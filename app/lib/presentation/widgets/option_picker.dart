import 'package:flutter/material.dart';

class OptionPicker extends StatelessWidget {
  final String title;
  final List<(String label, String value)> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const OptionPicker({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: cs.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (label, value) in options)
                  GestureDetector(
                    onTap: () => onSelected(value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
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
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: value == selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
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
}
