import 'package:flutter/material.dart';

// ── App Colors ────────────────────────────────────────────────────────────────
// Single source of truth for all colors used across the app.
// Screens should import this instead of defining local _C classes.
class AppColors {
  AppColors._();

  // Brand
  static const teal    = Color(0xFF0D9488);
  static const teal2   = Color(0xFF14B8A6);
  static const teal3   = Color(0xFF5EEAD4);

  // Ink / dark
  static const ink     = Color(0xFF04091A);
  static const ink2    = Color(0xFF0B1530);
  static const dark800 = Color(0xFF1A2A3D);

  // Greys
  static const g100    = Color(0xFFF0F4F7);
  static const g200    = Color(0xFFDDE4EC);
  static const g300    = Color(0xFFC4CFDB);
  static const g400    = Color(0xFF8FA0B4);
  static const g500    = Color(0xFF5E7291);

  // Semantic
  static const green   = Color(0xFF22C55E);
  static const amber   = Color(0xFFF59E0B);
  static const red     = Color(0xFFEF4444);
  static const blue    = Color(0xFF3B82F6);
  static const purple  = Color(0xFF8B5CF6);
  static const indigo  = Color(0xFF6366F1);
  static const yellow  = Color(0xFFEAB308);

  // Backgrounds
  static const scaffold = Color(0xFFF8FAFB);
  static const surface  = Color(0xFFF2F4F7);
}

// ── App Dimensions ────────────────────────────────────────────────────────────
class AppDimens {
  AppDimens._();

  // Bottom navigation
  static const bottomNavHeight      = 82.0;
  static const bottomNavBarHeight   = 62.0;
  static const bottomNavFabSize     = 74.0;
  static const bottomNavFabOffset   = 40.0; // notch radius

  // Border radii
  static const radiusSm  = 8.0;
  static const radiusMd  = 12.0;
  static const radiusLg  = 16.0;
  static const radiusXl  = 20.0;
  static const radiusFull = 99.0;

  // Spacing
  static const spaceSm  = 8.0;
  static const spaceMd  = 16.0;
  static const spaceLg  = 24.0;
  static const spaceXl  = 32.0;
}

// ── App Strings ───────────────────────────────────────────────────────────────
class AppStrings {
  AppStrings._();

  static const appName        = 'VisionScreen';
  static const appVersion     = 'v1.0.0';
  static const appTagline     = 'Made for Community Health Workers · Uganda';

  // Outcomes
  static const outcomePass    = 'pass';
  static const outcomeRefer   = 'refer';
  static const outcomePending = 'pending';

  // Referral statuses
  static const statusPending     = 'pending';
  static const statusNotified    = 'notified';
  static const statusCompleted   = 'completed';
  static const statusRescheduled = 'rescheduled';
  static const statusOverdue     = 'overdue';

  // SharedPreferences keys
  static const prefChwName       = 'chw_name';
  static const prefChwCenter     = 'chw_center';
  static const prefChwDistrict   = 'chw_district';
  static const prefChwEmail      = 'chw_email';
  static const prefChwPhone      = 'chw_phone';
  static const prefChwId         = 'chw_id';
  static const prefChwPhoto      = 'chw_photo';
  static const prefLastLoginTime = 'last_login_time';
  static const prefLastLoginRole = 'last_login_role';
  static const prefRememberMe    = 'remember_me';
  static const prefRememberedEmail = 'remembered_email';
  static const prefBrightnessLock  = 'brightness_lock';
  static const prefEyeOrder        = 'eye_order';
  static const prefHapticFeedback  = 'haptic_feedback';
  static const prefReferralLanguage = 'referral_language';
  static const prefFirstLaunch     = 'first_launch';
}

// ── Pagination ────────────────────────────────────────────────────────────────
class AppPagination {
  AppPagination._();

  static const patientPageSize   = 25;
  static const screeningPageSize = 20;
  static const recentLimit       = 10;
}
