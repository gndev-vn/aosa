import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';
import '../providers/sync_provider.dart';


class HomeHeader extends StatelessWidget {
  final bool syncEnabled;
  final bool isAuthenticated;
  final SyncState syncState;
  final String? activeRepoName;
  final VoidCallback? onSync;
  final VoidCallback? onSelectRepo;
  final VoidCallback onSettings;

  const HomeHeader({
    super.key,
    required this.syncEnabled,
    required this.isAuthenticated,
    required this.syncState,
    this.activeRepoName,
    this.onSync,
    this.onSelectRepo,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final existingTheme = ShadTheme.maybeOf(context);
    final isDark = existingTheme?.brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.dark;
    final seedColor = Theme.of(context).colorScheme.primary;
    final theme = existingTheme ??
        (isDark
            ? AppTheme.shadThemeDark(seedColor: seedColor)
            : AppTheme.shadThemeLight(seedColor: seedColor));
    final isSyncing = syncState == SyncState.syncing;

    final title = Text(
      'AOSA',
      style: AppTheme.titleStyle(color: theme.colorScheme.foreground),
    );

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (syncEnabled && isAuthenticated)
            ShadButton.outline(
              width: 36,
              height: 36,
              padding: EdgeInsets.zero,
              onPressed: isSyncing ? () {} : onSync!,
              child: Icon(
                LucideIcons.refreshCw,
                size: 16,
                color: theme.colorScheme.foreground,
              ),
            )
          else
            const SizedBox(width: 36),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                title,
                if (syncEnabled && activeRepoName != null) ...[
                  const SizedBox(height: 4),
                  ShadButton.outline(
                    size: ShadButtonSize.sm,
                    height: 28,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    onPressed: onSelectRepo,
                    leading: Icon(
                      LucideIcons.folder,
                      size: 13,
                      color: theme.colorScheme.mutedForeground,
                    ),
                    trailing: Icon(
                      LucideIcons.chevronDown,
                      size: 13,
                      color: theme.colorScheme.mutedForeground,
                    ),
                    child: Text(
                      activeRepoName!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.foreground,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ShadButton.outline(
            width: 36,
            height: 36,
            padding: EdgeInsets.zero,
            onPressed: onSettings,
            child: Icon(
              LucideIcons.settings,
              size: 16,
              color: theme.colorScheme.foreground,
            ),
          ),
        ],
      ),
    );

    final header = Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.border,
            width: 1.0,
          ),
        ),
      ),
      child: content,
    );

    if (existingTheme == null) {
      return ShadTheme(
        data: theme,
        child: header,
      );
    }
    return header;

  }
}
