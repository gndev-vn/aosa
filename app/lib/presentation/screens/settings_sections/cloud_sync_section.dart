import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/repo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/aosa_widgets.dart';
import '../../widgets/standard_bottom_sheet.dart';
import '../../widgets/settings_helpers.dart';
import '../settings_sheets/cloud_config_sheet.dart';
import '../settings_sheets/repo_manager_sheet.dart';

class CloudSyncSection extends ConsumerWidget {
  final AppSettings settings;

  const CloudSyncSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final authFlow = ref.watch(authProvider);
    final syncState = ref.watch(syncProvider);
    final isConnected = authFlow == AuthFlow.authenticated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Cloud sync'),
        AosaCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsRow(
                leading: const IconBox(icon: Icons.cloud_outlined),
                title: 'Cloud sync',
                subtitle: 'Store your data on your self-hosted server',
                trailing: AosaSwitch(
                  value: settings.syncEnabled,
                  onChanged: (v) async {
                    if (v) {
                      if (context.mounted) {
                        await _showCloudConfigSheet(context, ref);
                      }
                    } else {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Turn off cloud sync?'),
                          content: const Text(
                            'All cloud data will be removed until you reconnect to the server. '
                            'Your existing local OTP accounts will remain.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Turn off'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        ref.read(settingsProvider.notifier).toggleSync(false);
                      }
                    }
                  },
                ),
              ),
              if (settings.syncEnabled) ...[
                const ThinDivider(),
                SettingsRow(
                  leading: IconBox(
                    icon: Icons.dns_outlined,
                    color: colorScheme.secondaryContainer,
                  ),
                  title: 'Server',
                  subtitle: isConnected
                      ? 'Connected'
                      : (settings.serverUrl.isEmpty
                          ? 'Not configured'
                          : settings.serverUrl),
                  trailing: Icon(Icons.chevron_right,
                      size: 18, color: colorScheme.onSurfaceVariant),
                  onTap: () => _showCloudConfigSheet(context, ref),
                ),
                if (isConnected) ...[
                  const ThinDivider(),
                  SettingsRow(
                    leading: const IconBox(icon: Icons.folder_outlined),
                    title: 'Repos',
                    subtitle: 'Manage your repositories',
                    trailing: Icon(Icons.chevron_right,
                        size: 18, color: colorScheme.onSurfaceVariant),
                    onTap: () => _showRepoManager(context, ref),
                  ),
                  const ThinDivider(),
                  _SyncActions(
                    syncState: syncState,
                    onSync: () => _triggerSync(context, ref),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showCloudConfigSheet(
      BuildContext context, WidgetRef ref) async {
    final connected = await showSlideBottomSheet<bool>(
      context,
      isScrollControlled: true,
      builder: (_) => const CloudConfigSheet(),
    );

    if (!context.mounted) return;
    if (connected == true) {
      ref.read(settingsProvider.notifier).toggleSync(true);
    } else {
      ref.read(settingsProvider.notifier).toggleSync(false);
    }
  }

  void _showRepoManager(BuildContext context, WidgetRef ref) {
    final reposAsync = ref.read(repoProvider);
    reposAsync.whenData((repos) {
      showSlideBottomSheet<void>(
        context,
        builder: (_) => RepoManagerSheet(repos: repos),
      );
    });
  }

  Future<void> _triggerSync(BuildContext context, WidgetRef ref) async {
    final error = await ref.read(syncProvider.notifier).runSync(ref);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _SyncActions extends StatelessWidget {
  final SyncState syncState;
  final VoidCallback onSync;

  const _SyncActions({required this.syncState, required this.onSync});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AosaButton(
                  onPressed: syncState == SyncState.syncing ? null : onSync,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        syncState == SyncState.syncing
                            ? Icons.hourglass_top
                            : Icons.sync_rounded,
                        size: 18,
                        color: cs.onPrimary.withAlpha(160),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        syncState == SyncState.syncing
                            ? 'Syncing…'
                            : 'Sync now',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (syncState == SyncState.success)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Sync completed',
                  style: TextStyle(fontSize: 13, color: cs.primary)),
            ),
          if (syncState == SyncState.error)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Sync failed',
                  style: TextStyle(fontSize: 13, color: cs.error)),
            ),
        ],
      ),
    );
  }
}
