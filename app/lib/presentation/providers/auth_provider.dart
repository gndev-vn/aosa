import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aosa/data/api/user_api.dart';

enum AuthFlow { unauthenticated, authenticating, authenticated }

class AuthNotifier extends StateNotifier<AuthFlow> {
  final FlutterSecureStorage _storage;

  AuthNotifier() : _storage = const FlutterSecureStorage(), super(AuthFlow.unauthenticated);

  Future<void> checkSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) {
      state = AuthFlow.authenticated;
    }
  }

  Future<String?> signup(String serverUrl, String username, String password) async {
    state = AuthFlow.authenticating;
    try {
      final dio = Dio(BaseOptions(baseUrl: serverUrl, contentType: 'application/json'));
      final api = UserApi(dio);
      final result = await api.signup(username: username, password: password);

      await _persist(result.userId, result.token, result.refreshToken);
      await _storage.write(key: _activeRepoKey, value: result.defaultRepoId);

      state = AuthFlow.authenticated;
      return null;
    } catch (e) {
      state = AuthFlow.unauthenticated;
      return e.toString();
    }
  }

  Future<String?> login(String serverUrl, String username, String password) async {
    state = AuthFlow.authenticating;
    try {
      final dio = Dio(BaseOptions(baseUrl: serverUrl, contentType: 'application/json'));
      final api = UserApi(dio);
      final result = await api.login(username: username, password: password);

      await _persist(result.userId, result.token, result.refreshToken);
      state = AuthFlow.authenticated;
      return null;
    } catch (e) {
      state = AuthFlow.unauthenticated;
      return e.toString();
    }
  }

  Future<String?> connectWithToken(String serverUrl, String token) async {
    state = AuthFlow.authenticating;
    try {
      final dio = Dio(BaseOptions(
        baseUrl: serverUrl,
        contentType: 'application/json',
        headers: {'Authorization': 'Bearer $token'},
      ));
      final api = UserApi(dio);
      final me = await api.me();
      await _persist(me.userId, token, '');
      await _storage.write(key: _serverUrlKey, value: serverUrl);
      state = AuthFlow.authenticated;
      return null;
    } catch (e) {
      state = AuthFlow.unauthenticated;
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userIdKey);
    state = AuthFlow.unauthenticated;
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<String?> getUserId() => _storage.read(key: _userIdKey);

  Future<void> _persist(String userId, String token, String refresh) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _refreshKey, value: refresh);
    await _storage.write(key: _userIdKey, value: userId);
  }

  static const _tokenKey = 'aosa_user_token';
  static const _refreshKey = 'aosa_user_refresh';
  static const _userIdKey = 'aosa_user_id';
  static const _activeRepoKey = 'aosa_active_repo_id';
  static const _serverUrlKey = 'aosa_server_url';
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthFlow>(
  (_) => AuthNotifier(),
);
