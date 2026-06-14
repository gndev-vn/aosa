import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aosa/data/services/auth_service.dart';
import 'package:aosa/data/services/sync_service.dart';
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

    final authStatus = await services.authService.checkStatus();
    if (authStatus == AuthStatus.unregistered) {
      try {
        await services.authService.register(settings.serverUrl);
      } catch (e) {
        return 'Registration failed: $e';
      }
    }

    state = SyncState.syncing;
    try {
      final error = await syncService.fullSync(repoId: repoId);
      if (error != null) {
        state = SyncState.error;
        return error;
      }
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
