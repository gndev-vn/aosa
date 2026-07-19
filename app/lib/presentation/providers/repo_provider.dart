import 'package:aosa/data/api/api_client.dart';
import 'package:aosa/data/api/repo_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RepoNotifier extends StateNotifier<AsyncValue<List<RepoInfo>>> {
  final FlutterSecureStorage _storage;

  RepoNotifier() : _storage = const FlutterSecureStorage(), super(const AsyncValue.loading());

  Future<void> loadRepos(ApiClient api) async {
    state = const AsyncValue.loading();
    try {
      final repos = await RepoApi(api.dio).list();
      state = AsyncValue.data(repos);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<String?> createRepo(ApiClient api, String name) async {
    try {
      await RepoApi(api.dio).create(name);
      await loadRepos(api);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteRepo(ApiClient api, String id) async {
    try {
      await RepoApi(api.dio).delete(id);
      await loadRepos(api);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> getActiveRepoId() async {
    final stored = await _storage.read(key: 'aosa_active_repo_id');
    if (stored != null && stored.isNotEmpty) return stored;

    final data = state;
    if (data.hasValue && data.value!.isNotEmpty) {
      final defaultRepo = data.value!.firstWhere(
        (r) => r.isDefault,
        orElse: () => data.value!.first,
      );
      await _storage.write(key: 'aosa_active_repo_id', value: defaultRepo.id);
      return defaultRepo.id;
    }
    return '';
  }

  Future<void> setActiveRepoId(String id) async {
    await _storage.write(key: 'aosa_active_repo_id', value: id);
  }
}

final repoProvider =
    StateNotifierProvider<RepoNotifier, AsyncValue<List<RepoInfo>>>(
  (_) => RepoNotifier(),
);
