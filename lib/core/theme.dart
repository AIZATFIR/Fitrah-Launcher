import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Focus Clock's Obsidian Bookpaper palette, shared across launcher surfaces.
// ─────────────────────────────────────────────────────────────────────────────
const _seedAmber = Color(0xFFF0C987);

/// Shared Focus Clock palette for the launcher and its supporting screens.
class AppPalette {
  static const bg = Color(0xFF18181F);
  static const card = Color(0xFF23222B);
  static const cardHigh = Color(0xFF2B2933);
  static const accent = Color(0xFFF0C987);
  static const accentDim = Color(0xFFD8B56F);
  static const sand = Color(0xFFE8C89A);
  static const sandDim = Color(0xFFD4956A);

  static const text = Color(0xFFF5EBE6);
  static const textDim = Color(0xFFA69F95);
  static const stroke = Color(0xFF363340);
  static const outline = Color(0xFF555260);
  static const danger = Color(0xFFE5484D);

  static const bookpaperFieldBg = Color(0xFF2B2933);
  static const bookpaperBorder = Color(0xFF403C4B);
  static const bookpaperText = Color(0xFFF4E8D1);
  static const glassSurface = Color(0xF21C1B24);
  static const geminiGlassBg = Color(0xE6201F29);
  static const geminiGlassBorder = Color(0x33F0C987);
  static const geminiGlow = Color(0x40F0C987);

  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;

  static const blackBg = Color(0xFF0C0C0F);
  static const blackCard = Color(0xFF16151A);

  static const lightBg = Color(0xFFF7F3EB);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF2B2823);
  static const lightTextDim = Color(0xFF7A746B);
  static const lightStroke = Color(0xFFE6DFC9);
  static const lightAccent = Color(0xFFD49A35);
}

class GeminiMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Curve springCurve = Curves.easeOutCubic;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve emphasisIn = Curves.fastEaseInToSlowEaseOut;
}

ThemeData buildDarkTheme([String palette = 'sage']) {
  final m3scheme =
      ColorScheme.fromSeed(
        seedColor: _seedAmber,
        brightness: Brightness.dark,
      ).copyWith(
        surface: AppPalette.bg,
        surfaceContainerLowest: AppPalette.blackBg,
        surfaceContainerLow: AppPalette.bg,
        surfaceContainer: AppPalette.card,
        surfaceContainerHigh: AppPalette.cardHigh,
        surfaceContainerHighest: const Color(0xFF34313B),

        primary: AppPalette.accent,
        onPrimary: const Color(0xFF2A2115),
        primaryContainer: const Color(0xFF49391F),
        onPrimaryContainer: const Color(0xFFF4D9AA),

        secondary: AppPalette.textDim,
        onSecondary: const Color(0xFF29262B),
        secondaryContainer: const Color(0xFF403C4B),
        onSecondaryContainer: const Color(0xFFE0D8C8),

        tertiary: AppPalette.sand,
        onTertiary: const Color(0xFF2E1800),
        tertiaryContainer: const Color(0xFF49391F),
        onTertiaryContainer: const Color(0xFFF4D9AA),

        error: AppPalette.danger,
        onError: const Color(0xFF690012),
        errorContainer: const Color(0xFF5C0010),
        onErrorContainer: const Color(0xFFFFB3B0),

        onSurface: AppPalette.text,
        onSurfaceVariant: AppPalette.textDim,
        outline: AppPalette.outline,
        outlineVariant: AppPalette.stroke,

        inverseSurface: AppPalette.lightCard,
        onInverseSurface: AppPalette.lightText,
        inversePrimary: AppPalette.lightAccent,
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: m3scheme,
    brightness: Brightness.dark,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppPalette.bg,

    appBarTheme: AppBarTheme(
      backgroundColor: AppPalette.bg,
      foregroundColor: AppPalette.text,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppPalette.text,
      ),
      centerTitle: false,
    ),

    cardTheme: CardThemeData(
      color: AppPalette.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppPalette.stroke, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppPalette.card,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      height: 64,
      indicatorColor: AppPalette.accent.withValues(alpha: 0.18),
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final sel = states.contains(WidgetState.selected);
        return GoogleFonts.outfit(
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
      filled: true,
      fillColor: AppPalette.bookpaperFieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      hintStyle: const TextStyle(color: AppPalette.textDim, fontSize: 14),
      labelStyle: const TextStyle(color: AppPalette.textDim, fontSize: 13),
    ),

    dividerTheme: const DividerThemeData(
      color: AppPalette.stroke,
      space: 1,
      thickness: 1,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppPalette.cardHigh,
      contentTextStyle: GoogleFonts.outfit(
        color: AppPalette.text,
        fontSize: 13,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppPalette.cardHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppPalette.stroke),
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppPalette.bg,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppPalette.outline,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppPalette.card,
      selectedColor: AppPalette.accent.withValues(alpha: 0.22),
      side: const BorderSide(color: AppPalette.stroke),
      shape: const StadiumBorder(),
      labelStyle: GoogleFonts.outfit(fontSize: 13, color: AppPalette.text),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppPalette.accent,
      linearTrackColor: AppPalette.stroke,
      circularTrackColor: AppPalette.stroke,
    ),

    textTheme: GoogleFonts.outfitTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppPalette.text, displayColor: AppPalette.text),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppPalette.card,
      selectedItemColor: AppPalette.accent,
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
      surface: AppPalette.blackBg,
      surfaceContainerLowest: AppPalette.blackBg,
      surfaceContainerLow: AppPalette.blackBg,
      surfaceContainer: AppPalette.blackCard,
    ),
    appBarTheme: base.appBarTheme.copyWith(backgroundColor: AppPalette.blackBg),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      backgroundColor: AppPalette.blackCard,
    ),
    cardTheme: base.cardTheme.copyWith(color: AppPalette.blackCard),
  );
}

