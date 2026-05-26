import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette — dark (default)
// ─────────────────────────────────────────────────────────────────────────────
class _Dark {
  static const primary          = Color(0xFF6C63FF);
  static const primaryDark      = Color(0xFF4B44CC);
  static const secondary        = Color(0xFFFF6584);
  static const accent           = Color(0xFF43D9AD);
  static const background       = Color(0xFF0F0F1A);
  static const surface          = Color(0xFF1A1A2E);
  static const surfaceElevated  = Color(0xFF242440);
  static const cardBorder       = Color(0xFF2E2E50);
  static const textPrimary      = Color(0xFFF0F0FF);
  static const textSecondary    = Color(0xFF9999BB);
  static const success          = Color(0xFF43D9AD);
  static const error            = Color(0xFFFF6584);
  static const warning          = Color(0xFFFFB347);
}

// ─────────────────────────────────────────────────────────────────────────────
// Palette — light (warm, low-contrast, easy on the eyes)
//
// Design choices:
//   • background: warm off-white (not pure #FFF) — reduces glare
//   • surface: slightly cooler white so cards lift subtly from the bg
//   • textPrimary: dark navy instead of pure black — softer contrast
//   • textSecondary: medium slate — readable without harshness
//   • primary/accent/error: same hues as dark, slightly desaturated so they
//     read well on white without screaming
// ─────────────────────────────────────────────────────────────────────────────
class _Light {
  static const primary          = Color(0xFF5A54D4); // slightly darker for contrast on white
  static const primaryDark      = Color(0xFF3D38A8);
  static const secondary        = Color(0xFFE05575);
  static const accent           = Color(0xFF2BB894);
  static const background       = Color(0xFFF5F4FB); // warm lavender-white, not blinding
  static const surface          = Color(0xFFFFFFFF);
  static const surfaceElevated  = Color(0xFFEEEDF8); // subtle lavender tint
  static const cardBorder       = Color(0xFFDDDBF0);
  static const textPrimary      = Color(0xFF1A1A2E); // dark navy, mirrors dark bg
  static const textSecondary    = Color(0xFF6B6890); // muted purple-grey
  static const success          = Color(0xFF2BB894);
  static const error            = Color(0xFFD04060);
  static const warning          = Color(0xFFD4820A);
}

// ─────────────────────────────────────────────────────────────────────────────
// AppColors — context-aware accessor
//
// Usage in widgets (replaces all existing AppColors.xxx calls unchanged):
//   color: AppColors.of(context).textPrimary
//
// For places that can't access context (rare), the static constants still
// return the dark-mode values as a safe default.
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  const AppColors._({required bool light}) : _light = light;

  final bool _light;

  static AppColors of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AppColors._(light: brightness == Brightness.light);
  }

  Color get primary         => _light ? _Light.primary         : _Dark.primary;
  Color get primaryDark     => _light ? _Light.primaryDark     : _Dark.primaryDark;
  Color get secondary       => _light ? _Light.secondary       : _Dark.secondary;
  Color get accent          => _light ? _Light.accent          : _Dark.accent;
  Color get background      => _light ? _Light.background      : _Dark.background;
  Color get surface         => _light ? _Light.surface         : _Dark.surface;
  Color get surfaceElevated => _light ? _Light.surfaceElevated : _Dark.surfaceElevated;
  Color get cardBorder      => _light ? _Light.cardBorder      : _Dark.cardBorder;
  Color get textPrimary     => _light ? _Light.textPrimary     : _Dark.textPrimary;
  Color get textSecondary   => _light ? _Light.textSecondary   : _Dark.textSecondary;
  Color get success         => _light ? _Light.success         : _Dark.success;
  Color get error           => _light ? _Light.error           : _Dark.error;
  Color get warning         => _light ? _Light.warning         : _Dark.warning;

  // Player colours are the same in both themes — vivid on dark cards,
  // slightly desaturated versions would look muddy on white.
  static const playerColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6584),
    Color(0xFF43D9AD),
    Color(0xFFFFB347),
    Color(0xFF4FC3F7),
    Color(0xFFE040FB),
    Color(0xFF7743FF),
    Color(0xFF66BB6A),
  ];

}

// ── Static dark-mode constants for use without a BuildContext ─────────────
// Use AppColors.of(context) in widgets. Use AppColorsDark.xxx only in
// places that genuinely have no context (e.g. ThemeData definitions).
class AppColorsDark {
  static const primary         = _Dark.primary;
  static const primaryDark     = _Dark.primaryDark;
  static const secondary       = _Dark.secondary;
  static const accent          = _Dark.accent;
  static const background      = _Dark.background;
  static const surface         = _Dark.surface;
  static const surfaceElevated = _Dark.surfaceElevated;
  static const cardBorder      = _Dark.cardBorder;
  static const textPrimary     = _Dark.textPrimary;
  static const textSecondary   = _Dark.textSecondary;
  static const success         = _Dark.success;
  static const error           = _Dark.error;
  static const warning         = _Dark.warning;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme — produces both ThemeData objects
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get dark  => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final p  = isDark ? _Dark.primary         : _Light.primary;
    final bg = isDark ? _Dark.background      : _Light.background;
    final sf = isDark ? _Dark.surface         : _Light.surface;
    final se = isDark ? _Dark.surfaceElevated : _Light.surfaceElevated;
    final cb = isDark ? _Dark.cardBorder      : _Light.cardBorder;
    final tp = isDark ? _Dark.textPrimary     : _Light.textPrimary;
    final ts = isDark ? _Dark.textSecondary   : _Light.textSecondary;
    final er = isDark ? _Dark.error           : _Light.error;

    const fontFamily = 'Outfit';
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final textTheme = base.textTheme.apply(
      bodyColor: tp,
      displayColor: tp,
      fontFamily: fontFamily,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p,
        onPrimary: Colors.white,
        secondary: isDark ? _Dark.secondary : _Light.secondary,
        onSecondary: Colors.white,
        error: er,
        onError: Colors.white,
        surface: sf,
        onSurface: tp,
        surfaceContainerLowest: bg,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: tp,
        ),
        iconTheme: IconThemeData(color: tp),
      ),
      cardTheme: CardThemeData(
        color: sf,
        elevation: isDark ? 0 : 1,
        shadowColor: isDark ? Colors.transparent : Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cb),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: se,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cb),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cb),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p, width: 2),
        ),
        labelStyle: TextStyle(color: ts),
        hintStyle: TextStyle(color: ts),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: se,
        selectedColor: p.withValues(alpha: 0.2),
        labelStyle: TextStyle(color: tp),
        side: BorderSide(color: cb),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(color: cb, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: se,
        contentTextStyle: TextStyle(fontFamily: fontFamily, color: tp),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
