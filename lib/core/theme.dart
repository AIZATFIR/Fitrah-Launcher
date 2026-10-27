import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// M3 Seed — Sage Green + Warm Sand (Sadar Way of Life Design System)
// ─────────────────────────────────────────────────────────────────────────────
const _seedGreen    = Color(0xFF4E9A7A);
const _seedTertiary = Color(0xFFD4956A);

/// AppPalette — Sage Green + Warm Sand Dark Aesthetic (M3 aligned)
class AppPalette {
  static const bg         = Color(0xFF0F1410);
  static const card       = Color(0xFF1A2018);
  static const cardHigh   = Color(0xFF222B20);
  static const accent     = Color(0xFF7FCFAA); // M3 primary on dark — sage mint
  static const accentDim  = Color(0xFF4E9A7A);
  static const sand       = Color(0xFFE8C89A); // tertiary — warm sand
  static const sandDim    = Color(0xFFD4956A);

  static const text       = Color(0xFFE8F0EB);
  static const textDim    = Color(0xFF8FAF9A);
  static const stroke     = Color(0xFF2E3E30);
  static const outline    = Color(0xFF4A6050);
  static const danger     = Color(0xFFFF8A80);

  // Legacy aliases (keep old names compiling)
  static const bookpaperFieldBg  = Color(0xFF1C2A1E);
  static const bookpaperBorder   = Color(0xFF324535);
  static const bookpaperText     = Color(0xFFD8EAD8);
  static const glassSurface      = Color(0xF21A2018);
  static const geminiGlassBg    = Color(0xE61A2018);
  static const geminiGlassBorder = Color(0x337FCFAA);
  static const geminiGlow        = Color(0x407FCFAA);

  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;

  static const blackBg   = Color(0xFF080D09);
  static const blackCard = Color(0xFF0F1810);

  static const lightBg      = Color(0xFFF3F8F2);
  static const lightCard    = Color(0xFFFFFFFF);
  static const lightText    = Color(0xFF1A2A1C);
  static const lightTextDim = Color(0xFF5A7A60);
  static const lightStroke  = Color(0xFFCBE0CC);
  static const lightAccent  = Color(0xFF2E7D55);
}

class GeminiMotion {
  static const Duration fast   = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow   = Duration(milliseconds: 420);
  static const Curve springCurve = Curves.easeOutCubic;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve emphasisIn  = Curves.fastEaseInToSlowEaseOut;
}

ThemeData buildDarkTheme([String palette = 'sage']) {
  final m3scheme = ColorScheme.fromSeed(
    seedColor: _seedGreen,
    brightness: Brightness.dark,
  ).copyWith(
    surface:                 AppPalette.bg,
    surfaceContainerLowest:  AppPalette.blackBg,
    surfaceContainerLow:     AppPalette.bg,
    surfaceContainer:        AppPalette.card,
    surfaceContainerHigh:    AppPalette.cardHigh,
    surfaceContainerHighest: const Color(0xFF2C3A2A),

    primary:            AppPalette.accent,
    onPrimary:          const Color(0xFF0A2518),
    primaryContainer:   const Color(0xFF1D4535),
    onPrimaryContainer: const Color(0xFFA8E6C8),

    secondary:            const Color(0xFF8FAF9A),
    onSecondary:          const Color(0xFF162820),
    secondaryContainer:   const Color(0xFF243D2A),
    onSecondaryContainer: const Color(0xFFBDD8C6),

    tertiary:            AppPalette.sand,
    onTertiary:          const Color(0xFF2E1800),
    tertiaryContainer:   const Color(0xFF4A2D10),
    onTertiaryContainer: const Color(0xFFF5D8B5),

    error:            AppPalette.danger,
    onError:          const Color(0xFF690012),
    errorContainer:   const Color(0xFF5C0010),
    onErrorContainer: const Color(0xFFFFB3B0),

    onSurface:        AppPalette.text,
    onSurfaceVariant: AppPalette.textDim,
    outline:          AppPalette.outline,
    outlineVariant:   AppPalette.stroke,

    inverseSurface:   AppPalette.lightCard,
    onInverseSurface: AppPalette.lightText,
    inversePrimary:   AppPalette.lightAccent,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: m3scheme,
    brightness: Brightness.dark,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppPalette.bg,

    appBarTheme: AppBarTheme(
      backgroundColor:          AppPalette.bg,
      foregroundColor:          AppPalette.text,
      surfaceTintColor:         Colors.transparent,
      shadowColor:              Colors.transparent,
      elevation:                0,
      scrolledUnderElevation:   1,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppPalette.text,
      ),
      centerTitle: false,
    ),

    cardTheme: CardThemeData(
      color:     AppPalette.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppPalette.stroke, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor:  AppPalette.card,
      surfaceTintColor: Colors.transparent,
      shadowColor:      Colors.transparent,
      elevation:        0,
      height:           64,
      indicatorColor: AppPalette.accent.withValues(alpha: 0.18),
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final sel = states.contains(WidgetState.selected);
        return GoogleFonts.inter(
          fontSize: 11,
          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
          color: sel ? AppPalette.accent : AppPalette.textDim,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final sel = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 22,
          color: sel ? AppPalette.accent : AppPalette.textDim,
        );
      }),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled:          true,
      fillColor:       AppPalette.bookpaperFieldBg,
      contentPadding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.bookpaperBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.bookpaperBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.danger),
      ),
      hintStyle:  const TextStyle(color: AppPalette.textDim, fontSize: 14),
      labelStyle: const TextStyle(color: AppPalette.textDim, fontSize: 13),
    ),

    dividerTheme: const DividerThemeData(
      color: AppPalette.stroke,
      space: 1,
      thickness: 1,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppPalette.cardHigh,
      contentTextStyle: GoogleFonts.inter(color: AppPalette.text, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor:  AppPalette.cardHigh,
      surfaceTintColor: Colors.transparent,
      elevation:        4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppPalette.stroke),
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor:  AppPalette.bg,
      surfaceTintColor: Colors.transparent,
      showDragHandle:   true,
      dragHandleColor:  AppPalette.outline,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppPalette.card,
      selectedColor:   AppPalette.accent.withValues(alpha: 0.22),
      side: const BorderSide(color: AppPalette.stroke),
      shape: const StadiumBorder(),
      labelStyle: GoogleFonts.inter(fontSize: 13, color: AppPalette.text),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color:              AppPalette.accent,
      linearTrackColor:   AppPalette.stroke,
      circularTrackColor: AppPalette.stroke,
    ),

    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor:    AppPalette.text,
      displayColor: AppPalette.text,
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor:     AppPalette.card,
      selectedItemColor:   AppPalette.accent,
      unselectedItemColor: AppPalette.textDim,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

