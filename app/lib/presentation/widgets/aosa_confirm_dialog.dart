import 'package:flutter/material.dart';
import 'standard_bottom_sheet.dart';

@Deprecated('Use StandardBottomSheet or showConfirmationBottomSheet instead.')
class AosaConfirmDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final String confirmLabel;
  final VoidCallback onConfirm;

  const AosaConfirmDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.confirmLabel = 'Confirm',
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return StandardBottomSheet(
      title: title,
      confirmLabel: confirmLabel,
      onConfirm: onConfirm,
      onBack: () => Navigator.of(context).pop(),
      child: child,
    );
  }
}
