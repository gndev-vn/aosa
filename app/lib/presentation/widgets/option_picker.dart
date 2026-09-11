import 'package:flutter/material.dart';
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
    final cs = Theme.of(context).colorScheme;
    return StandardBottomSheet(
      title: title.isEmpty ? 'Select Option' : title,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, value) in options)
            InkWell(
              onTap: () => onSelected(value),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      value == selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 20,
                      color: value == selected
                          ? cs.primary
                          : cs.outlineVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: value == selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
