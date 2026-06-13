import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:aosa/data/database/app_database.dart';
import 'package:aosa/data/encryption/crypto_service.dart';
import 'package:aosa/data/repositories/otp_repository_impl.dart';
import 'package:aosa/domain/repositories/otp_repository.dart';

class AppServices {
  final AppDatabase database;
  final CryptoService? cryptoService;
  final OtpRepository otpRepository;
  final bool isInitialized;

  const AppServices({
    required this.database,
    this.cryptoService,
    required this.otpRepository,
    this.isInitialized = false,
  });
}

class AppInitNotifier extends StateNotifier<AppServices?> {
  AppInitNotifier() : super(null);

  Future<void> initialize() async {
    final db = await AppDatabase.getInstance();
    final storage = const FlutterSecureStorage();

    final storedSalt = await _readStorage(storage, 'pin_salt');
    CryptoService? crypto;
    if (storedSalt != null) {
      final saltBytes = base64Decode(storedSalt);
      crypto = await CryptoService.fromPin('', saltBytes);
    }

    final repo = OtpRepositoryImpl(db, crypto ?? CryptoService(Uint8List(32)));
    state = AppServices(
      database: db,
      cryptoService: crypto,
      otpRepository: repo,
      isInitialized: true,
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
