import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AosaLoadingIndicator extends StatefulWidget {
  final double size;

  const AosaLoadingIndicator({super.key, this.size = 24});

  @override
  State<AosaLoadingIndicator> createState() => _AosaLoadingIndicatorState();
}

class _AosaLoadingIndicatorState extends State<AosaLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.maybeOf(context);
    final primary =
        theme?.colorScheme.primary ?? Theme.of(context).colorScheme.primary;
    return Center(
      child: RotationTransition(
        turns: _controller,
        child: Icon(
          LucideIcons.loader2,
          size: widget.size,
          color: primary,
        ),
      ),
    );
  }
}

class VibrantProgressBar extends StatelessWidget {
  final double progress;
  final bool isUrgent;
  final Color? accentColor;
  final double height;

  const VibrantProgressBar({
    super.key,
    required this.progress,
    required this.isUrgent,
    this.accentColor,
    this.height = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final shadTheme = ShadTheme.maybeOf(context);
    final themeColor = shadTheme?.colorScheme.primary ??
        Theme.of(context).colorScheme.primary;
    final effectiveAccent = accentColor ?? themeColor;
    return ShadProgress(
      value: progress.clamp(0.0, 1.0),
      minHeight: height,
      color: isUrgent
          ? (shadTheme?.colorScheme.destructive ??
              Theme.of(context).colorScheme.error)
          : effectiveAccent,
      backgroundColor: shadTheme?.colorScheme.muted,
    );
  }
}


