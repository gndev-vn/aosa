import 'package:aosa/data/repositories/otp_repository_impl.dart';
import 'package:aosa/domain/entities/otp_account.dart';
import 'package:aosa/domain/usecases/totp_engine.dart';
import 'package:aosa/presentation/providers/navigation_provider.dart';
import 'package:aosa/presentation/providers/otp_list_provider.dart';
import 'package:aosa/presentation/widgets/aosa_widgets.dart';
import 'package:aosa/presentation/widgets/confirm_delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditOtpScreen extends ConsumerStatefulWidget {
  final OtpRepositoryImpl repository;
  final OtpAccount account;

  const EditOtpScreen({
    super.key,
    required this.repository,
    required this.account,
  });

  @override
  ConsumerState<EditOtpScreen> createState() => _EditOtpScreenState();
}

class _EditOtpScreenState extends ConsumerState<EditOtpScreen> {
  late final TextEditingController _issuerCtrl;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _secretCtrl;
  bool _secretVisible = false;
  bool _isSaving = false;
  String? _secretError;

  OtpAccount get account => widget.account;

  @override
  void initState() {
    super.initState();
    _issuerCtrl = TextEditingController(text: account.issuer);
    _labelCtrl = TextEditingController(text: account.accountLabel);
    _secretCtrl = TextEditingController(text: account.secretBase32);
  }

  @override
  void dispose() {
    _issuerCtrl.dispose();
    _labelCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
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
      _secretError = 'Too short (min 16 characters)';
    } else {
      _secretError = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(cs),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // OTP Preview card
                    _buildOtpPreview(cs),
                    const SizedBox(height: 24),

                    // Account details card (Issuer + Account + Secret)
                    _buildDetailsCard(cs),
                    const SizedBox(height: 32),

                    // Delete button
                    _buildDeleteButton(cs),
                  ],
                ),
              ),
            ),

            // Save button
            _buildSaveBar(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          aosaBackButton(context),
          const Spacer(),
          Text(
            'Edit account',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildOtpPreview(ColorScheme cs) {
    final items = ref.watch(otpListProvider);
    final item = items.where((e) => e.account.id == account.id).firstOrNull;
    final code = item?.code.code ?? '------';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.primaryContainer.withAlpha(180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          code,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: 6,
            fontFamily: 'monospace',
            color: cs.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withAlpha(80)),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          _buildField(
            controller: _issuerCtrl,
            label: 'Issuer',
            hint: 'e.g. Google, GitHub',
            icon: Icons.business_outlined,
            onChanged: (_) => setState(() {}),
          ),
          Divider(height: 1, color: cs.outlineVariant.withAlpha(60), indent: 52),
          _buildField(
            controller: _labelCtrl,
            label: 'Account',
            hint: 'e.g. user@gmail.com',
            icon: Icons.person_outline_rounded,
            onChanged: (_) => setState(() {}),
          ),
          Divider(height: 1, color: cs.outlineVariant.withAlpha(60), indent: 52),
          _buildSecretField(cs),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    ValueChanged<String>? onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
      ),
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
    );
  }

  Widget _buildSecretField(ColorScheme cs) {
    return TextField(
      controller: _secretCtrl,
      decoration: InputDecoration(
        labelText: 'Secret key',
        hintText: 'JBSWY3DPEHPK3PXP',
        errorText: _secretError,
        prefixIcon: const Icon(Icons.key_rounded, size: 20),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(
            _secretVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: () {
            setState(() => _secretVisible = !_secretVisible);
          },
        ),
      ),
      obscureText: !_secretVisible,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z2-7=]')),
        _UpperCaseTextFormatter(),
      ],
      onChanged: (_) {
        _validateSecret();
        setState(() {});
      },
    );
  }

  Widget _buildDeleteButton(ColorScheme cs) {
    return OutlinedButton(
      onPressed: () => _confirmDelete(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.error,
        side: BorderSide(color: cs.error.withAlpha(80)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: const Text('Delete account'),
    );
  }

  Widget _buildSaveBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withAlpha(60)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          onPressed: (_canSave && !_isSaving) ? _save : null,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save changes'),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final updated = account.copyWith(
      issuer: _issuerCtrl.text.trim(),
      accountLabel: _labelCtrl.text.trim(),
      secretBase32: _secretCtrl.text.trim().toUpperCase(),
    );

    await widget.repository.save(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_issuerCtrl.text.trim()} updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.read(navigationProvider.notifier).goToHome();
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      issuer: account.issuer,
      accountLabel: account.accountLabel,
    );
    if (!confirmed || !mounted) return;

    await widget.repository.delete(account.id);
    if (!mounted) return;

    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text('${account.issuer} deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    ref.read(navigationProvider.notifier).goToHome();
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
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
