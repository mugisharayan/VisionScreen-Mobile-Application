import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../utils/app_theme.dart';
import '../widgets/vs_logo.dart';
import '../widgets/onboarding_illustrations.dart';

// ─────────────────────────────────────────────────────────────
// Onboarding Screen
// 4 slides, each with a unique gradient + custom illustration.
// Diagonal clipper, animated dots, teal pill button.
// ─────────────────────────────────────────────────────────────

class _SlideData {
  const _SlideData({
    required this.headline,
    required this.headlineAccent,
    required this.body,
    required this.gradient,
    required this.illustration,
  });
  final String headline;
  final String headlineAccent;
  final String body;
  final LinearGradient gradient;
  final Widget illustration;
}

final List<_SlideData> _slides = [
  _SlideData(
    headline: 'Community ',
    headlineAccent: 'Health Workers',
    body: 'Designed for field-based CHWs conducting vision screenings in Ugandan communities. No specialist training required.',
    gradient: VsGradients.heroSlide1,
    illustration: const ChwIllustration(color: Colors.white),
  ),
  _SlideData(
    headline: 'Visual ',
    headlineAccent: 'Acuity Testing',
    body: 'Uses the clinically validated Tumbling E chart — the literacy-independent optotype recommended for community settings. Works for all ages.',
    gradient: VsGradients.heroSlide2,
    illustration: const EChartIllustration(color: Colors.white),
  ),
  _SlideData(
    headline: 'Patient ',
    headlineAccent: 'Care & Referrals',
    body: 'Register patients, track test history per eye, generate structured referral documents and follow up on every referred patient.',
    gradient: VsGradients.heroSlide3,
    illustration: const PatientCareIllustration(color: Colors.white),
  ),
  _SlideData(
    headline: 'Data ',
    headlineAccent: 'Analytics',
    body: 'Monitor your screening impact with live analytics. Data syncs automatically when internet is available. Core functions always work offline.',
    gradient: VsGradients.heroSlide4,
    illustration: const AnalyticsIllustration(color: Colors.white),
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

  // Slide content animation
  late final AnimationController _slideCtrl;
  late final Animation<double> _slideOpacity;
  late final Animation<Offset> _slideOffset;

  // Button press animation
  late final AnimationController _btnCtrl;
  late final Animation<double> _btnScale;

  // Gradient transition
  late final AnimationController _gradCtrl;
  late final Animation<double> _gradAnim;
  LinearGradient _fromGrad = VsGradients.heroSlide1;
  LinearGradient _toGrad   = VsGradients.heroSlide1;

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _slideOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideOffset = Tween<Offset>(
            begin: const Offset(0.08, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();

    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _btnScale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));

    _gradCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _gradAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _gradCtrl, curve: Curves.easeInOut));

    _startAutoAdvance();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageCtrl.dispose();
    _slideCtrl.dispose();
    _btnCtrl.dispose();
    _gradCtrl.dispose();
    super.dispose();
  }

  void _startAutoAdvance() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
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
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOut);
    } else {
      _goToLogin();
    }
  }

  void _onPageChanged(int index) {
    // Animate gradient transition
    _fromGrad = _slides[_currentPage].gradient;
    _toGrad   = _slides[index].gradient;
    _gradCtrl.forward(from: 0);

    setState(() => _currentPage = index);
    _slideCtrl.forward(from: 0);
    _startAutoAdvance();
  }

  LinearGradient _lerpGradient(double t) {
    final c1a = _fromGrad.colors[0];
    final c1b = _fromGrad.colors[1];
    final c2a = _toGrad.colors[0];
    final c2b = _toGrad.colors[1];
    return LinearGradient(
      colors: [
        Color.lerp(c1a, c2a, t)!,
        Color.lerp(c1b, c2b, t)!,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Hero zone with illustration ──────────────────
          Expanded(
            flex: 58,
            child: AnimatedBuilder(
              animation: _gradAnim,
              builder: (_, child) => Container(
                decoration: BoxDecoration(
                  gradient: _lerpGradient(_gradAnim.value),
                ),
                child: child,
              ),
              child: Stack(
                children: [
                  // Dot pattern
                  Positioned.fill(
                    child: CustomPaint(painter: _DotPatternPainter()),
                  ),

                  // Decorative circles
                  Positioned(
                    top: -40, right: -40,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20, left: -30,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                            width: 1),
                      ),
                    ),
                  ),

                  // Logo top-left
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: VsLogoWordmark(
                        logoSize: 30,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  // Skip button top-right
                  SafeArea(
                    bottom: false,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 16, 20, 0),
                        child: GestureDetector(
                          onTap: _goToLogin,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3)),
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
                      ),
                    ),
                  ),

                  // Illustration (PageView for swipe)
                  PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: _onPageChanged,
                    itemCount: _slides.length,
                    itemBuilder: (_, index) => _IllustrationSlide(
                      data: _slides[index],
                      slideCtrl: _slideCtrl,
                      slideOpacity: _slideOpacity,
                      slideOffset: _slideOffset,
                      isActive: index == _currentPage,
                    ),
                  ),

                  // Diagonal bottom cut
                  Positioned(
                    bottom: -1,
                    left: 0,
                    right: 0,
                    child: ClipPath(
                      clipper: _DiagonalClipper(),
                      child: Container(height: 48, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Text + controls zone ─────────────────────────
          Expanded(
            flex: 42,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Headline
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
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
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 24, fontWeight: FontWeight.w800),
                          children: [
                            TextSpan(
                              text: _slides[_currentPage].headline,
                              style: TextStyle(color: VsColors.brandDark),
                            ),
                            TextSpan(
                              text: _slides[_currentPage].headlineAccent,
                              style: const TextStyle(color: VsColors.slate900),
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
                      _slides[_currentPage].body,
                      key: ValueKey('body_$_currentPage'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: VsColors.slate500,
                        height: 1.65,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Dot indicators
                  Row(
                    children: [
                      Row(
                        children: List.generate(_slides.length, (i) {
                          final isActive = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.only(right: 6),
                            width: isActive ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? VsColors.brand
                                  : VsColors.slate200,
                              borderRadius: BorderRadius.circular(99),
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 13),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _slides[_currentPage].gradient.colors[1],
                                  _slides[_currentPage].gradient.colors[0],
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: _slides[_currentPage]
                                      .gradient
                                      .colors[1]
                                      .withValues(alpha: 0.4),
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
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_rounded,
                                    size: 16, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Individual illustration slide
// ─────────────────────────────────────────────────────────────
class _IllustrationSlide extends StatelessWidget {
  const _IllustrationSlide({
    required this.data,
    required this.slideCtrl,
    required this.slideOpacity,
    required this.slideOffset,
    required this.isActive,
  });

  final _SlideData data;
  final AnimationController slideCtrl;
  final Animation<double> slideOpacity;
  final Animation<Offset> slideOffset;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: slideOpacity,
      child: SlideTransition(
        position: slideOffset,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 60, bottom: 48),
            child: data.illustration,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Diagonal clipper — more dynamic than wave
// ─────────────────────────────────────────────────────────────
class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_DiagonalClipper old) => false;
}

// ─────────────────────────────────────────────────────────────
// Dot pattern painter
// ─────────────────────────────────────────────────────────────
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    const spacing = 26.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter old) => false;
}
