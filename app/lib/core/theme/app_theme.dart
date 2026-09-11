import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const radiusSm = 12.0;
  static const radiusLg = 28.0;
  static const radiusPill = 24.0;

  static const darkSurface = Color(0xFF1A1C1E);
  static const darkCardSurface = Color(0xFF232528);
  static const lightSurface = Color(0xFFF8F9FA);
  static const lightCardSurface = Colors.white;

  static const _radiusSm = radiusSm;
  static const _radiusLg = radiusLg;
  static const _radiusPill = radiusPill;

  static TextStyle titleStyle({Color? color}) {
    return _inter(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: color,
    );
  }

  static TextStyle codeStyle({Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: 2.0,
      color: color,
    );
  }

  static ThemeData light({required Color seedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      surface: lightSurface,
    );
    return _buildTheme(colorScheme, Brightness.light);
  }

  static ThemeData dark({required Color seedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF1A1C1E),
    );
    return _buildTheme(colorScheme, Brightness.dark);
  }

  static TextStyle _inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      splashFactory: InkRipple.splashFactory,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: _inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: colorScheme.onSurface,
        ),
      ),

      textTheme: TextTheme(
        headlineLarge: _inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: colorScheme.onSurface,
        ),
        headlineMedium: _inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: colorScheme.onSurface,
        ),
        headlineSmall: _inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        titleLarge: _inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        titleMedium: _inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        titleSmall: _inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        bodyLarge: _inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        bodyMedium: _inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        bodySmall: _inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant,
        ),
        labelLarge: _inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: colorScheme.onSurface,
        ),
        labelMedium: _inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: colorScheme.onSurfaceVariant,
        ),
        labelSmall: _inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withAlpha(10)
            : Colors.black.withAlpha(4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIconColor: colorScheme.onSurfaceVariant,
        labelStyle: _inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: _inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant.withAlpha(120),
        ),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF232528) : Colors.white,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_radiusLg)),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1A1C1E) : Colors.white,
        modalBackgroundColor: isDark ? const Color(0xFF1A1C1E) : Colors.white,
        dragHandleColor: colorScheme.onSurfaceVariant.withAlpha(80),
        dragHandleSize: const Size(36, 4),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
        elevation: 2,
        backgroundColor: isDark ? const Color(0xFF2C2F33) : const Color(0xFF1F1F1F),
        contentTextStyle: _inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusPill)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusPill)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusPill)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusPill)),
        ),
      ),
    );
  }
}
