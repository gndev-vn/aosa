import 'package:aosa/data/repositories/otp_repository_impl.dart';
import 'package:aosa/domain/entities/otp_account.dart';
import 'package:aosa/domain/usecases/otpauth_parser.dart';
import 'package:aosa/presentation/screens/qr_scanner_screen.dart';
import 'package:aosa/presentation/widgets/aosa_action_chip.dart';
import 'package:aosa/presentation/widgets/aosa_confirm_dialog.dart';
import 'package:aosa/presentation/widgets/otp_form.dart';
import 'package:aosa/presentation/widgets/standard_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showAddOtpSheet(
    BuildContext context, WidgetRef ref, OtpRepositoryImpl repo) {
  return showSlideBottomSheet(
    context,
    isScrollControlled: true,
    builder: (_) => _AddOtpSheetContent(repository: repo),
  );
}

class _AddOtpSheetContent extends ConsumerStatefulWidget {
  final OtpRepositoryImpl repository;

  const _AddOtpSheetContent({required this.repository});

  @override
  ConsumerState<_AddOtpSheetContent> createState() =>
      _AddOtpSheetContentState();
}

class _AddOtpSheetContentState extends ConsumerState<_AddOtpSheetContent> {
  OtpFormData _formData = const OtpFormData();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return StandardBottomSheet(
      title: 'Add Account',
      useSafeArea: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActions(Theme.of(context), Theme.of(context).colorScheme),
          OtpForm(
            key: _formKey,
            initialData: _formData,
            onSave: (data) => _saveAccount(data),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: AosaActionChip(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan',
              color: colorScheme,
              onTap: () => _openScanner(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AosaActionChip(
              icon: Icons.link_rounded,
              label: 'URI',
              color: colorScheme,
              onTap: () => _showPasteUriDialog(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AosaActionChip(
              icon: Icons.backup_rounded,
              label: 'Import',
              color: colorScheme,
              onTap: () => _showImportDialog(),
            ),
          ),
        ],
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

  void _showImportDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AosaConfirmDialog(
        icon: Icons.backup_rounded,
        title: 'Import Accounts',
        confirmLabel: 'Import',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste otpauth:// URIs, one per line.\n'
              'Google Authenticator JSON backup is also supported.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText:
                    'otpauth://totp/Example:user@example.com?secret=...',
              ),
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ],
        ),
        onConfirm: () {
          final text = controller.text.trim();
          if (text.isNotEmpty) _importAccounts(text);
        },
      ),
    );
  }

  Future<void> _importAccounts(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    List<OtpAccount> accounts;

    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      accounts = OtpAuthParser.parseGoogleAuthExport(trimmed);
    } else {
      accounts = OtpAuthParser.parseUriList(trimmed);
    }

    if (accounts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No valid accounts found in import data')),
        );
      }
      return;
    }

    var imported = 0;
    for (final account in accounts) {
      await widget.repository.save(account);
      imported++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $imported account(s)')),
      );
      Navigator.of(context).pop();
    }
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
