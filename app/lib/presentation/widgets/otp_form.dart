import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aosa/domain/usecases/totp_engine.dart';
import 'aosa_widgets.dart';

class OtpFormData {
  final String issuer;
  final String accountLabel;
  final String secretBase32;
  final String algorithm;
  final int digits;
  final int period;

  const OtpFormData({
    this.issuer = '',
    this.accountLabel = '',
    this.secretBase32 = '',
    this.algorithm = 'SHA1',
    this.digits = 6,
    this.period = 30,
  });

  bool get isValid =>
      issuer.isNotEmpty &&
      accountLabel.isNotEmpty &&
      TotpEngine.isValidBase32(secretBase32) &&
      secretBase32.length >= 16;

  Map<String, dynamic> toJson() => {
        'issuer': issuer,
        'account_label': accountLabel,
        'secret_base32': secretBase32,
        'algorithm': algorithm,
        'digits': digits,
        'period': period,
      };
}

class OtpForm extends StatefulWidget {
  final OtpFormData initialData;
  final Future<void> Function(OtpFormData) onSave;

  const OtpForm({
    super.key,
    this.initialData = const OtpFormData(),
    required this.onSave,
  });

  @override
  State<OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  late final _issuerCtrl = TextEditingController(text: widget.initialData.issuer);
  late final _labelCtrl = TextEditingController(text: widget.initialData.accountLabel);
  late final _secretCtrl = TextEditingController(text: widget.initialData.secretBase32);
  late String _algorithm = widget.initialData.algorithm;
  late int _digits = widget.initialData.digits;
  late int _period = widget.initialData.period;
  String? _secretError;

  @override
  void didUpdateWidget(OtpForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData.issuer != oldWidget.initialData.issuer) {
      _issuerCtrl.text = widget.initialData.issuer;
    }
    if (widget.initialData.accountLabel != oldWidget.initialData.accountLabel) {
      _labelCtrl.text = widget.initialData.accountLabel;
    }
    if (widget.initialData.secretBase32 != oldWidget.initialData.secretBase32) {
      _secretCtrl.text = widget.initialData.secretBase32;
      _validateSecret();
    }
    if (widget.initialData.algorithm != oldWidget.initialData.algorithm) {
      _algorithm = widget.initialData.algorithm;
    }
    if (widget.initialData.digits != oldWidget.initialData.digits) {
      _digits = widget.initialData.digits;
    }
    if (widget.initialData.period != oldWidget.initialData.period) {
      _period = widget.initialData.period;
    }
  }

  @override
  void dispose() {
    _issuerCtrl.dispose();
    _labelCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSection('Account Information', [
            _buildTextField(
              controller: _issuerCtrl,
              label: 'Issuer',
              hint: 'e.g. Google, GitHub',
              icon: Icons.business,
              onChanged: (_) => _onChanged(),
            ),
            _buildTextField(
              controller: _labelCtrl,
              label: 'Account Label',
              hint: 'e.g. user@gmail.com',
              icon: Icons.person_outline,
              onChanged: (_) => _onChanged(),
            ),
          ]),

          const SizedBox(height: 16),
          _buildSection('Secret Key', [
            _buildTextField(
              controller: _secretCtrl,
              label: 'Secret Key (Base32)',
              hint: 'e.g. JBSWY3DPEHPK3PXP',
              icon: Icons.key,
              errorText: _secretError,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z2-7=]')),
                UpperCaseTextFormatter(),
              ],
              onChanged: (v) {
                _validateSecret();
                _onChanged();
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'The secret key is usually a 16-32 character Base32 string. '
                'You can find it when setting up 2FA on the service website.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ]),

          const SizedBox(height: 24),
          AosaButton(
            onPressed: _canSave ? _save : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 18),
                const SizedBox(width: 8),
                Text('Save Account'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? errorText,
    int maxLines = 1,
    TextInputAction textInputAction = TextInputAction.next,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        maxLines: maxLines,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
      ),
    );
  }

  bool get _canSave {
    return _issuerCtrl.text.trim().isNotEmpty &&
        _labelCtrl.text.trim().isNotEmpty &&
        _secretCtrl.text.trim().isNotEmpty &&
        _secretError == null;
  }

  void _validateSecret() {
    final secret = _secretCtrl.text.trim();
    if (secret.isNotEmpty && !TotpEngine.isValidBase32(secret)) {
      _secretError = 'Invalid Base32 characters';
    } else if (secret.isNotEmpty && secret.length < 16) {
      _secretError = 'Secret is too short (min 16 chars)';
    } else {
      _secretError = null;
    }
    setState(() {});
  }

  void _onChanged() => setState(() {});

  Future<void> _save() async {
    if (!_canSave) return;
    await widget.onSave(OtpFormData(
      issuer: _issuerCtrl.text.trim(),
      accountLabel: _labelCtrl.text.trim(),
      secretBase32: _secretCtrl.text.trim().toUpperCase(),
      algorithm: _algorithm,
      digits: _digits,
      period: _period,
    ),);
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
