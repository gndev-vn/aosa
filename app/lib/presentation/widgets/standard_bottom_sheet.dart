import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';

Future<T?> showSlideBottomSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext) builder,
  bool useSafeArea = true,
  bool isScrollControlled = false,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    useSafeArea: false,
    isScrollControlled: isScrollControlled,
    useRootNavigator: false,
    isDismissible: isDismissible,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: builder,
  );
}

class StandardBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final String? confirmLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onBack;
  final bool useSafeArea;
  final bool isScrollControlled;
  final EdgeInsetsGeometry? padding;

  const StandardBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.confirmLabel,
    this.onConfirm,
    this.onBack,
    this.useSafeArea = true,
    this.isScrollControlled = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = (isScrollControlled && media.viewInsets.bottom > 0)
        ? media.viewInsets.bottom + 16.0
        : media.viewPadding.bottom + 16.0;

    final existingTheme = ShadTheme.maybeOf(context);
    final isDark = existingTheme?.brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.dark;
    final seed = Theme.of(context).colorScheme.primary;
    final theme = existingTheme ??
        (isDark
            ? AppTheme.shadThemeDark(seedColor: seed)
            : AppTheme.shadThemeLight(seedColor: seed));
    final cardColor = theme.colorScheme.card;
    final borderColor = theme.colorScheme.border;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(theme, borderColor),
        Flexible(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(title),
              child: SingleChildScrollView(
                padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset),
        child: Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ShadThemeData theme, Color borderColor) {
    final hasBack = onBack != null;
    final hasConfirm = confirmLabel != null;
    final isConfirmEnabled = hasConfirm && onConfirm != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: _buildGrabber(borderColor)),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (hasBack)
                  Positioned(
                    left: 0,
                    child: ShadButton.outline(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: onBack,
                      child: const Text('Back'),
                    ),
                  ),
                Center(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.foreground,
                    ),
                  ),
                ),
                if (hasConfirm)
                  Positioned(
                    right: 0,
                    child: ShadButton(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      onPressed: isConfirmEnabled ? onConfirm : null,
                      child: Text(confirmLabel!),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildGrabber(Color grabberColor) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: grabberColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
    );
  }
}
