import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
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

    final input = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ShadInput(
        controller: controller,
        placeholder: const Text('Search accounts...'),
        leading: const Icon(LucideIcons.search, size: 16),
        trailing: searchQuery.isNotEmpty
            ? ShadButton.ghost(
                width: 24,
                height: 24,
                padding: EdgeInsets.zero,
                onPressed: onClear,
                child: const Icon(LucideIcons.x, size: 14),
              )
            : null,
        onChanged: onChanged,
      ),
    );

    if (existingTheme == null) {
      return ShadTheme(
        data: theme,
        child: input,
      );
    }
    return input;
  }
}

