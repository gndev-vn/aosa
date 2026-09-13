import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AppTheme {
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusPill = 9999.0;

  // Modern Zinc Color Palette
  static const darkSurface = Color(0xFF09090B);      // Zinc-950
  static const darkCardSurface = Color(0xFF18181B);  // Zinc-900
  static const darkBorder = Color(0xFF27272A);       // Zinc-800
  static const darkMuted = Color(0xFFA1A1AA);        // Zinc-400
  static const darkDestructive = Color(0xFFEF4444);  // Red-500

  static const lightSurface = Color(0xFFF4F4F5);     // Zinc-100
  static const lightCardSurface = Colors.white;
  static const lightBorder = Color(0xFFE4E4E7);      // Zinc-200
  static const lightMuted = Color(0xFF71717A);       // Zinc-500
  static const lightDestructive = Color(0xFFDC2626); // Red-600

  // Pure Shadcn Surface & Border Helpers
  static Color headerBackground(bool isDark) =>
      isDark ? darkSurface : lightSurface;

  static const _radiusSm = radiusSm;

  static TextStyle titleStyle({Color? color}) {
    return _inter(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      color: color,
    );
  }

  static TextStyle codeStyle({
    Color? color,
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 2.0,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: color,
    );
  }

  static ShadThemeData shadThemeLight({required Color seedColor}) {
    final lightZinc = ShadZincColorScheme.light(
      primary: seedColor,
      background: lightSurface,
      card: lightCardSurface,
      border: lightBorder,
    );
    return ShadThemeData(
      brightness: Brightness.light,
      colorScheme: lightZinc,
      cardTheme: ShadCardTheme(
        backgroundColor: lightCardSurface,
        border: ShadBorder.all(color: lightBorder, width: 1.0),
        radius: BorderRadius.circular(radiusSm),
      ),
      outlineButtonTheme: ShadButtonTheme(
        foregroundColor: lightZinc.foreground,
      ),
      ghostButtonTheme: ShadButtonTheme(
        foregroundColor: lightZinc.foreground,
      ),
      radius: BorderRadius.circular(radiusSm),
    );
  }

  static ShadThemeData shadThemeDark({required Color seedColor}) {
    final darkZinc = ShadZincColorScheme.dark(
      primary: seedColor,
      background: darkSurface,
      card: darkCardSurface,
      border: darkBorder,
    );
    return ShadThemeData(
      brightness: Brightness.dark,
      colorScheme: darkZinc,
      cardTheme: ShadCardTheme(
        backgroundColor: darkCardSurface,
        border: ShadBorder.all(color: darkBorder, width: 1.0),
        radius: BorderRadius.circular(radiusSm),
      ),
      outlineButtonTheme: ShadButtonTheme(
        foregroundColor: darkZinc.foreground,
      ),
      ghostButtonTheme: ShadButtonTheme(
        foregroundColor: darkZinc.foreground,
      ),
      radius: BorderRadius.circular(radiusSm),
    );
  }

  static ThemeData light({required Color seedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      surface: lightSurface,
      brightness: Brightness.light,
    );
    return _buildTheme(colorScheme, Brightness.light);
  }

  static ThemeData dark({required Color seedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: darkSurface,
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
      iconTheme: IconThemeData(
        color: isDark ? const Color(0xFFFAFAFA) : const Color(0xFF09090B),
      ),

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
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
        elevation: 0,
        backgroundColor: isDark ? darkCardSurface : lightCardSurface,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_radiusSm)),
        ),
        elevation: 0,
        backgroundColor: isDark ? darkCardSurface : lightCardSurface,
        modalBackgroundColor: isDark ? darkCardSurface : lightCardSurface,
        dragHandleColor: colorScheme.onSurfaceVariant.withAlpha(80),
        dragHandleSize: const Size(36, 4),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
        elevation: 2,
        backgroundColor: isDark ? darkCardSurface : const Color(0xFF09090B),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusSm)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusSm)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusSm)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusSm)),
        ),
      ),
    );
  }
}
