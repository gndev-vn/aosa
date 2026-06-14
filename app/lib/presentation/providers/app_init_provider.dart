import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:aosa/data/api/api_client.dart';
import 'package:aosa/data/api/sync_api.dart';
import 'package:aosa/data/database/app_database.dart';
import 'package:aosa/data/encryption/crypto_service.dart';
import 'package:aosa/data/repositories/otp_repository_impl.dart';
import 'package:aosa/data/services/auth_service.dart';
import 'package:aosa/data/services/sync_service.dart';
import 'package:aosa/domain/repositories/otp_repository.dart';

class AppServices {
  final AppDatabase database;
  final CryptoService? cryptoService;
  final OtpRepository otpRepository;
  final ApiClient apiClient;
  final AuthService authService;
  final SyncService? syncService;
  final bool isInitialized;

  const AppServices({
    required this.database,
    this.cryptoService,
    required this.otpRepository,
    required this.apiClient,
    required this.authService,
    this.syncService,
    this.isInitialized = false,
  });

  AppServices copyWith({
    AppDatabase? database,
    CryptoService? cryptoService,
    OtpRepository? otpRepository,
    ApiClient? apiClient,
    AuthService? authService,
    SyncService? syncService,
    bool? isInitialized,
  }) {
    return AppServices(
      database: database ?? this.database,
      cryptoService: cryptoService ?? this.cryptoService,
      otpRepository: otpRepository ?? this.otpRepository,
      apiClient: apiClient ?? this.apiClient,
      authService: authService ?? this.authService,
      syncService: syncService ?? this.syncService,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AppInitNotifier extends StateNotifier<AppServices?> {
  AppInitNotifier() : super(null);

  Future<void> initialize() async {
    final db = await AppDatabase.getInstance();
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(storage: storage);

    final storedSalt = await _readStorage(storage, 'pin_salt');
    CryptoService? crypto;
    if (storedSalt != null) {
      final saltBytes = base64Decode(storedSalt);
      crypto = await CryptoService.fromPin('', saltBytes);
    }

    final key = crypto != null ? Uint8List(32) : Uint8List(32);

    final effectiveCrypto = crypto ?? CryptoService(key);
    final authService = AuthService(apiClient, storage: storage);

    final repo = OtpRepositoryImpl(db, effectiveCrypto);
    state = AppServices(
      database: db,
      cryptoService: effectiveCrypto,
      otpRepository: repo,
      apiClient: apiClient,
      authService: authService,
      isInitialized: true,
    );

    // init sync if server URL is configured
    final serverUrl = await _readStorage(storage, 'server_url');
    if (serverUrl != null && serverUrl.isNotEmpty) {
      configureSync(serverUrl);
    }
  }

  void configureSync(String serverUrl) {
    final current = state;
    if (current == null) return;
    current.apiClient.updateBaseUrl(serverUrl);
    final syncApi = SyncApi(current.apiClient.dio);
    state = current.copyWith(
      syncService: SyncService(
        syncApi,
        current.database,
        current.cryptoService ?? CryptoService(Uint8List(32)),
      ),
    );
  }

  Future<String?> _readStorage(FlutterSecureStorage storage, String key) async {
    try {
      return await storage.read(key: key);
    } on PlatformException {
      return null;
    }
  }
}

final appInitProvider =
    StateNotifierProvider<AppInitNotifier, AppServices?>(
  (_) => AppInitNotifier(),
);
