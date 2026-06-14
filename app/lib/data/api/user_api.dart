import 'package:dio/dio.dart';

class UserApi {
  final Dio _dio;

  UserApi(this._dio);

  Future<SignupResult> signup({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post('/api/v1/auth/signup', data: {
      'username': username,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    return SignupResult(
      userId: data['user_id'] as String,
      token: data['token'] as String,
      refreshToken: data['refresh_token'] as String,
      defaultRepoId: data['default_repo_id'] as String,
    );
  }

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post('/api/v1/auth/login', data: {
      'username': username,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    return LoginResult(
      userId: data['user_id'] as String,
      token: data['token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
  }

  Future<MeResult> me() async {
    final response = await _dio.get('/api/v1/auth/me');
    final data = response.data as Map<String, dynamic>;
    return MeResult(
      userId: data['user_id'] as String,
      username: data['username'] as String,
    );
  }
}

class SignupResult {
  final String userId;
  final String token;
  final String refreshToken;
  final String defaultRepoId;

  const SignupResult({
    required this.userId,
    required this.token,
    required this.refreshToken,
    required this.defaultRepoId,
  });
}

class LoginResult {
  final String userId;
  final String token;
  final String refreshToken;

  const LoginResult({
    required this.userId,
    required this.token,
    required this.refreshToken,
  });
}

class MeResult {
  final String userId;
  final String username;

  const MeResult({
    required this.userId,
    required this.username,
  });
}
