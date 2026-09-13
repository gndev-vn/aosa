import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';

Future<bool> showConfirmationBottomSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
  Color? iconColor,
  Color? iconBackgroundColor,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: true,
    useSafeArea: false,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (ctx) => ConfirmationBottomSheet(
      icon: icon,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      onConfirm: () => Navigator.of(ctx).pop(true),
      onCancel: () => Navigator.of(ctx).pop(false),
    ),
  );
  return result ?? false;
}

class ConfirmationBottomSheet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationBottomSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.iconColor,
    this.iconBackgroundColor,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final bottomInset =
        max(media.viewPadding.bottom, media.viewInsets.bottom) + 16.0;

    final existingTheme = ShadTheme.maybeOf(context);
    final isDark = existingTheme?.brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.dark;
    final theme = existingTheme ??
        (isDark
            ? AppTheme.shadThemeDark(seedColor: cs.primary)
            : AppTheme.shadThemeLight(seedColor: cs.primary));
    final cardColor = theme.colorScheme.card;
    final borderColor = theme.colorScheme.border;

    final badgeBg = iconBackgroundColor ??
        (isDestructive
            ? theme.colorScheme.destructive.withValues(alpha: 0.1)
            : theme.colorScheme.primary.withValues(alpha: 0.1));
    final badgeFg = iconColor ??
        (isDestructive ? theme.colorScheme.destructive : theme.colorScheme.primary);

    final sheet = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset),
        child: Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusPill),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ShadAvatar(
                  null,
                  size: const Size.square(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  backgroundColor: badgeBg,
                  placeholder: Icon(icon, size: 28, color: badgeFg),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: theme.colorScheme.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ShadButton.outline(
                        onPressed: onCancel ??
                            () => Navigator.of(context).pop(false),
                        height: 44,
                        child: Text(cancelLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: isDestructive
                          ? ShadButton.destructive(
                              onPressed: onConfirm,
                              height: 44,
                              child: Text(confirmLabel),
                            )
                          : ShadButton(
                              onPressed: onConfirm,
                              height: 44,
                              child: Text(confirmLabel),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (existingTheme == null) {
      return ShadTheme(
        data: theme,
        child: sheet,
      );
    }
    return sheet;
  }
}
