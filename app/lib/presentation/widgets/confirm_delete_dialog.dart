import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'confirmation_bottom_sheet.dart';

Future<bool> showConfirmDeleteDialog(
  BuildContext context, {
  required String issuer,
  required String? accountLabel,
}) {
  return showConfirmationBottomSheet(
    context,
    icon: LucideIcons.trash2,
    title: 'Delete Account',
    message: (accountLabel != null && accountLabel.isNotEmpty)
        ? 'Remove $issuer ($accountLabel)? This cannot be undone.'
        : 'Remove $issuer?',
    confirmLabel: 'Delete',
    cancelLabel: 'Cancel',
    isDestructive: true,
  );
}
