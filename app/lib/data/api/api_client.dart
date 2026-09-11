import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

class ApiClient {
  final FlutterSecureStorage _storage;
  late final Dio dio;

  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),);

    dio.interceptors.add(AuthInterceptor(_storage));
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => _logger.d('[API] $obj'),
    ),);
  }

  static const String apiPrefix = '/api/v1';

  void updateBaseUrl(String url) {
    var clean = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    if (clean.endsWith(apiPrefix)) {
      clean = clean.substring(0, clean.length - apiPrefix.length);
    }
    dio.options.baseUrl = '$clean$apiPrefix/';
  }

  bool get hasBaseUrl => dio.options.baseUrl.isNotEmpty;
}

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler,) async {
    final userToken = await _storage.read(key: userTokenKey);
    if (userToken != null && userToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $userToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Pass 401 through without deleting tokens — the caller handles
    // credential expiry (shows error, lets user reconnect manually).
    // Previously we deleted tokens here, which caused the UI to silently
    // lose the "Connected" state after a JWT expired.
    handler.next(err);
  }

  static const String userTokenKey = 'aosa_user_token';
  static const String userRefreshKey = 'aosa_user_refresh';
}
