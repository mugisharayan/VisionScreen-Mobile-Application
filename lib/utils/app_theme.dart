import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screen_utils.dart';

// ─────────────────────────────────────────────────────────────
// VisionScreen Design System — "Clinical Teal"
// Single source of truth for all colors, typography, and theme.
// ─────────────────────────────────────────────────────────────

class VsColors {
  VsColors._();

  // ── Brand ──────────────────────────────────────────────────
  static const brand      = Color(0xFF0D9488); // Teal 600 — primary
  static const brandDark  = Color(0xFF0F766E); // Teal 700 — pressed / gradient end
  static const brandDeep  = Color(0xFF134E4A); // Teal 900 — hero backgrounds
  static const brandLight = Color(0xFFCCFBF1); // Teal 100 — tinted chips
  static const brandFaint = Color(0xFFF0FDFA); // Teal 50  — card backgrounds

  // ── Slate (neutral) ────────────────────────────────────────
  static const slate900 = Color(0xFF0F172A);
  static const slate800 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748B);
  static const slate400 = Color(0xFF94A3B8);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate50  = Color(0xFFF8FAFC);

  // ── Semantic ───────────────────────────────────────────────
  static const emerald    = Color(0xFF10B981); // pass
  static const emeraldBg  = Color(0xFFD1FAE5);
  static const amber      = Color(0xFFF59E0B); // pending / refer
  static const amberBg    = Color(0xFFFEF3C7);
  static const rose       = Color(0xFFF43F5E); // urgent / overdue
  static const roseBg     = Color(0xFFFFE4E6);
  static const sky        = Color(0xFF0EA5E9); // info / sync
  static const skyBg      = Color(0xFFE0F2FE);
  static const violet     = Color(0xFF8B5CF6); // training / modules
  static const violetBg   = Color(0xFFEDE9FE);

  // ── Surface ────────────────────────────────────────────────
  static const scaffold = Color(0xFFF8FAFC);
  static const card     = Color(0xFFFFFFFF);
  static const border   = Color(0xFFE2E8F0);
}

// ─────────────────────────────────────────────────────────────
// Typography helpers
// ─────────────────────────────────────────────────────────────
class VsText {
  VsText._();

  // Display — hero numbers, splash title
  static TextStyle display({Color color = VsColors.slate900}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: ScreenUtils.sp(28), fontWeight: FontWeight.w800, color: color, height: 1.1);

  // H1 — screen titles
  static TextStyle h1({Color color = VsColors.slate900}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: ScreenUtils.sp(22), fontWeight: FontWeight.w700, color: color, height: 1.2);

  // H2 — section headers
  static TextStyle h2({Color color = VsColors.slate900}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: ScreenUtils.sp(17), fontWeight: FontWeight.w700, color: color, height: 1.3);

  // H3 — card titles
  static TextStyle h3({Color color = VsColors.slate900}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: ScreenUtils.sp(15), fontWeight: FontWeight.w600, color: color, height: 1.3);

  // Body — main content
  static TextStyle body({Color color = VsColors.slate700}) =>
      GoogleFonts.inter(
        fontSize: ScreenUtils.sp(14), fontWeight: FontWeight.w400, color: color, height: 1.5);

  // Body medium
  static TextStyle bodyMd({Color color = VsColors.slate700}) =>
      GoogleFonts.inter(
        fontSize: ScreenUtils.sp(14), fontWeight: FontWeight.w500, color: color, height: 1.5);

  // Label — metadata, subtitles
  static TextStyle label({Color color = VsColors.slate500}) =>
      GoogleFonts.inter(
        fontSize: ScreenUtils.sp(12), fontWeight: FontWeight.w500, color: color, height: 1.4);

  // Caption — timestamps, hints
  static TextStyle caption({Color color = VsColors.slate400}) =>
      GoogleFonts.inter(
        fontSize: ScreenUtils.sp(11), fontWeight: FontWeight.w400, color: color, height: 1.4);

  // Micro — badges, chips
  static TextStyle micro({Color color = VsColors.slate600}) =>
      GoogleFonts.inter(
        fontSize: ScreenUtils.sp(10), fontWeight: FontWeight.w600, color: color,
        letterSpacing: 0.3);

  // Number — stat display
  static TextStyle number({Color color = VsColors.slate900, double size = 28}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size, fontWeight: FontWeight.w800, color: color, height: 1.0);

  // Button
  static TextStyle button({Color color = Colors.white}) =>
      GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, color: color);
}

// ─────────────────────────────────────────────────────────────
// Theme
// ─────────────────────────────────────────────────────────────
class VsTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: VsColors.brand,
      brightness: Brightness.light,
      primary: VsColors.brand,
      surface: VsColors.scaffold,
    ),
    scaffoldBackgroundColor: VsColors.scaffold,
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: VsColors.scaffold,
      elevation: 0,
      titleTextStyle: VsText.h2(),
      iconTheme: const IconThemeData(color: VsColors.slate900),
    ),
    cardTheme: CardThemeData(
      color: VsColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: VsColors.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: VsColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: VsText.button(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VsColors.slate50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: VsColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: VsColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: VsColors.brand, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: VsText.body(color: VsColors.slate400),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Shared gradient presets
// ─────────────────────────────────────────────────────────────
class VsGradients {
  VsGradients._();

  static const brand = LinearGradient(
    colors: [VsColors.brand, VsColors.brandDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const hero = LinearGradient(
    colors: [VsColors.brandDeep, VsColors.brand],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroSlide1 = LinearGradient(
    colors: [Color(0xFF134E4A), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroSlide2 = LinearGradient(
    colors: [Color(0xFF1E3A5F), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroSlide3 = LinearGradient(
    colors: [Color(0xFF064E3B), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroSlide4 = LinearGradient(
    colors: [Color(0xFF1C1917), Color(0xFF78716C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────
// Shared shadow presets
// ─────────────────────────────────────────────────────────────
class VsShadows {
  VsShadows._();

  static List<BoxShadow> get card => [
    BoxShadow(
      color: VsColors.slate900.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get brandGlow => [
    BoxShadow(
      color: VsColors.brand.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get fab => [
    BoxShadow(
      color: VsColors.brand.withValues(alpha: 0.35),
      blurRadius: 24,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
