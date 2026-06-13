import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

enum AppPlatform { android, ios, linux, macOS, windows, web }

class AppPlatformUtil {
  static AppPlatform get current {
    if (kIsWeb) return AppPlatform.web;
    if (Platform.isAndroid) return AppPlatform.android;
    if (Platform.isIOS) return AppPlatform.ios;
    if (Platform.isLinux) return AppPlatform.linux;
    if (Platform.isMacOS) return AppPlatform.macOS;
    if (Platform.isWindows) return AppPlatform.windows;
    return AppPlatform.web;
  }

  static bool get isAndroid => current == AppPlatform.android;
  static bool get isIOS => current == AppPlatform.ios;

  static int get androidApiLevel {
    if (!isAndroid) return 0;
    try {
      final version = Platform.operatingSystemVersion;
      final apiMatch = RegExp(r'API\s*(\d+)').firstMatch(version);
      if (apiMatch != null) return int.parse(apiMatch.group(1)!);
      final sdkMatch = RegExp(r'sdk\s*(\d+)', caseSensitive: false).firstMatch(version);
      if (sdkMatch != null) return int.parse(sdkMatch.group(1)!);
    } catch (_) {}
    return 0;
  }

  static bool get isAndroid16OrLater => androidApiLevel >= 37;
}
