import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../data/api/repo_api.dart';
import 'standard_bottom_sheet.dart';

class RepoPickerSheet extends StatelessWidget {
  final List<RepoInfo> repos;
  final String? currentRepoId;

  const RepoPickerSheet({super.key, required this.repos, this.currentRepoId});

  @override
  Widget build(BuildContext context) {
    final existingTheme = ShadTheme.maybeOf(context);
    final isDark = existingTheme?.brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.dark;
    final seed = Theme.of(context).colorScheme.primary;
    final theme = existingTheme ??
        (isDark
            ? AppTheme.shadThemeDark(seedColor: seed)
            : AppTheme.shadThemeLight(seedColor: seed));

    final sheet = StandardBottomSheet(
      title: 'Select Repo',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...repos.map((repo) {
            final isSelected = repo.id == currentRepoId;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(repo.id),
                child: ShadCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: isSelected
                      ? ShadBorder.all(color: theme.colorScheme.primary, width: 1.5)
                      : null,
                  backgroundColor: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        repo.isDefault ? LucideIcons.star : LucideIcons.folder,
                        size: 18,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.mutedForeground,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              repo.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.foreground,
                              ),
                            ),
                            if (repo.shared)
                              Text(
                                'Shared',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(LucideIcons.check, size: 18, color: theme.colorScheme.primary)
                      else
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: theme.colorScheme.mutedForeground,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (repos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No repos found',
                    style: TextStyle(color: theme.colorScheme.mutedForeground)),
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
