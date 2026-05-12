import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────
// VisionScreen Design System
//
// Single source of truth. Five type sizes, four palette roles,
// six spacing values. Resist adding more.
// ─────────────────────────────────────────────────────────────

class VsColors {
  VsColors._();

  // ── Brand (primary actions only) ───────────────────────────
  static const brand = Color(0xFF0D9488); // Teal 600 — primary
  static const brandDark = Color(0xFF0F766E); // Teal 700 — pressed
  static const brandDeep = Color(0xFF134E4A); // Teal 900 — hero / splash
  static const brandLight = Color(0xFFCCFBF1); // Teal 100 — tinted chip bg
  static const brandFaint = Color(0xFFF0FDFA); // Teal 50  — tinted surface

  // ── Slate (neutral chrome) ─────────────────────────────────
  static const slate900 = Color(0xFF0F172A);
  static const slate800 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748B);
  static const slate400 = Color(0xFF94A3B8);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate50 = Color(0xFFF8FAFC);

  // ── Semantic (state, not chrome) ───────────────────────────
  static const emerald = Color(0xFF10B981); // pass
  static const emeraldBg = Color(0xFFD1FAE5);
  static const amber = Color(0xFFF59E0B); // pending
  static const amberBg = Color(0xFFFEF3C7);
  static const rose = Color(0xFFE11D48); // refer / error
  static const roseBg = Color(0xFFFFE4E6);
  static const sky = Color(0xFF0EA5E9); // info / sync
  static const skyBg = Color(0xFFE0F2FE);
  static const violet = Color(0xFF8B5CF6); // optional accent
  static const violetBg = Color(0xFFEDE9FE);

  // ── Surface ────────────────────────────────────────────────
  static const scaffold = Color(0xFFF8FAFC);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);
}

// ─────────────────────────────────────────────────────────────
// Typography — five sizes, period.
// display 32/800   title 22/700   headline 16/600   body 14/400   label 12/500
// ─────────────────────────────────────────────────────────────
class VsText {
  VsText._();

  static TextStyle display({Color color = VsColors.slate900}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.1,
      );

  static TextStyle title({Color color = VsColors.slate900}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      );

  static TextStyle headline({Color color = VsColors.slate900}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  static TextStyle body({
    Color color = VsColors.slate700,
    FontWeight w = FontWeight.w400,
  }) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: w, color: color, height: 1.5);

  static TextStyle label({
    Color color = VsColors.slate500,
    FontWeight w = FontWeight.w500,
  }) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: w, color: color, height: 1.4);

  // Buttons use body weight so they share the body baseline visually.
  static TextStyle button({Color color = Colors.white}) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: color,
  );
}

// ─────────────────────────────────────────────────────────────
// Spacing — six values. No bespoke paddings.
// ─────────────────────────────────────────────────────────────
class VsSpace {
  VsSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

// ─────────────────────────────────────────────────────────────
// Radii
// ─────────────────────────────────────────────────────────────
class VsRadius {
  VsRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

// ─────────────────────────────────────────────────────────────
// Shadows — keep one card shadow, one elevated shadow. That's it.
// ─────────────────────────────────────────────────────────────
class VsShadows {
  VsShadows._();

  static List<BoxShadow> get card => [
    BoxShadow(
      color: VsColors.slate900.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: VsColors.slate900.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

// ─────────────────────────────────────────────────────────────
// Gradients — reserved for brand moments and workflow headers.
// Do not use for buttons, list items, dividers, or dense data rows.
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
}

// ─────────────────────────────────────────────────────────────
// ThemeData — InputDecoration filled, app uses Material 3.
// ─────────────────────────────────────────────────────────────
class VsTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: VsColors.brand,
      brightness: Brightness.light,
      primary: VsColors.brand,
      surface: VsColors.card,
    ),
    scaffoldBackgroundColor: VsColors.scaffold,
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: VsColors.slate900,
      displayColor: VsColors.slate900,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: VsColors.scaffold,
      foregroundColor: VsColors.slate900,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: VsText.headline(),
      iconTheme: const IconThemeData(color: VsColors.slate900),
    ),
    cardTheme: CardThemeData(
      color: VsColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VsRadius.lg),
        side: const BorderSide(color: VsColors.border),
      ),
    ),
    dividerColor: VsColors.border,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: VsColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: VsSpace.xl,
          vertical: VsSpace.md + 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VsRadius.md),
        ),
        textStyle: VsText.button(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: VsColors.brand,
        textStyle: VsText.button(color: VsColors.brand),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: VsColors.slate700,
        side: const BorderSide(color: VsColors.border, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: VsSpace.xl,
          vertical: VsSpace.md + 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VsRadius.md),
        ),
        textStyle: VsText.button(color: VsColors.slate700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VsColors.slate100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VsRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VsRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VsRadius.md),
        borderSide: const BorderSide(color: VsColors.brand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VsRadius.md),
        borderSide: const BorderSide(color: VsColors.rose, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VsRadius.md),
        borderSide: const BorderSide(color: VsColors.rose, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: VsSpace.lg,
        vertical: VsSpace.md + 2,
      ),
      hintStyle: VsText.body(color: VsColors.slate400),
      labelStyle: VsText.label(color: VsColors.slate500),
      prefixIconColor: VsColors.slate400,
      suffixIconColor: VsColors.slate400,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: VsColors.card,
      selectedColor: VsColors.brand,
      side: const BorderSide(color: VsColors.border),
      labelStyle: VsText.label(color: VsColors.slate700),
      secondaryLabelStyle: VsText.label(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VsRadius.pill),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: VsSpace.md,
        vertical: VsSpace.sm,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: VsColors.slate900,
      contentTextStyle: VsText.body(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VsRadius.md),
      ),
    ),
  );
}
