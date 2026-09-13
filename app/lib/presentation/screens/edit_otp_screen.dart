import 'package:aosa/data/repositories/otp_repository_impl.dart';
import 'package:aosa/domain/entities/otp_account.dart';
import 'package:aosa/domain/usecases/totp_engine.dart';
import 'package:aosa/presentation/providers/navigation_provider.dart';
import 'package:aosa/presentation/providers/otp_list_provider.dart';
import 'package:aosa/presentation/widgets/aosa_input.dart';
import 'package:aosa/presentation/widgets/confirm_delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/loading_indicator.dart';

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
    final existingTheme = ShadTheme.maybeOf(context);
    final isDark = existingTheme?.brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.dark;
    final seed = Theme.of(context).colorScheme.primary;
    final shadTheme = existingTheme ??
        (isDark
            ? AppTheme.shadThemeDark(seedColor: seed)
            : AppTheme.shadThemeLight(seedColor: seed));

    final scaffold = Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(shadTheme),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // OTP Preview card
                    _buildOtpPreview(shadTheme),
                    const SizedBox(height: 24),

                    // Account details card (Issuer + Account + Secret)
                    _buildDetailsCard(shadTheme),
                    const SizedBox(height: 32),

                    // Delete button
                    _buildDeleteButton(shadTheme),
                  ],
                ),
              ),
            ),

            // Save button
            _buildSaveBar(shadTheme),
          ],
        ),
      ),
    );

    if (existingTheme == null) {
      return ShadTheme(
        data: shadTheme,
        child: scaffold,
      );
    }
    return scaffold;
  }

  Widget _buildHeader(ShadThemeData shadTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          ShadButton.outline(
            width: 36,
            height: 36,
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Icon(LucideIcons.arrowLeft, size: 16),
          ),
          const Spacer(),
          Text(
            'Edit account',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: shadTheme.colorScheme.foreground,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildOtpPreview(ShadThemeData shadTheme) {
    final items = ref.watch(otpListProvider);
    final item = items.where((e) => e.account.id == account.id).firstOrNull;
    final code = item?.code.code ?? '------';

    return ShadCard(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: Text(
          code.length == 6
              ? '${code.substring(0, 3)} ${code.substring(3)}'
              : code,
          style: AppTheme.codeStyle(color: shadTheme.colorScheme.foreground),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(ShadThemeData shadTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildField(
          controller: _issuerCtrl,
          label: 'Issuer',
          hint: 'e.g. Google, GitHub',
          icon: LucideIcons.building2,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _labelCtrl,
          label: 'Account label',
          hint: 'e.g. user@gmail.com',
          icon: LucideIcons.user,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        _buildSecretField(shadTheme),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    ValueChanged<String>? onChanged,
  }) {
    return AosaInput(
      controller: controller,
      label: label,
      hint: hint,
      leadingIcon: icon,
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
    );
  }

  Widget _buildSecretField(ShadThemeData shadTheme) {
    return AosaInput(
      controller: _secretCtrl,
      label: 'Secret key',
      hint: 'JBSWY3DPEHPK3PXP',
      errorText: _secretError,
      leadingIcon: LucideIcons.keyRound,
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
      trailing: GestureDetector(
        onTap: () => setState(() => _secretVisible = !_secretVisible),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(
            _secretVisible ? LucideIcons.eyeOff : LucideIcons.eye,
            size: 16,
            color: shadTheme.colorScheme.mutedForeground,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(ShadThemeData shadTheme) {
    return ShadButton.destructive(
      width: double.infinity,
      height: 44,
      onPressed: () => _confirmDelete(context),
      leading: const Icon(LucideIcons.trash2, size: 16),
      child: const Text('Delete account'),
    );
  }

  Widget _buildSaveBar(ShadThemeData shadTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: shadTheme.colorScheme.background,
        border: Border(
          top: BorderSide(color: shadTheme.colorScheme.border, width: 1),
        ),
      ),
      child: ShadButton(
        width: double.infinity,
        height: 48,
        onPressed: (_canSave && !_isSaving) ? _save : null,
        child: _isSaving
            ? const AosaLoadingIndicator(size: 18)
            : const Text('Save changes'),
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
