import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// ScreenUtils — makes the app look identical on all phones
//
// Designed against a 390×844 reference screen (standard mid-range).
// All sizes scale proportionally to the actual device width.
//
// Usage:
//   ScreenUtils.init(context)  — call once in the root widget
//   ScreenUtils.w(16)          — scaled width/horizontal value
//   ScreenUtils.h(24)          — scaled height/vertical value
//   ScreenUtils.sp(14)         — scaled font size
//   ScreenUtils.r(12)          — scaled radius/icon size
// ─────────────────────────────────────────────────────────────

class ScreenUtils {
  ScreenUtils._();

  static double _scaleW = 1.0;  // horizontal scale
  static double _scaleH = 1.0;  // vertical scale

  // Reference design dimensions (mid-range Android phone)
  static const double _refWidth  = 390.0;
  static const double _refHeight = 844.0;

  // Clamp scale so extreme phones don't go too big or too small
  // 0.85 min — small phones (320px) don't get too tiny
  // 1.10 max — large Samsung/Tecno phones don't get too big
  static const double _minScale = 0.85;
  static const double _maxScale = 1.10;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _scaleW = (size.width  / _refWidth ).clamp(_minScale, _maxScale);
    _scaleH = (size.height / _refHeight).clamp(_minScale, _maxScale);
  }

  /// Scale a horizontal measurement (padding, width, spacing)
  static double w(double value) => value * _scaleW;

  /// Scale a vertical measurement (padding, height, spacing)
  static double h(double value) => value * _scaleH;

  /// Scale a font size
  static double sp(double value) => value * _scaleW;

  /// Scale a radius, icon size, or square dimension
  static double r(double value) => value * _scaleW;
}
