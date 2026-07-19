import 'package:aosa/data/api/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage _storage;

  AuthService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<bool> hasToken() async {
    final token = await _storage.read(key: AuthInterceptor.userTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() =>
      _storage.read(key: AuthInterceptor.userTokenKey);

  Future<void> clear() async {
    await _storage.delete(key: AuthInterceptor.userTokenKey);
    await _storage.delete(key: AuthInterceptor.userRefreshKey);
  }
}
