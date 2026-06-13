import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/settings_provider.dart';

class AccentColorPicker extends ConsumerWidget {
  const AccentColorPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentColor = ref.watch(settingsProvider.select((s) => s.seedColor));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.colorize_rounded, size: 18, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 10),
                Text(
                  'Accent Color',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: _seedColors.map((color) {
                final selected = color.value == currentColor;
                return GestureDetector(
                  onTap: () {
                    ref.read(settingsProvider.notifier).setSeedColor(color.value);
                    Navigator.of(context).pop();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: colorScheme.onSurface,
                              width: 3,
                            )
                          : Border.all(
                              color: colorScheme.outlineVariant,
                              width: 1,
                            ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: color.withAlpha(80),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            size: 22,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black87
                                : Colors.white,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

const _seedColors = [
  Color(0xff1976d2), // Blue
  Color(0xff1565c0), // Dark blue
  Color(0xff0d47a1), // Navy
  Color(0xff00838f), // Teal
  Color(0xff00796b), // Green
  Color(0xff2e7d32), // Dark green
  Color(0xff558b2f), // Light green
  Color(0xfff9a825), // Yellow
  Color(0xffff8f00), // Amber
  Color(0xffef6c00), // Orange
  Color(0xffd84315), // Deep orange
  Color(0xffc62828), // Red
  Color(0xffad1457), // Pink
  Color(0xff6a1b9a), // Purple
  Color(0xff4a148c), // Deep purple
  Color(0xff37474f), // Blue grey
];
