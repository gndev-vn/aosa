import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_init_provider.dart';
import 'settings_provider.dart';

enum SyncState { idle, syncing, success, error }

class SyncNotifier extends StateNotifier<SyncState> {
  final FlutterSecureStorage _storage;

  SyncNotifier() : _storage = const FlutterSecureStorage(), super(SyncState.idle);

  Future<String?> runSync(WidgetRef ref) async {
    final services = ref.read(appInitProvider);
    if (services == null) return 'App not initialized';

    final settings = ref.read(settingsProvider);
    if (settings.serverUrl.isEmpty) return 'Server URL not configured';

    final repoId = await _storage.read(key: 'aosa_active_repo_id');
    if (repoId == null || repoId.isEmpty) return 'No repo selected';

    if (services.syncService == null) {
      ref.read(appInitProvider.notifier).configureSync(settings.serverUrl);
    }

    final updated = ref.read(appInitProvider);
    final syncService = updated?.syncService;
    if (syncService == null) return 'Failed to initialize sync';

    final hasToken = await services.authService.hasToken();
    if (!hasToken) return 'Not authenticated. Please log in first.';

    state = SyncState.syncing;
    try {
      final error = await syncService.fullSync(repoId: repoId);
      if (error != null) {
        state = SyncState.error;
        return error;
      }
      // Store the last sync time
      ref.read(settingsProvider.notifier).setLastSyncTime(DateTime.now());
      state = SyncState.success;
      return null;
    } catch (e) {
      state = SyncState.error;
      return e.toString();
    }
  }

  void reset() => state = SyncState.idle;
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>(
  (_) => SyncNotifier(),
);
