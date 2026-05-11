import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import '../widgets/vs_logo.dart';
import '../widgets/onboarding_illustrations.dart';

// ─────────────────────────────────────────────────────────────
// Onboarding Screen — full-screen immersive slides
// ─────────────────────────────────────────────────────────────

class _SlideData {
  const _SlideData({
    required this.tag,
    required this.headline,
    required this.headlineAccent,
    required this.body,
    required this.gradientColors,
    required this.accentColor,
    required this.illustration,
    required this.stat,
    required this.statLabel,
  });
  final String tag;
  final String headline;
  final String headlineAccent;
  final String body;
  final List<Color> gradientColors;
  final Color accentColor;
  final Widget illustration;
  final String stat;
  final String statLabel;
}

final List<_SlideData> _slides = [
  _SlideData(
    tag: 'COMMUNITY HEALTH',
    headline: 'Built for\n',
    headlineAccent: 'Field Workers',
    body:
        'Designed for CHWs conducting vision screenings across Ugandan communities.',
    gradientColors: const [
      Color(0xFF0A3D38),
      Color(0xFF0D9488),
      Color(0xFF14B8A6),
    ],
    accentColor: const Color(0xFF5EEAD4),
    illustration: const ChwIllustration(color: Colors.white),
    stat: 'CHW',
    statLabel: 'Field workflow',
  ),
  _SlideData(
    tag: 'CLINICAL TESTING',
    headline: 'Standardized\n',
    headlineAccent: 'Vision Testing',
    body:
        'Uses the Tumbling E chart, a literacy-independent optotype suited to community screening. Works across age groups.',
    gradientColors: const [
      Color(0xFF0C2A4A),
      Color(0xFF0369A1),
      Color(0xFF0EA5E9),
    ],
    accentColor: const Color(0xFF7DD3FC),
    illustration: const EChartIllustration(color: Colors.white),
    stat: 'Tumbling E',
    statLabel: 'Visual acuity test',
  ),
  _SlideData(
    tag: 'PATIENT CARE',
    headline: 'Track &\n',
    headlineAccent: 'Refer Patients',
    body:
        'Register patients, track test history per eye, generate structured referral documents and follow up on every case.',
    gradientColors: const [
      Color(0xFF064E3B),
      Color(0xFF059669),
      Color(0xFF10B981),
    ],
    accentColor: const Color(0xFF6EE7B7),
    illustration: const PatientCareIllustration(color: Colors.white),
    stat: 'Tracked',
    statLabel: 'Referral follow-up',
  ),
  _SlideData(
    tag: 'DATA & INSIGHTS',
    headline: 'Live\n',
    headlineAccent: 'Analytics',
    body:
        'Review screening totals locally and sync records when the configured workspace is available.',
    gradientColors: const [
      Color(0xFF1E1B4B),
      Color(0xFF4F46E5),
      Color(0xFF818CF8),
    ],
    accentColor: const Color(0xFFC7D2FE),
    illustration: const AnalyticsIllustration(color: Colors.white),
    stat: 'Offline',
    statLabel: 'Sync when ready',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  Timer? _autoTimer;

  // Gradient animation
  late final AnimationController _gradCtrl;
  late final Animation<double> _gradAnim;
  List<Color> _fromColors = _slides[0].gradientColors;
  List<Color> _toColors = _slides[0].gradientColors;

  // Content slide-in
  late final AnimationController _contentCtrl;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentSlide;

  // Button press
  late final AnimationController _btnCtrl;
  late final Animation<double> _btnScale;

  // Floating particles
  late final AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();

    _gradCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _gradAnim = CurvedAnimation(parent: _gradCtrl, curve: Curves.easeInOut);

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic),
        );
    _contentCtrl.forward();

    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _btnScale = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _startAutoAdvance();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageCtrl.dispose();
    _gradCtrl.dispose();
    _contentCtrl.dispose();
    _btnCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  void _startAutoAdvance() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _nextSlide();
    });
  }

  void _goToLogin() {
    _autoTimer?.cancel();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _nextSlide() {
    if (_currentPage < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  void _onPageChanged(int index) {
    _fromColors = _slides[_currentPage].gradientColors;
    _toColors = _slides[index].gradientColors;
    _gradCtrl.forward(from: 0);
    setState(() => _currentPage = index);
    _contentCtrl.forward(from: 0);
    _startAutoAdvance();
  }

  List<Color> _lerpColors(double t) => [
    Color.lerp(_fromColors[0], _toColors[0], t)!,
    Color.lerp(_fromColors[1], _toColors[1], t)!,
    Color.lerp(_fromColors[2], _toColors[2], t)!,
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _gradAnim,
        builder: (_, child) {
          final colors = _lerpColors(_gradAnim.value);
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            // ── Floating particles background ──
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ParticlePainter(
                    progress: _particleCtrl.value,
                    color: slide.accentColor,
                  ),
                ),
              ),
            ),

            // ── Large decorative circles ──
            Positioned(
              top: -size.width * 0.4,
              right: -size.width * 0.3,
              child: Container(
                width: size.width * 0.9,
                height: size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.3,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
              ),
            ),

            // ── Full-screen PageView ──
            PageView.builder(
              controller: _pageCtrl,
              onPageChanged: _onPageChanged,
              itemCount: _slides.length,
              itemBuilder: (_, index) => const SizedBox.shrink(),
            ),

            // ── Content overlay ──
            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Row(
                      children: [
                        // Logo wordmark
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VsPulsingRings(
                              color: Colors.white,
                              size: 52,
                              child: VsLogoAnimated(size: 26),
                            ),
                            const SizedBox(width: 8),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Vision',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Screen',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Skip
                        GestureDetector(
                          onTap: _goToLogin,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              'Skip',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Illustration zone ──
                  Expanded(
                    flex: 52,
                    child: FadeTransition(
                      opacity: _contentOpacity,
                      child: SlideTransition(
                        position: _contentSlide,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: slide.illustration,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Bottom glass card ──
                  FadeTransition(
                    opacity: _contentOpacity,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _contentCtrl,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tag + stat row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: slide.accentColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(
                                      color: slide.accentColor.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    slide.tag,
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: slide.accentColor,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Stat badge
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      slide.stat,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.0,
                                      ),
                                    ),
                                    Text(
                                      slide.statLabel,
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Headline
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.06, 0),
                                        end: Offset.zero,
                                      ).animate(anim),
                                      child: child,
                                    ),
                                  ),
                              child: Align(
                                key: ValueKey(_currentPage),
                                alignment: Alignment.centerLeft,
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: slide.headline,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white.withValues(
                                            alpha: 0.75,
                                          ),
                                          height: 1.1,
                                        ),
                                      ),
                                      TextSpan(
                                        text: slide.headlineAccent,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Body
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              child: Text(
                                slide.body,
                                key: ValueKey('body_$_currentPage'),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.70),
                                  height: 1.6,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Dots + button row
                            Row(
                              children: [
                                // Dot indicators
                                Row(
                                  children: List.generate(_slides.length, (i) {
                                    final isActive = i == _currentPage;
                                    return GestureDetector(
                                      onTap: () {
                                        _autoTimer?.cancel();
                                        _pageCtrl.animateToPage(
                                          i,
                                          duration: const Duration(
                                            milliseconds: 400,
                                          ),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                        margin: const EdgeInsets.only(right: 6),
                                        width: isActive ? 24 : 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.white
                                              : Colors.white.withValues(
                                                  alpha: 0.3,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const Spacer(),
                                // Next / Get Started button
                                AnimatedBuilder(
                                  animation: _btnScale,
                                  builder: (_, child) => Transform.scale(
                                    scale: _btnScale.value,
                                    child: child,
                                  ),
                                  child: GestureDetector(
                                    onTapDown: (_) => _btnCtrl.forward(),
                                    onTapUp: (_) {
                                      _btnCtrl.reverse();
                                      _autoTimer?.cancel();
                                      _nextSlide();
                                    },
                                    onTapCancel: () => _btnCtrl.reverse(),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 13,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(99),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.25,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isLast ? 'Get Started' : 'Next',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: _slides[_currentPage]
                                                  .gradientColors[1],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            isLast
                                                ? Icons.rocket_launch_rounded
                                                : Icons.arrow_forward_rounded,
                                            size: 16,
                                            color: _slides[_currentPage]
                                                .gradientColors[1],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Floating particles painter
// ─────────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  static final _rng = Random(42);
  static final _particles = List.generate(
    18,
    (i) => [
      _rng.nextDouble(), // x ratio
      _rng.nextDouble(), // y ratio
      _rng.nextDouble() * 0.5 + 0.3, // speed
      _rng.nextDouble() * 3 + 2, // radius
      _rng.nextDouble(), // phase offset
    ],
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final phase = (progress * p[2] + p[4]) % 1.0;
      final x = p[0] * size.width;
      final y =
          (p[1] * size.height - phase * size.height * 0.4 + size.height) %
          size.height;
      final opacity = (sin(phase * pi) * 0.25).clamp(0.0, 0.25);
      canvas.drawCircle(
        Offset(x, y),
        p[3],
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress || old.color != color;
}