ThemeData buildLightTheme() {
  final m3scheme =
      ColorScheme.fromSeed(
        seedColor: _seedAmber,
        brightness: Brightness.light,
      ).copyWith(
        surface: AppPalette.lightBg,
        onSurface: AppPalette.lightText,
        primary: AppPalette.lightAccent,
        tertiary: AppPalette.lightAccent,
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: m3scheme,
    brightness: Brightness.light,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppPalette.lightBg,
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalette.lightBg,
      foregroundColor: AppPalette.lightText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
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
    textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
      bodyColor: AppPalette.lightText,
      displayColor: AppPalette.lightText,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppPalette.lightCard,
      indicatorColor: AppPalette.lightAccent.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final sel = states.contains(WidgetState.selected);
        return GoogleFonts.outfit(
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
  0xFF7AAFA0,
  0xFFC8A882,
  0xFF9CAAC6,
  0xFFB8C88A,
  0xFFB2A3C4,
  0xFFA8B896,
  0xFFCFA085,
  0xFF8DB8B2,
  0xFFD4B28C,
  0xFFA69C90,
];

const presetColors = <int>[
  0xFF4E9A7A,
  0xFF7FCFAA,
  0xFFD4956A,
  0xFFE8C89A,
  0xFF9CAAC6,
  0xFFB2A3C4,
  0xFFFF8A80,
  0xFF4CAF50,
  0xFF009688,
  0xFF00BCD4,
  0xFF03A9F4,
  0xFF2196F3,
  0xFF3F51B5,
  0xFF673AB7,
  0xFF9C27B0,
  0xFFE91E63,
  0xFF795548,
];

const presetIcons = <String>[
  '🏃',
  '💻',
  '😴',
  '🍽️',
  '📚',
  '🏋️',
  '🎮',
  '🎵',
  '🏠',
  '💆',
  '✍️',
  '🚗',
  '🤝',
  '📞',
  '🧘',
  '🎨',
  '🛒',
  '☕',
  '🧹',
  '🎯',
];
