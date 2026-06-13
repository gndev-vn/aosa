import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aosa/data/repositories/otp_repository_impl.dart';
import 'package:aosa/domain/entities/otp_account.dart';
import 'package:aosa/domain/usecases/otpauth_parser.dart';
import 'package:aosa/presentation/screens/qr_scanner_screen.dart';
import 'package:aosa/presentation/widgets/aosa_widgets.dart';
import 'package:aosa/presentation/widgets/otp_form.dart';

Future<void> showAddOtpSheet(
    BuildContext context, WidgetRef ref, OtpRepositoryImpl repo) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          _buildHeader(theme, colorScheme),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildActions(theme, colorScheme),
                  OtpForm(
                    key: _formKey,
                    initialData: _formData,
                    onSave: (data) => _saveAccount(data),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withAlpha(180),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.add_rounded,
              size: 20,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Add Account',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(120),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
            child: _ActionChip(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan',
              color: colorScheme,
              onTap: () => _openScanner(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionChip(
              icon: Icons.link_rounded,
              label: 'URI',
              color: colorScheme,
              onTap: () => _showPasteUriDialog(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionChip(
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
      PageRouteBuilder(
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
    showDialog(
      context: context,
      builder: (ctx) => _Dialog(
        icon: Icons.link_rounded,
        title: 'Paste URI',
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
    showDialog(
      context: context,
      builder: (ctx) => _Dialog(
        icon: Icons.backup_rounded,
        title: 'Import Accounts',
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
      if (context.mounted) {
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

    if (context.mounted) {
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data.issuer} added'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
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

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color.onPrimaryContainer),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final VoidCallback onConfirm;

  const _Dialog({
    required this.icon,
    required this.title,
    required this.child,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Center(
                        child: Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: cs.primary,
                      ),
                      child: Center(
                        child: Text('Import', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onPrimary)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
