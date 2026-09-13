import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/providers/settings_provider.dart';
import 'standard_bottom_sheet.dart';

class AccentColorPicker extends ConsumerWidget {
  const AccentColorPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentColor = ref.watch(settingsProvider.select((s) => s.seedColor));
    final shadTheme = ShadTheme.of(context);

    return StandardBottomSheet(
      title: 'Accent Color',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _seedColors.map((color) {
              final selected = color.toARGB32() == currentColor;
              return GestureDetector(
                onTap: () {
                  ref.read(settingsProvider.notifier).setSeedColor(color.toARGB32());
                  Navigator.of(context).pop();
                },
                child: ShadAvatar(
                  null,
                  size: const Size.square(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    side: BorderSide(
                      color: selected
                          ? shadTheme.colorScheme.foreground
                          : shadTheme.colorScheme.border,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  backgroundColor: color,
                  placeholder: selected
                      ? Icon(
                          LucideIcons.check,
                          size: 20,
                          color: color.computeLuminance() > 0.4
                              ? const Color(0xFF09090B)
                              : const Color(0xFFFAFAFA),
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

const _seedColors = [
  Color(0xFF3B82F6), // Blue
  Color(0xFF6366F1), // Indigo
  Color(0xFF8B5CF6), // Violet
  Color(0xFFEC4899), // Pink
  Color(0xFFF43F5E), // Rose
  Color(0xFFEF4444), // Red
  Color(0xFFF97316), // Orange
  Color(0xFFF59E0B), // Amber
  Color(0xFF10B981), // Emerald
  Color(0xFF14B8A6), // Teal
  Color(0xFF06B6D4), // Cyan
  Color(0xFF71717A), // Zinc / Slate
  Color(0xFF0D47A1), // Navy
  Color(0xFF2E7D32), // Forest Green
  Color(0xFF4A148C), // Deep Purple
  Color(0xFF37474F), // Blue Grey
];
