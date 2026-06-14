import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aosa/data/api/api_client.dart';
import 'package:aosa/data/api/auth_api.dart';

enum AuthStatus { unregistered, registered, tokenExpired }

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;
  AuthApi? _authApi;

  AuthService(this._apiClient, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  String get _deviceIdKey => 'aosa_device_id';

  Future<String> getDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _generateUuid();
    await _storage.write(key: _deviceIdKey, value: id);
    return id;
  }

  Future<String?> getDeviceToken() =>
      _storage.read(key: AuthInterceptor.deviceTokenKey);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AuthInterceptor.refreshTokenKey);

  Future<AuthStatus> checkStatus() async {
    if (!_apiClient.hasBaseUrl) return AuthStatus.unregistered;
    final token = await getDeviceToken();
    if (token == null || token.isEmpty) return AuthStatus.unregistered;
    return AuthStatus.registered;
  }

  Future<void> register(String serverUrl) async {
    _apiClient.updateBaseUrl(serverUrl);
    _authApi = AuthApi(_apiClient.dio);

    final deviceId = await getDeviceId();
    final deviceName = await _storage.read(key: 'aosa_device_name') ?? '';

    final result = await _authApi!.register(
      deviceId: deviceId,
      deviceName: deviceName,
      pinPublicSalt: '',
      publicKey: '',
    );

    await _storage.write(
        key: AuthInterceptor.deviceTokenKey, value: result.deviceToken);
    await _storage.write(
        key: AuthInterceptor.refreshTokenKey, value: result.refreshToken);
  }

  Future<bool> refreshToken() async {
    final refreshTk = await getRefreshToken();
    if (refreshTk == null || refreshTk.isEmpty) return false;

    try {
      _authApi ??= AuthApi(_apiClient.dio);
      final result = await _authApi!.refresh(refreshTk);
      await _storage.write(
          key: AuthInterceptor.deviceTokenKey, value: result.deviceToken);
      await _storage.write(
          key: AuthInterceptor.refreshTokenKey, value: result.refreshToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: AuthInterceptor.deviceTokenKey);
    await _storage.delete(key: AuthInterceptor.refreshTokenKey);
  }

  String _generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    return [
      bytes.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      bytes.sublist(4, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      bytes.sublist(6, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      bytes.sublist(8, 10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      bytes.sublist(10, 16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    ].join('-');
  }
}
