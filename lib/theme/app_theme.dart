import 'package:flutter/material.dart';

/// Cream / charcoal / green direction (SRS Phase 1.2).
abstract final class AppColors {
  static const cream = Color(0xFFF6F1E7);
  static const creamDeep = Color(0xFFECE4D4);
  static const charcoal = Color(0xFF2A2A2A);
  static const charcoalSoft = Color(0xFF5C5A55);
  static const green = Color(0xFF3E7B57);
  static const greenLight = Color(0xFF8CC3A1);
  static const danger = Color(0xFFB3261E);

  static const night = Color(0xFF1C1C1B);
  static const nightCard = Color(0xFF282826);
}

abstract final class AppTheme {
  static ThemeData light() => _build(
    ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.green,
      onPrimary: Colors.white,
      surface: AppColors.cream,
      onSurface: AppColors.charcoal,
      onSurfaceVariant: AppColors.charcoalSoft,
      surfaceContainerLowest: Colors.white,
      surfaceContainerHighest: AppColors.creamDeep,
      error: AppColors.danger,
    ),
  );

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.greenLight,
      onPrimary: AppColors.charcoal,
      surface: AppColors.night,
      onSurface: AppColors.cream,
      surfaceContainerLowest: AppColors.nightCard,
      surfaceContainerHighest: const Color(0xFF33322F),
    ),
  );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
    final radius = BorderRadius.circular(16);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
