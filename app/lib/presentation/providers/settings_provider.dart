import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  Future<void> load() async {
    const storage = FlutterSecureStorage();
    final json = await _readStorage(storage, _storageKey);
    if (json != null) {
      state = AppSettings.fromJson(jsonDecode(json) as Map<String, dynamic>);
    }
  }

  Future<void> _persist() async {
    const storage = FlutterSecureStorage();
    try {
      await storage.write(key: _storageKey, value: jsonEncode(state.toJson()));
    } on PlatformException {
      // keyring unavailable — settings won't persist across restarts
    }
  }

  Future<String?> _readStorage(FlutterSecureStorage storage, String key) async {
    try {
      return await storage.read(key: key);
    } on PlatformException {
      return null;
    }
  }

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _persist();
  }

  void setSeedColor(int color) {
    state = state.copyWith(seedColor: color);
    _persist();
  }

  void setPinEnabled(bool enabled) {
    state = state.copyWith(pinEnabled: enabled);
    _persist();
  }

  void toggleBiometric(bool enabled) {
    state = state.copyWith(biometricEnabled: enabled);
    _persist();
  }

  void setAutoLockTimeout(AutoLockTimeout timeout) {
    state = state.copyWith(autoLockTimeout: timeout);
    _persist();
  }

  void toggleSync(bool enabled) {
    state = state.copyWith(syncEnabled: enabled);
    _persist();
  }

  void setServerUrl(String url) {
    state = state.copyWith(serverUrl: url);
    _persist();
  }

  void setDeviceName(String name) {
    state = state.copyWith(deviceName: name);
    _persist();
  }

  void setGlobalHotkey(String hotkey) {
    state = state.copyWith(globalHotkey: hotkey);
    _persist();
  }

  void toggleMinimizeToTray(bool enabled) {
    state = state.copyWith(minimizeToTray: enabled);
    _persist();
  }

  static const _storageKey = 'app_settings';
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
  (_) => SettingsNotifier(),
);
