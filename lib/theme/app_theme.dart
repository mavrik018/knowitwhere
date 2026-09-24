import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    // iOS Human Interface Guidelines sizes at the default text setting,
    // scaled from the 411×914 design with .sp. Dynamic Type still applies
    // on top through MediaQuery's text scaler.
    TextStyle? style(
      TextStyle? s,
      double size,
      FontWeight weight, {
      double? height,
      double letterSpacing = 0,
    }) => s?.copyWith(
      fontSize: size.sp,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
    final text = t.copyWith(
      // Title 1 (28): "Good morning.", item name on the detail screen.
      headlineLarge: style(
        t.headlineLarge,
        28,
        FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.6,
      ),
      headlineMedium: style(
        t.headlineMedium,
        28,
        FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.6,
      ),
      // Title 3 (20): "What are you looking for?".
      headlineSmall: style(
        t.headlineSmall,
        20,
        FontWeight.w500,
        height: 1.2,
        letterSpacing: -0.3,
      )?.copyWith(color: scheme.onSurfaceVariant),
      // Title 3 (20): screen titles, location headers, empty-state titles.
      titleLarge: style(t.titleLarge, 20, FontWeight.w700, letterSpacing: -0.3),
      // Headline (17 semibold): item names.
      titleMedium: style(
        t.titleMedium,
        17,
        FontWeight.w600,
        letterSpacing: -0.2,
      ),
      // Subhead (15): tabs.
      titleSmall: style(t.titleSmall, 15, FontWeight.w500),
      // Body (17), Subhead (15), Footnote (13).
      bodyLarge: style(t.bodyLarge, 17, FontWeight.w400, height: 1.35),
      bodyMedium: style(t.bodyMedium, 15, FontWeight.w400, height: 1.3),
      bodySmall: style(t.bodySmall, 13, FontWeight.w400, height: 1.3),
      // Buttons: Headline (17 semibold).
      labelLarge: style(t.labelLarge, 17, FontWeight.w600),
      // Caption 1 (12): eyebrows and section chips.
      labelMedium: style(
        t.labelMedium,
        12,
        FontWeight.w700,
        letterSpacing: 0.8,
      ),
      // Caption 2 (11): the smallest text allowed.
      labelSmall: style(t.labelSmall, 11, FontWeight.w500),
    );
    final radius = BorderRadius.circular(16.r);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      iconTheme: base.iconTheme.copyWith(size: 22.r),
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 52.h,
        iconTheme: IconThemeData(size: 22.r, color: scheme.onSurface),
        actionsIconTheme: IconThemeData(size: 22.r, color: scheme.onSurface),
        titleTextStyle: text.titleMedium?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.field,
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        prefixIconConstraints: BoxConstraints(minWidth: 44.w),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.orange, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
        sizeConstraints: BoxConstraints.tightFor(width: 56.r, height: 56.r),
        iconSize: 28.r,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          minimumSize: Size.fromHeight(50.h),
          textStyle: text.labelLarge,
          iconSize: 20.r,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: Size(0, 44.h),
          textStyle: text.labelLarge,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.accentText,
          textStyle: text.labelLarge?.copyWith(fontSize: 15.sp),
          iconSize: 18.r,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        actionTextColor: AppColors.orange,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
        contentTextStyle: text.bodyLarge?.copyWith(color: scheme.onSurface),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.orange,
      ),
    );
  }
}
