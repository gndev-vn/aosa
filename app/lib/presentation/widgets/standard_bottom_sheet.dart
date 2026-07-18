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
    useSafeArea: useSafeArea,
    isScrollControlled: isScrollControlled,
    useRootNavigator: false,
    isDismissible: isDismissible,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: builder,
  );
}

class StandardBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? leadingAction;
  final Widget? trailingAction;
  final bool useSafeArea;
  final bool isScrollControlled;
  final EdgeInsetsGeometry? padding;

  const StandardBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.leadingAction,
    this.trailingAction,
    this.useSafeArea = true,
    this.isScrollControlled = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = isScrollControlled
        ? MediaQuery.of(context).viewInsets.bottom
        : 0.0;

    final sheet = Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          _buildGrabber(cs),
          const SizedBox(height: 4),
          _buildHeader(cs),
          Flexible(
            child: SingleChildScrollView(
              padding: padding ?? const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: child,
            ),
          ),
        ],
      ),
    );

    if (useSafeArea) {
      return SafeArea(top: false, child: sheet);
    }
    return sheet;
  }

  Widget _buildGrabber(ColorScheme cs) {
    return Center(
      child: Container(
        width: 48,
        height: 6,
        decoration: BoxDecoration(
          color: cs.onSurfaceVariant.withAlpha(80),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          if (leadingAction != null) leadingAction! else const SizedBox(width: 40),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          if (trailingAction != null) trailingAction! else const SizedBox(width: 40),
        ],
      ),
    );
  }
}
