import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aosa/data/api/repo_api.dart';
import 'auth_provider.dart';

class RepoNotifier extends StateNotifier<AsyncValue<List<RepoInfo>>> {
  final FlutterSecureStorage _storage;

  RepoNotifier() : _storage = const FlutterSecureStorage(), super(const AsyncValue.loading());

  Future<void> loadRepos(String serverUrl, String token) async {
    state = const AsyncValue.loading();
    try {
      final dio = Dio(BaseOptions(
        baseUrl: serverUrl,
        contentType: 'application/json',
        headers: {'Authorization': 'Bearer $token'},
      ));
      final api = RepoApi(dio);
      final repos = await api.list();
      state = AsyncValue.data(repos);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<String?> createRepo(String serverUrl, String token, String name) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: serverUrl,
        contentType: 'application/json',
        headers: {'Authorization': 'Bearer $token'},
      ));
      final api = RepoApi(dio);
      await api.create(name);
      await loadRepos(serverUrl, token);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteRepo(String serverUrl, String token, String id) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: serverUrl,
        contentType: 'application/json',
        headers: {'Authorization': 'Bearer $token'},
      ));
      final api = RepoApi(dio);
      await api.delete(id);
      await loadRepos(serverUrl, token);
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
