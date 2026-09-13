import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';

class HomeEmptyState extends StatelessWidget {
  final String? searchQuery;

  const HomeEmptyState({super.key, this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final existingTheme = ShadTheme.maybeOf(context);
    final isDark = existingTheme?.brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.dark;
    final seedColor = Theme.of(context).colorScheme.primary;
    final shadTheme = existingTheme ??
        (isDark
            ? AppTheme.shadThemeDark(seedColor: seedColor)
            : AppTheme.shadThemeLight(seedColor: seedColor));
    final hasFilter = searchQuery != null && searchQuery!.isNotEmpty;

    final Widget content;
    if (hasFilter) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShadAvatar(
                null,
                size: const Size.square(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                backgroundColor: shadTheme.colorScheme.secondary,
                placeholder: Icon(
                  LucideIcons.searchX,
                  size: 26,
                  color: shadTheme.colorScheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No results for "$searchQuery"',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: shadTheme.colorScheme.foreground,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Try checking for typos or searching with another keyword',
                style: TextStyle(
                  fontSize: 13,
                  color: shadTheme.colorScheme.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShadAvatar(
                null,
                size: const Size.square(64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                backgroundColor: shadTheme.colorScheme.secondary,
                placeholder: Icon(
                  LucideIcons.keyRound,
                  size: 30,
                  color: shadTheme.colorScheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No OTP accounts yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: shadTheme.colorScheme.foreground,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first account using the + button below',
                style: TextStyle(
                  fontSize: 14,
                  color: shadTheme.colorScheme.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (existingTheme == null) {
      return ShadTheme(
        data: shadTheme,
        child: content,
      );
    }
    return content;
  }
}
