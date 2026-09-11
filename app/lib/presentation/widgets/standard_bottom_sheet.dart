import 'package:flutter/material.dart';

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
    final cs = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final bottomInset = (isScrollControlled && media.viewInsets.bottom > 0)
        ? media.viewInsets.bottom + 16.0
        : media.viewPadding.bottom + 16.0;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(cs),
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
          color: cs.surface,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          elevation: 6,
          child: content,
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    final hasBack = onBack != null;
    final hasConfirm = confirmLabel != null && onConfirm != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: _buildGrabber(cs)),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (hasBack)
                  Positioned(
                    left: 0,
                    child: GestureDetector(
                      onTap: onBack,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                if (hasConfirm)
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: onConfirm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          confirmLabel!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onPrimary,
                          ),
                        ),
                      ),
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

  Widget _buildGrabber(ColorScheme cs) {
    return Container(
      width: 48,
      height: 6,
      decoration: BoxDecoration(
        color: cs.onSurfaceVariant.withAlpha(80),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
