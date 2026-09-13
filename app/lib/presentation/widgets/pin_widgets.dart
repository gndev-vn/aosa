import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';

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
    final shadTheme = ShadTheme.maybeOf(context);
    final isDark = shadTheme?.brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.dark;
    final primary = shadTheme?.colorScheme.primary ??
        Theme.of(context).colorScheme.primary;
    final borderColor = shadTheme?.colorScheme.border ??
        (isDark ? AppTheme.darkBorder : AppTheme.lightBorder);

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
            color: filled ? primary : Colors.transparent,
            border: Border.all(
              color: filled ? primary : borderColor,
              width: 2,
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
    final shadTheme = ShadTheme.maybeOf(context);
    final spacing = keySize * 0.08;
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
                  child: ShadButton.outline(
                    width: keySize,
                    height: keySize,
                    padding: EdgeInsets.zero,
                    decoration: const ShadDecoration(shape: BoxShape.circle),
                    enabled: !disabled,
                    onPressed: disabled
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            onKeyPressed(key);
                          },
                    child: Text(
                      key,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: shadTheme?.colorScheme.foreground,
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
    return ShadAlert.destructive(
      icon: const Icon(LucideIcons.circleAlert),
      description: Text(message),
    );
  }
}
