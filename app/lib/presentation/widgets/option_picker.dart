import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';
import 'standard_bottom_sheet.dart';

Future<String?> showOptionPickerSheet(
  BuildContext context, {
  String title = '',
  required List<(String label, String value)> options,
  required String selected,
}) {
  return showSlideBottomSheet<String>(
    context,
    builder: (ctx) => OptionPicker(
      title: title,
      options: options,
      selected: selected,
      onSelected: (val) => Navigator.of(ctx).pop(val),
    ),
  );
}

class OptionPicker extends StatelessWidget {
  final String title;
  final List<(String label, String value)> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const OptionPicker({
    super.key,
    this.title = '',
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final existingTheme = ShadTheme.maybeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seed = Theme.of(context).colorScheme.primary;
    final theme = existingTheme ??
        (isDark
            ? AppTheme.shadThemeDark(seedColor: seed)
            : AppTheme.shadThemeLight(seedColor: seed));

    final sheet = StandardBottomSheet(
      title: title.isEmpty ? 'Select Option' : title,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, value) in options)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              child: (value == selected)
                  ? ShadButton.secondary(
                      width: double.infinity,
                      height: 44,
                      mainAxisAlignment: MainAxisAlignment.start,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onSelected(value);
                      },
                      trailing: const Icon(LucideIcons.check, size: 16),
                      child: Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: theme.colorScheme.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : ShadButton.ghost(
                      width: double.infinity,
                      height: 44,
                      mainAxisAlignment: MainAxisAlignment.start,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onSelected(value);
                      },
                      child: Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: theme.colorScheme.foreground,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
            ),
        ],
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
