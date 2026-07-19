import 'package:aosa/data/api/api_client.dart';
import 'package:aosa/data/api/repo_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RepoState {
  final List<RepoInfo> repos;
  final String activeRepoId;
  final bool isLoading;
  final String? error;

  const RepoState({
    this.repos = const [],
    this.activeRepoId = '',
    this.isLoading = false,
    this.error,
  });

  RepoState copyWith({
    List<RepoInfo>? repos,
    String? activeRepoId,
    bool? isLoading,
    String? error,
  }) {
    return RepoState(
      repos: repos ?? this.repos,
      activeRepoId: activeRepoId ?? this.activeRepoId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  RepoInfo? get activeRepo {
    if (repos.isEmpty || activeRepoId.isEmpty) return null;
    return repos.where((r) => r.id == activeRepoId).firstOrNull;
  }
}

class RepoNotifier extends StateNotifier<RepoState> {
  final FlutterSecureStorage _storage;

  RepoNotifier() : _storage = const FlutterSecureStorage(), super(const RepoState());

  Future<void> loadRepos(ApiClient api) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repos = await RepoApi(api.dio).list();
      final activeId = await _resolveActiveRepoId(repos);
      state = RepoState(repos: repos, activeRepoId: activeId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load repos');
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
      final remaining = state.repos.where((r) => r.id != id).toList();
      final newActiveId = await _resolveActiveRepoId(remaining);
      state = RepoState(repos: remaining, activeRepoId: newActiveId);
      await _storage.write(key: 'aosa_active_repo_id', value: newActiveId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> setActiveRepoId(String id) async {
    await _storage.write(key: 'aosa_active_repo_id', value: id);
    state = state.copyWith(activeRepoId: id);
  }

  Future<String> _resolveActiveRepoId(List<RepoInfo> repos) async {
    final stored = await _storage.read(key: 'aosa_active_repo_id');
    if (stored != null && stored.isNotEmpty && repos.any((r) => r.id == stored)) {
      return stored;
    }
    if (repos.isNotEmpty) {
      final defaultRepo = repos.firstWhere(
        (r) => r.isDefault,
        orElse: () => repos.first,
      );
      await _storage.write(key: 'aosa_active_repo_id', value: defaultRepo.id);
      return defaultRepo.id;
    }
    return '';
  }
}

final repoProvider =
    StateNotifierProvider<RepoNotifier, RepoState>(
  (_) => RepoNotifier(),
);
