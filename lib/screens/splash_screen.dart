import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../widgets/vs_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minimumVisible = Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final stopwatch = Stopwatch()..start();
    final prefs = await SharedPreferences.getInstance();
    final sessionEmail = prefs.getString(AppStrings.prefChwEmail) ?? '';
    final targetRoute = sessionEmail.isNotEmpty ? '/home' : '/onboarding';

    final remaining = _minimumVisible - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: VsColors.brandDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: VsGradients.hero),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Center(
                      child: VsLogo(size: 68, showRing: false),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'VisionScreen',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Community vision screening',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.16),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AppColors — kept for backward compatibility with other screens
// that still import from splash_screen.dart
// ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const Color ink = Color(0xFF04091A);
  static const Color ink2 = Color(0xFF0B1530);
  static const Color ink3 = Color(0xFF162040);
  static const Color teal = Color(0xFF0D9488);
  static const Color teal2 = Color(0xFF14B8A6);
  static const Color teal3 = Color(0xFF5EEAD4);
  static const Color sky = Color(0xFF38BDF8);

  // Updated: use teal instead of lime-green
  static const Color green = VsColors.brand;
  static const Color greenDark = VsColors.brandDark;
  static const Color greenDeep = VsColors.brandDeep;
  static const Color greenHero = VsColors.brandFaint;
  static const Color greenHero2 = VsColors.brandLight;
  static const Color greenForgot = VsColors.brandDark;

  static const Color authBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color cardShadow = Color(0x200D9488);
}