ThemeData buildBlackTheme() {
  final base = buildDarkTheme();
  return base.copyWith(
    scaffoldBackgroundColor: AppPalette.blackBg,
    colorScheme: base.colorScheme.copyWith(
      surface:                AppPalette.blackBg,
      surfaceContainerLowest: AppPalette.blackBg,
      surfaceContainerLow:    AppPalette.blackBg,
      surfaceContainer:       AppPalette.blackCard,
    ),
    appBarTheme:         base.appBarTheme.copyWith(backgroundColor: AppPalette.blackBg),
    navigationBarTheme:  base.navigationBarTheme.copyWith(backgroundColor: AppPalette.blackCard),
    cardTheme:           base.cardTheme.copyWith(color: AppPalette.blackCard),
  );
}

ThemeData buildLightTheme() {
  final m3scheme = ColorScheme.fromSeed(
    seedColor: _seedGreen,
    brightness: Brightness.light,
  ).copyWith(
    surface:   AppPalette.lightBg,
    onSurface: AppPalette.lightText,
    primary:   AppPalette.lightAccent,
    tertiary:  _seedTertiary,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: m3scheme,
    brightness: Brightness.light,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppPalette.lightBg,
    appBarTheme: AppBarTheme(
      backgroundColor:  AppPalette.lightBg,
      foregroundColor:  AppPalette.lightText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppPalette.lightText,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppPalette.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppPalette.lightStroke),
      ),
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor:    AppPalette.lightText,
      displayColor: AppPalette.lightText,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppPalette.lightCard,
      indicatorColor: AppPalette.lightAccent.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final sel = states.contains(WidgetState.selected);
        return GoogleFonts.inter(
          fontSize: 11,
          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
          color: sel ? AppPalette.lightAccent : AppPalette.lightTextDim,
        );
      }),
    ),
  );
}

ThemeData buildFullBookTheme() => buildDarkTheme('sage');

const pastelBookColors = <int>[
  0xFF7AAFA0, 0xFFC8A882, 0xFF9CAAC6, 0xFFB8C88A,
  0xFFB2A3C4, 0xFFA8B896, 0xFFCFA085, 0xFF8DB8B2,
  0xFFD4B28C, 0xFFA69C90,
];

const presetColors = <int>[
  0xFF4E9A7A, 0xFF7FCFAA, 0xFFD4956A, 0xFFE8C89A,
  0xFF9CAAC6, 0xFFB2A3C4, 0xFFFF8A80, 0xFF4CAF50,
  0xFF009688, 0xFF00BCD4, 0xFF03A9F4, 0xFF2196F3,
  0xFF3F51B5, 0xFF673AB7, 0xFF9C27B0, 0xFFE91E63,
  0xFF795548,
];

const presetIcons = <String>[
  '🏃', '💻', '😴', '🍽️', '📚',
  '🏋️', '🎮', '🎵', '🏠', '💆',
  '✍️', '🚗', '🤝', '📞', '🧘',
  '🎨', '🛒', '☕', '🧹', '🎯',
];
