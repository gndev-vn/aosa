import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../providers/sync_provider.dart';
import 'aosa_widgets.dart';

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
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final titleStyle = textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: cs.onSurface,
        ) ??
        AppTheme.titleStyle(color: cs.onSurface);

    final title = Text(
      'AOSA',
      style: titleStyle,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
      child: Row(
        children: [
          if (syncEnabled && isAuthenticated)
            aosaIconButton(
              icon: syncState == SyncState.syncing
                  ? Icons.hourglass_top
                  : Icons.sync_rounded,
              color: cs.onSurface,
              onPressed: syncState == SyncState.syncing
                  ? () {}
                  : (onSync ?? () {}),
            )
          else
            const SizedBox(width: 40),
          Expanded(
            child: syncEnabled
                ? GestureDetector(
                    onTap: onSelectRepo,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        title,
                        if (activeRepoName != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                size: 14,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                activeRepoName!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: cs.primary,
                                ),
                              ),
                              Icon(
                                Icons.expand_more,
                                size: 14,
                                color: cs.primary,
                              ),
                            ],
                          ),
                      ],
                    ),
                  )
                : Center(child: title),
          ),
          aosaIconButton(
            icon: Icons.settings,
            color: cs.onSurface,
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}
