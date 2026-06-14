import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final FlutterSecureStorage _storage;
  late final Dio dio;

  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(AuthInterceptor(_storage));
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (_) {},
    ));
  }

  void updateBaseUrl(String url) {
    final clean = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    dio.options.baseUrl = clean;
  }

  bool get hasBaseUrl => dio.options.baseUrl.isNotEmpty;
}

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final userToken = await _storage.read(key: userTokenKey);
    if (userToken != null && userToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $userToken';
    } else {
      final deviceToken = await _storage.read(key: deviceTokenKey);
      if (deviceToken != null && deviceToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $deviceToken';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _storage.delete(key: userTokenKey);
      await _storage.delete(key: userRefreshKey);
    }
    handler.next(err);
  }

  static const String userTokenKey = 'aosa_user_token';
  static const String userRefreshKey = 'aosa_user_refresh';
  static const String deviceTokenKey = 'aosa_device_token';
  static const String refreshTokenKey = 'aosa_refresh_token';
}
