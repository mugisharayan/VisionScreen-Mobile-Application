import 'package:flutter/services.dart';

/// Centralized haptic feedback helpers.
/// Call these on tap/press events for tactile response.
class VsHaptics {
  VsHaptics._();

  /// Light tap — nav items, filter chips, toggles
  static void light() {
    try { HapticFeedback.lightImpact(); } catch (_) {}
  }

  /// Medium tap — action buttons, card taps
  static void medium() {
    try { HapticFeedback.mediumImpact(); } catch (_) {}
  }

  /// Heavy — destructive actions, FAB press
  static void heavy() {
    try { HapticFeedback.heavyImpact(); } catch (_) {}
  }

  /// Selection click — filter chips, radio buttons
  static void selection() {
    try { HapticFeedback.selectionClick(); } catch (_) {}
  }
}
