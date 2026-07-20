import 'package:aosa/data/api/api_client.dart';
import 'package:aosa/data/api/repo_api.dart';
import 'package:aosa/data/api/user_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AuthFlow { initializing, unauthenticated, authenticating, authenticated }

class AuthNotifier extends StateNotifier<AuthFlow> {
  final FlutterSecureStorage _storage;

  AuthNotifier() : _storage = const FlutterSecureStorage(), super(AuthFlow.initializing);

  Future<void> checkSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) {
      state = AuthFlow.authenticated;
    } else {
      state = AuthFlow.unauthenticated;
    }
  }

  Future<String?> signup(ApiClient api, String username, String password) async {
    state = AuthFlow.authenticating;
    try {
      final api_ = UserApi(api.dio);
      final result = await api_.signup(username: username, password: password);

      await _persist(result.userId, result.token, result.refreshToken,
          username: username, password: password);
      await _storage.write(key: _activeRepoKey, value: result.defaultRepoId);

      state = AuthFlow.authenticated;
      return null;
    } catch (e) {
      state = AuthFlow.unauthenticated;
      return _humanizeError(e);
    }
  }

  Future<String?> login(ApiClient api, String username, String password) async {
    state = AuthFlow.authenticating;
    try {
      final api_ = UserApi(api.dio);
      final result = await api_.login(username: username, password: password);

      await _persist(result.userId, result.token, result.refreshToken,
          username: username, password: password);
      state = AuthFlow.authenticated;

      try {
        final repos = await RepoApi(api.dio).list();
        final defaultRepo = repos.firstWhere(
          (r) => r.isDefault,
          orElse: () => repos.first,
        );
        await _storage.write(key: _activeRepoKey, value: defaultRepo.id);
      } catch (_) {}

      return null;
    } catch (e) {
      state = AuthFlow.unauthenticated;
      return _humanizeError(e);
    }
  }

  Future<String?> connectWithToken(ApiClient api, String serverUrl, String token) async {
    state = AuthFlow.authenticating;
    try {
      api.dio.options.headers['Authorization'] = 'Bearer $token';
      final api_ = UserApi(api.dio);
      final me = await api_.me();
      api.dio.options.headers.remove('Authorization');

      await _persist(me.userId, token, '');
      await _storage.write(key: _serverUrlKey, value: serverUrl);
      state = AuthFlow.authenticated;

      try {
        final repos = await RepoApi(api.dio).list();
        final defaultRepo = repos.firstWhere(
          (r) => r.isDefault,
          orElse: () => repos.first,
        );
        await _storage.write(key: _activeRepoKey, value: defaultRepo.id);
      } catch (_) {}

      return null;
    } catch (e) {
      api.dio.options.headers.remove('Authorization');
      state = AuthFlow.unauthenticated;
      return _humanizeError(e);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _activeRepoKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
    state = AuthFlow.unauthenticated;
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<String?> getUserId() => _storage.read(key: _userIdKey);
  Future<String?> getUsername() => _storage.read(key: _usernameKey);
  Future<String?> getPassword() => _storage.read(key: _passwordKey);

  Future<void> _persist(String userId, String token, String refresh,
      {String? username, String? password}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _refreshKey, value: refresh);
    await _storage.write(key: _userIdKey, value: userId);
    if (username != null && username.isNotEmpty) {
      await _storage.write(key: _usernameKey, value: username);
    }
    if (password != null && password.isNotEmpty) {
      await _storage.write(key: _passwordKey, value: password);
    }
  }

  static String _humanizeError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 401) return 'Invalid credentials';
      if (status == 404) return 'Server not found';
      if (status == 409) return 'Username already taken';
      if (status == 429) return 'Too many requests. Try again later';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Cannot reach server';
      }
    }
    return 'Something went wrong. Please try again';
  }

  static const _tokenKey = 'aosa_user_token';
  static const _refreshKey = 'aosa_user_refresh';
  static const _userIdKey = 'aosa_user_id';
  static const _activeRepoKey = 'aosa_active_repo_id';
  static const _serverUrlKey = 'aosa_server_url';
  static const _usernameKey = 'aosa_username';
  static const _passwordKey = 'aosa_user_password';
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthFlow>(
  (_) => AuthNotifier(),
);
