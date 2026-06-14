import 'package:dio/dio.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<RegisterResult> register({
    required String deviceId,
    required String deviceName,
    required String pinPublicSalt,
    required String publicKey,
  }) async {
    final response = await _dio.post('/api/v1/auth/register', data: {
      'device_id': deviceId,
      'device_name': deviceName,
      'pin_public_salt': pinPublicSalt,
      'public_key': publicKey,
    });

    final data = response.data as Map<String, dynamic>;
    return RegisterResult(
      deviceToken: data['device_token'] as String,
      refreshToken: data['refresh_token'] as String,
      serverVersion: data['server_version'] as int,
    );
  }

  Future<RefreshResult> refresh(String refreshToken) async {
    final response = await _dio.post('/api/v1/auth/refresh', data: {
      'refresh_token': refreshToken,
    });

    final data = response.data as Map<String, dynamic>;
    return RefreshResult(
      deviceToken: data['device_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
  }
}

class RegisterResult {
  final String deviceToken;
  final String refreshToken;
  final int serverVersion;

  const RegisterResult({
    required this.deviceToken,
    required this.refreshToken,
    required this.serverVersion,
  });
}

class RefreshResult {
  final String deviceToken;
  final String refreshToken;

  const RefreshResult({
    required this.deviceToken,
    required this.refreshToken,
  });
}
