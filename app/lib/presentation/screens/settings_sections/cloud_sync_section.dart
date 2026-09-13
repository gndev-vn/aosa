import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../domain/entities/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/repo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_init_provider.dart';
import '../../widgets/confirmation_bottom_sheet.dart';
import '../../widgets/standard_bottom_sheet.dart';
import '../../widgets/settings_helpers.dart';
import '../settings_sheets/cloud_config_sheet.dart';
import '../settings_sheets/repo_manager_sheet.dart';

class CloudSyncSection extends ConsumerWidget {
  final AppSettings settings;

  const CloudSyncSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shadTheme = ShadTheme.maybeOf(context);
    final mutedFg = shadTheme?.colorScheme.mutedForeground ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    final authFlow = ref.watch(authProvider);
    final isConnected = authFlow == AuthFlow.authenticated;
    final reposState = ref.watch(repoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Cloud sync'),
        ShadCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsRow(
                leading: const IconBox(icon: LucideIcons.cloud),
                title: 'Cloud sync',
                subtitle: 'Store your data on your self-hosted server',
                trailing: ShadSwitch(
                  value: settings.syncEnabled,
                  onChanged: (v) async {
                    if (v) {
                      if (context.mounted) {
                        await _showCloudConfigSheet(context, ref);
                      }
                    } else {
                      final confirmed = await showConfirmationBottomSheet(
                        context,
                        icon: LucideIcons.cloudOff,
                        title: 'Turn off cloud sync?',
                        message:
                            'All cloud data will be removed until you reconnect to the server. '
                            'Your existing local OTP accounts will remain.',
                        confirmLabel: 'Turn off',
                        cancelLabel: 'Cancel',
                        isDestructive: false,
                      );
                      if (confirmed && context.mounted) {
                        ref.read(settingsProvider.notifier).toggleSync(false);
                      }
                    }
                  },
                ),
              ),
              if (settings.syncEnabled) ...[
                const ThinDivider(),
                SettingsRow(
                  leading: const IconBox(icon: LucideIcons.server),
                  title: 'Server',
                  subtitle: _serverSubtitle(settings, isConnected),
                  trailing: Icon(LucideIcons.chevronRight,
                      size: 18, color: mutedFg),
                  onTap: () => _showCloudConfigSheet(context, ref),
                ),
                if (isConnected) ...[
                  const ThinDivider(),
                  SettingsRow(
                    leading: const IconBox(icon: LucideIcons.folder),
                    title: 'Repositories',
                    subtitle: _activeRepoName(reposState),
                    trailing: Icon(LucideIcons.chevronRight,
                        size: 18, color: mutedFg),
                    onTap: () => _showRepoManager(context),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _serverSubtitle(AppSettings settings, bool isConnected) {
    if (!isConnected) {
      return settings.serverUrl.isEmpty
          ? 'Not configured'
          : settings.serverUrl;
    }
    final lastSync = settings.lastSyncTime;
    if (lastSync == null) return 'Connected';
    final formatted = DateFormat('MMM d, h:mm a').format(lastSync);
    return 'Connected · Last sync: $formatted';
  }

  String _activeRepoName(RepoState reposState) {
    if (reposState.isLoading) return 'Loading...';
    if (reposState.error != null) return 'Error loading repos';
    final active = reposState.activeRepo;
    if (active != null) return active.name;
    if (reposState.repos.isEmpty) return 'No repos';
    return 'No repo selected';
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
      await _loadReposAndSync(context, ref);
    } else if (connected == false) {
      // Only toggle off if user explicitly disconnected (not just dismissed sheet)
      ref.read(settingsProvider.notifier).toggleSync(false);
    }
    // connected == null (dismissed) → do nothing
  }

  Future<void> _loadReposAndSync(BuildContext context, WidgetRef ref) async {
    final services = ref.read(appInitProvider);
    if (services == null) return;
    await ref.read(repoProvider.notifier).loadRepos(services.apiClient);
    if (context.mounted) {
      final error = await ref.read(syncProvider.notifier).runSync(ref);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showRepoManager(BuildContext context) {
    showSlideBottomSheet<void>(
      context,
      builder: (_) => const RepoManagerSheet(),
    );
  }
}
