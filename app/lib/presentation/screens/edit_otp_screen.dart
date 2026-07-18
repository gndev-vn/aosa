import 'package:aosa/data/repositories/otp_repository_impl.dart';
import 'package:aosa/domain/entities/otp_account.dart';
import 'package:aosa/presentation/providers/navigation_provider.dart';
import 'package:aosa/presentation/widgets/aosa_widgets.dart';
import 'package:aosa/presentation/widgets/confirm_delete_dialog.dart';
import 'package:aosa/presentation/widgets/otp_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      issuer: account.issuer,
      accountLabel: account.accountLabel,
    );
    if (confirmed) {
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
    }
  }
}
