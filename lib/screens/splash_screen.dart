import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../widgets/vs_logo.dart';

// ─────────────────────────────────────────────────────────────
// Splash Screen — full-screen teal hero, new Sight Mark logo,
// animated pulsing rings, progress bar, credential badges.
// ─────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Entry animation ──────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryOpacity;
  late final Animation<Offset>   _entrySlide;
  late final Animation<double>   _logoScale;

  // ── Progress bar ─────────────────────────────────────────
  late final AnimationController _loadCtrl;
  late final Animation<double>   _loadProgress;

  // ── Badge stagger ────────────────────────────────────────
  late final AnimationController _badgeCtrl;
  late final List<Animation<double>> _badgeOpacity;

  // ── Tagline shimmer ──────────────────────────────────────
  late final AnimationController _shimmerCtrl;
  late final Animation<double>   _shimmerAnim;

  int _msgIndex = 0;
  static const _messages = [
    'Preparing your workspace...',
    'Loading patient records...',
    'Syncing health data...',
    'Almost ready...',
  ];

  @override
  void initState() {
    super.initState();

    // Entry
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _entryOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _entrySlide = Tween<Offset>(
            begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.2, 1.0, curve: Curves.elasticOut)));

    // Progress
    _loadCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3400));
    _loadProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _loadCtrl, curve: Curves.easeInOut));

    // Badge stagger
    _badgeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _badgeOpacity = List.generate(3, (i) {
      final start = i * 0.25;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _badgeCtrl,
              curve: Interval(start, end, curve: Curves.easeOut)));
    });

    // Shimmer
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    // Sequence
    Future.delayed(const Duration(milliseconds: 150),
        () { if (mounted) _entryCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 400),
        () { if (mounted) _loadCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 800),
        () { if (mounted) _badgeCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 600), _rotateMessages);

    // Navigate
    Future.delayed(const Duration(milliseconds: 4000), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final remembered = prefs.getBool('remember_me') ?? false;
      final email = prefs.getString('remembered_email') ?? '';
      if (remembered && email.isNotEmpty) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      } else {
        if (mounted) Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    });
  }

  void _rotateMessages() {
    if (!mounted) return;
    setState(() => _msgIndex = (_msgIndex + 1) % _messages.length);
    Future.delayed(const Duration(milliseconds: 900), _rotateMessages);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _loadCtrl.dispose();
    _badgeCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: VsColors.brandDeep,
      body: Stack(
        children: [
          // ── Full-screen teal gradient background ──────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: VsGradients.hero),
            ),
          ),

          // ── Dot pattern overlay ───────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _DotPatternPainter()),
          ),

          // ── Decorative arc top-right ──────────────────────
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.3,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06), width: 1),
              ),
            ),
          ),
          Positioned(
            top: -size.width * 0.15,
            right: -size.width * 0.15,
            child: Container(
              width: size.width * 0.55,
              height: size.width * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08), width: 1),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Logo zone (top 60%) ──
                Expanded(
                  flex: 60,
                  child: FadeTransition(
                    opacity: _entryOpacity,
                    child: SlideTransition(
                      position: _entrySlide,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Pulsing rings + animated logo
                          VsPulsingRings(
                            color: Colors.white,
                            size: 320,
                            child: AnimatedBuilder(
                              animation: _logoScale,
                              builder: (_, __) => Transform.scale(
                                scale: _logoScale.value,
                                child: VsLogoAnimated(size: 180),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // App name — "Vision" white, "Screen" black
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Vision',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Screen',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Precision Vision · Community Care',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bottom zone (40%) ──
                Expanded(
                  flex: 40,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Credential badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _badge(0, Icons.verified_outlined, 'WHO'),
                            const SizedBox(width: 10),
                            _badge(1, Icons.local_hospital_outlined, 'Uganda MOH'),
                            const SizedBox(width: 10),
                            _badge(2, Icons.lock_outline_rounded, 'AES-256'),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Progress bar
                        AnimatedBuilder(
                          animation: _loadProgress,
                          builder: (_, __) => Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: Container(
                                  height: 3,
                                  color: Colors.white.withValues(alpha: 0.15),
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: _loadProgress.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(99),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withValues(alpha: 0.5),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.3),
                                      end: Offset.zero,
                                    ).animate(anim),
                                    child: child,
                                  ),
                                ),
                                child: Text(
                                  _messages[_msgIndex],
                                  key: ValueKey(_msgIndex),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '© 2025 VisionScreen',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                'v1.0.0',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(int index, IconData icon, String label) {
    return FadeTransition(
      opacity: _badgeOpacity[index],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.85)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dot pattern painter
// ─────────────────────────────────────────────────────────────
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// AppColors — kept for backward compatibility with other screens
// that still import from splash_screen.dart
// ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const Color ink        = Color(0xFF04091A);
  static const Color ink2       = Color(0xFF0B1530);
  static const Color ink3       = Color(0xFF162040);
  static const Color teal       = Color(0xFF0D9488);
  static const Color teal2      = Color(0xFF14B8A6);
  static const Color teal3      = Color(0xFF5EEAD4);
  static const Color sky        = Color(0xFF38BDF8);

  // Updated: use teal instead of lime-green
  static const Color green      = VsColors.brand;
  static const Color greenDark  = VsColors.brandDark;
  static const Color greenDeep  = VsColors.brandDeep;
  static const Color greenHero  = VsColors.brandFaint;
  static const Color greenHero2 = VsColors.brandLight;
  static const Color greenForgot = VsColors.brandDark;

  static const Color authBg     = Color(0xFFFFFFFF);
  static const Color textDark   = Color(0xFF0F172A);
  static const Color textMuted  = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color cardShadow  = Color(0x200D9488);
}

