import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinDots extends StatelessWidget {
  final int filledCount;
  final bool animate;
  final double spacing;

  const PinDots({
    super.key,
    required this.filledCount,
    this.animate = false,
    this.spacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(6, (i) {
        final filled = i < filledCount;
        final isLatest = animate && i == filledCount - 1 && filled;
        final dot = AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: spacing),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? colorScheme.primary : Colors.transparent,
            border: Border.all(
              color: filled ? colorScheme.primary : colorScheme.outlineVariant,
              width: filled ? 0 : 2,
            ),
          ),
        );
        if (isLatest) {
          return AnimatedScale(
            scale: 1.3,
            duration: const Duration(milliseconds: 200),
            curve: Curves.elasticOut,
            child: dot,
          );
        }
        return dot;
      }),
    );
  }
}

class Numpad extends StatelessWidget {
  final ValueChanged<String> onKeyPressed;
  final bool disabled;
  final double keySize;

  const Numpad({
    super.key,
    required this.onKeyPressed,
    this.disabled = false,
    this.keySize = 72,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = keySize * 0.08;
    final radius = keySize * 0.5;
    final fontSize = keySize * 0.33;
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '\u232B'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: spacing * 0.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: row.map((key) {
              if (key.isEmpty) return SizedBox(width: keySize + spacing * 2);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing),
                child: SizedBox(
                  width: keySize,
                  height: keySize,
                  child: Material(
                    color: disabled
                        ? Colors.transparent
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(radius),
                    elevation: disabled ? 0 : 1,
                    shadowColor: colorScheme.shadow.withAlpha(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(radius),
                      onTap: disabled
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              onKeyPressed(key);
                            },
                      child: Center(
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                            color: disabled
                                ? colorScheme.onSurfaceVariant.withAlpha(80)
                                : key == '\u232B'
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;

  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
