import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';

class VsToast {
  VsToast._();

  static OverlayEntry? _entry;

  static void hide() {
    _entry?.remove();
    _entry = null;
  }

  static void show(
    BuildContext context, {
    required Widget content,
    Color backgroundColor = VsColors.slate900,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    hide();

    final topInset = MediaQuery.of(context).padding.top + 12;
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: topInset,
        left: 16,
        right: 16,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    _entry = entry;
    Future<void>.delayed(duration, () {
      if (_entry == entry) {
        hide();
      }
    });
  }

  static void showText(
    BuildContext context,
    String message, {
    Color backgroundColor = VsColors.slate900,
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context,
      backgroundColor: backgroundColor,
      duration: duration,
      content: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.4,
        ),
      ),
    );
  }
}
