import 'package:flutter/material.dart';

BoxDecoration appBackground(ColorScheme colorScheme) => BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colorScheme.surface,
          colorScheme.surfaceContainerHighest.withAlpha(180),
        ],
      ),
    );

class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  const GradientIcon({
    super.key,
    required this.icon,
    this.size = 72,
    this.iconSize = 36,
    this.borderRadius = 20,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withAlpha(180),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: colorScheme.onPrimary,
      ),
    );
  }
}
