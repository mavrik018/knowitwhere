import 'package:flutter/material.dart';

/// Warm cream / ink / orange palette, tuned to the squirrel mascot.
abstract final class AppColors {
  static const cream = Color(0xFFFBF8F2);
  static const field = Color(0xFFF3EFE7);
  static const chip = Color(0xFFEFEAE1);
  static const line = Color(0xFFE7E1D6);
  static const surface = Colors.white;
  static const ink = Color(0xFF1F1B18);
  static const muted = Color(0xFF78726B);

  /// Fills: buttons, FAB, pins, icons. Pair with white *bold* text only.
  static const orange = Color(0xFFF4632A);

  /// Orange for small text on light backgrounds (meets 4.5:1 contrast).
  static const orangeInk = Color(0xFFB4430F);
  static const orangeSoft = Color(0xFFFDE9DF);

  static const sage = Color(0xFFDFE9E1);
  static const sageInk = Color(0xFF2F5A3F);
  static const danger = Color(0xFFB3261E);

  static const night = Color(0xFF1F1B18);
  static const nightCard = Color(0xFF2A2622);
  static const nightField = Color(0xFF34302B);
  static const nightMuted = Color(0xFFB7AFA5);
}

/// Extra tokens Material's ColorScheme has no slot for.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.field,
    required this.chip,
    required this.accentText,
    required this.accentSoft,
    required this.tip,
    required this.tipText,
    required this.photoPlaceholder,
  });

  final Color field;
  final Color chip;

  /// Orange for text, with enough contrast on the page background.
  final Color accentText;
  final Color accentSoft;
  final Color tip;
  final Color tipText;
  final Color photoPlaceholder;

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  static const light = AppPalette(
    field: AppColors.field,
    chip: AppColors.chip,
    accentText: AppColors.orangeInk,
    accentSoft: AppColors.orangeSoft,
    tip: AppColors.sage,
    tipText: AppColors.sageInk,
    photoPlaceholder: AppColors.orangeSoft,
  );

  static const dark = AppPalette(
    field: AppColors.nightField,
    chip: AppColors.nightField,
    accentText: Color(0xFFFF9A6B),
    accentSoft: Color(0xFF4A2F22),
    tip: Color(0xFF26332A),
    tipText: Color(0xFFB9D7C2),
    photoPlaceholder: Color(0xFF3A2C24),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) => t < 0.5 ? this : other!;
}

abstract final class AppTheme {
  static ThemeData light() => _build(
    ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.orange,
      onPrimary: Colors.white,
      secondary: AppColors.ink,
      onSecondary: Colors.white,
      surface: AppColors.cream,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerHighest: AppColors.field,
      outlineVariant: AppColors.line,
      error: AppColors.danger,
    ),
    AppPalette.light,
  );

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.orange,
      onPrimary: Colors.white,
      secondary: AppColors.cream,
      onSecondary: AppColors.ink,
      surface: AppColors.night,
      onSurface: AppColors.cream,
      onSurfaceVariant: AppColors.nightMuted,
      surfaceContainerLowest: AppColors.nightCard,
      surfaceContainerHighest: AppColors.nightField,
      outlineVariant: const Color(0xFF3F3A34),
    ),
    AppPalette.dark,
  );

  static ThemeData _build(ColorScheme scheme, AppPalette palette) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final t = base.textTheme;
    final text = t.copyWith(
      // "Good morning."
      headlineLarge: t.headlineLarge?.copyWith(
        fontSize: 34,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      // "What are you looking for?"
      headlineSmall: t.headlineSmall?.copyWith(
        fontSize: 26,
        height: 1.15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.8,
        color: scheme.onSurfaceVariant,
      ),
      headlineMedium: t.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      titleLarge: t.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleMedium: t.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      // Eyebrows and section chips.
      labelMedium: t.labelMedium?.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
      ),
    );
    final radius = BorderRadius.circular(18);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.field,
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.orange,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.orange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        prefixIconColor: scheme.onSurfaceVariant.withValues(alpha: 0.8),
        suffixIconColor: scheme.onSurfaceVariant.withValues(alpha: 0.65),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        sizeConstraints: const BoxConstraints.tightFor(width: 64, height: 64),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          textStyle: text.labelLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: palette.accentText),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        actionTextColor: AppColors.orange,
        contentTextStyle: const TextStyle(
          color: Color(0xFFFBF8F2),
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x33FFFFFF), width: 0.8),
        ),
        elevation: 6,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.orange,
      ),
    );
  }
}
