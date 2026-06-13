import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/app_settings.dart';
import 'settings_provider.dart';

final themeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(settingsProvider);
  final seedColor = Color(settings.seedColor);

  return switch (settings.themeMode) {
    AppThemeMode.light => AppTheme.light(seedColor: seedColor),
    AppThemeMode.dark => AppTheme.dark(seedColor: seedColor),
    AppThemeMode.system => PlatformDispatcher.instance.platformBrightness ==
            Brightness.dark
        ? AppTheme.dark(seedColor: seedColor)
        : AppTheme.light(seedColor: seedColor),
  };
});
