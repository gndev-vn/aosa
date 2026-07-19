import 'package:aosa/data/repositories/otp_repository_impl.dart';
import 'package:aosa/domain/entities/otp_account.dart';
import 'package:aosa/domain/usecases/otpauth_parser.dart';
import 'package:aosa/presentation/screens/qr_scanner_screen.dart';
import 'package:aosa/presentation/widgets/aosa_confirm_dialog.dart';
import 'package:aosa/presentation/widgets/otp_form.dart';
import 'package:aosa/presentation/widgets/standard_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AddOtpMode { form, scan, uri }

Future<void> showAddOtpSheet(
  BuildContext context,
  WidgetRef ref,
  OtpRepositoryImpl repo, {
  AddOtpMode startMode = AddOtpMode.form,
}) {
  return showSlideBottomSheet(
    context,
    isScrollControlled: true,
    builder: (_) => _AddOtpSheetContent(repository: repo, startMode: startMode),
  );
}

class _AddOtpSheetContent extends ConsumerStatefulWidget {
  final OtpRepositoryImpl repository;
  final AddOtpMode startMode;

  const _AddOtpSheetContent({required this.repository, required this.startMode});

  @override
  ConsumerState<_AddOtpSheetContent> createState() =>
      _AddOtpSheetContentState();
}

class _AddOtpSheetContentState extends ConsumerState<_AddOtpSheetContent> {
  OtpFormData _formData = const OtpFormData();
  final _otpFormKey = GlobalKey<OtpFormState>();
  bool _formValid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (widget.startMode) {
        case AddOtpMode.scan:
          _openScanner();
          break;
        case AddOtpMode.uri:
          _showPasteUriDialog();
          break;
        case AddOtpMode.form:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StandardBottomSheet(
      title: 'Add account',
      useSafeArea: false,
      confirmLabel: 'Save',
      onConfirm: _formValid ? () => _otpFormKey.currentState?.save() : null,
      child: OtpForm(
        key: _otpFormKey,
        initialData: _formData,
        onValidChanged: (valid) => setState(() => _formValid = valid),
        onSave: (data) => _saveAccount(data),
      ),
    );
  }

  void _openScanner() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => QrScannerScreen(onScan: (data) {
          Navigator.of(context).pop();
          _handleScanResult(data);
        }),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  void _handleScanResult(String data) {
    final result = OtpAuthParser.parse(data);
    if (result != null) {
      setState(() {
        _formData = OtpFormData(
          issuer: result.issuer,
          accountLabel: result.accountLabel,
          secretBase32: result.secretBase32,
          algorithm: result.algorithm,
          digits: result.digits,
          period: result.period,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR code — not a valid otpauth:// URI'),
        ),
      );
    }
  }

  void _showPasteUriDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AosaConfirmDialog(
        icon: Icons.link_rounded,
        title: 'Paste URI',
        confirmLabel: 'Import',
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'otpauth://totp/...',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        onConfirm: () {
          final uri = controller.text.trim();
          if (uri.isNotEmpty) _handleScanResult(uri);
        },
      ),
    );
  }

  Future<void> _saveAccount(OtpFormData data) async {
    try {
      final account = OtpAccount(
        id: _generateId(),
        issuer: data.issuer,
        accountLabel: data.accountLabel,
        secretBase32: data.secretBase32,
        algorithm: data.algorithm,
        digits: data.digits,
        period: data.period,
      );

      await widget.repository.save(account);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data.issuer} added'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = (now ^ (now << 13) ^ (now >> 17)).toRadixString(16);
    return '$now-$random';
  }
}
