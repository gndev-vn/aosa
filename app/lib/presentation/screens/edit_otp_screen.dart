import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aosa/data/repositories/otp_repository_impl.dart';
import 'package:aosa/domain/entities/otp_account.dart';
import 'package:aosa/presentation/providers/navigation_provider.dart';
import 'package:aosa/presentation/widgets/aosa_widgets.dart';
import 'package:aosa/presentation/widgets/otp_form.dart';

class EditOtpScreen extends ConsumerWidget {
  final OtpRepositoryImpl repository;
  final OtpAccount account;

  const EditOtpScreen({
    super.key,
    required this.repository,
    required this.account,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AosaHeader(
              leading: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: aosaBackButton(context),
              ),
              titleWidget: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withAlpha(180),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        account.issuer[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      account.issuer,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      color: colorScheme.error),
                  tooltip: 'Delete account',
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
            Expanded(
              child: OtpForm(
                initialData: OtpFormData(
                  issuer: account.issuer,
                  accountLabel: account.accountLabel,
                  secretBase32: account.secretBase32,
                  algorithm: account.algorithm,
                  digits: account.digits,
                  period: account.period,
                ),
                onSave: (data) => _saveChanges(context, ref, data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges(
      BuildContext context, WidgetRef ref, OtpFormData data) async {
    final updated = account.copyWith(
      issuer: data.issuer,
      accountLabel: data.accountLabel,
      secretBase32: data.secretBase32,
      algorithm: data.algorithm,
      digits: data.digits,
      period: data.period,
    );

    await repository.save(updated);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${data.issuer} updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.read(navigationProvider.notifier).goToHome();
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: cs.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.delete_outline_rounded,
                    size: 28, color: cs.onErrorContainer),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Remove ${account.issuer} (${account.accountLabel})? '
                'This cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await repository.delete(account.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${account.issuer} deleted'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          ref.read(navigationProvider.notifier).goToHome();
                        }
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: cs.error,
                        ),
                        child: Center(
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.onError,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
