enum AppThemeMode { light, dark, system }

enum AutoLockTimeout { immediate, seconds30, minute1, minutes5 }

class AppSettings {
  final AppThemeMode themeMode;
  final int seedColor;
  final bool pinEnabled;
  final bool biometricEnabled;
  final AutoLockTimeout autoLockTimeout;
  final bool syncEnabled;
  final String serverUrl;
  final String deviceName;
  final String globalHotkey;
  final bool minimizeToTray;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.seedColor = 0xff1976d2,
    this.pinEnabled = false,
    this.biometricEnabled = false,
    this.autoLockTimeout = AutoLockTimeout.immediate,
    this.syncEnabled = false,
    this.serverUrl = '',
    this.deviceName = '',
    this.globalHotkey = '',
    this.minimizeToTray = false,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    int? seedColor,
    bool? pinEnabled,
    bool? biometricEnabled,
    AutoLockTimeout? autoLockTimeout,
    bool? syncEnabled,
    String? serverUrl,
    String? deviceName,
    String? globalHotkey,
    bool? minimizeToTray,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      serverUrl: serverUrl ?? this.serverUrl,
      deviceName: deviceName ?? this.deviceName,
      globalHotkey: globalHotkey ?? this.globalHotkey,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
    );
  }

  Map<String, dynamic> toJson() => {
        'theme_mode': themeMode.name,
        'seed_color': seedColor,
        'pin_enabled': pinEnabled,
        'biometric_enabled': biometricEnabled,
        'auto_lock_timeout': autoLockTimeout.name,
        'sync_enabled': syncEnabled,
        'server_url': serverUrl,
        'device_name': deviceName,
        'global_hotkey': globalHotkey,
        'minimize_to_tray': minimizeToTray,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: AppThemeMode.values.firstWhere(
          (e) => e.name == json['theme_mode'],
          orElse: () => AppThemeMode.system,
        ),
        seedColor: json['seed_color'] as int? ?? 0xff1976d2,
        pinEnabled: json['pin_enabled'] as bool? ?? false,
        biometricEnabled: json['biometric_enabled'] as bool? ?? false,
        autoLockTimeout: AutoLockTimeout.values.firstWhere(
          (e) => e.name == json['auto_lock_timeout'],
          orElse: () => AutoLockTimeout.immediate,
        ),
        syncEnabled: json['sync_enabled'] as bool? ?? false,
        serverUrl: json['server_url'] as String? ?? '',
        deviceName: json['device_name'] as String? ?? '',
        globalHotkey: json['global_hotkey'] as String? ?? '',
        minimizeToTray: json['minimize_to_tray'] as bool? ?? false,
      );
}
