import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'splash_screen.dart' show AppColors;

// ─────────────────────────────────────────────────────────────
// Slide data model
// ─────────────────────────────────────────────────────────────
class _SlideData {
  const _SlideData({
    required this.headline,
    required this.headlineAccent,
    required this.body,
    required this.imagePath,
    required this.gradientColors,
  });
  final String headline;
  final String headlineAccent;
  final String body;
  final String imagePath;
  final List<Color> gradientColors;
}

final List<_SlideData> _slides = [
  _SlideData(
    headline: 'Community ',
    headlineAccent: 'Health Workers',
    body:
        'Designed for field-based Community Health Workers conducting vision screenings in Ugandan communities. No specialist training required.',
    imagePath: '—Pngtree—male nurse female nurse hospital_7123812.png',
    gradientColors: [AppColors.greenDark, AppColors.green],
  ),
  _SlideData(
    headline: 'Visual ',
    headlineAccent: 'Acuity Testing',
    body:
        'Uses the clinically validated Tumbling E chart, the literacy-independent optotype recommended for community settings. Works for all ages.',
    imagePath: '—Pngtree—visual acuity_7080163.png',
    gradientColors: [AppColors.greenDark, AppColors.green],
  ),
  _SlideData(
    headline: 'Patient ',
    headlineAccent: 'Care & Referrals',
    body:
        'Register patients, track test history per eye, generate structured referral documents and follow up on every referred patient.',
    imagePath: '—Pngtree—medical clipboard with a red_18496671.png',
    gradientColors: [AppColors.greenDark, AppColors.green],
  ),
  _SlideData(
    headline: 'Data ',
    headlineAccent: 'Analytics',
    body:
        'Monitor your screening impact with live analytics. Data syncs automatically when internet is available. Core functions always work offline.',
    imagePath: 'pngwing.com.png',
    gradientColors: [AppColors.greenDark, AppColors.green],
  ),
];

// ─────────────────────────────────────────────────────────────
// Onboarding Screen
// ─────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  Timer? _autoAdvanceTimer;

  late final AnimationController _slideCtrl;
  late final Animation<double> _slideOpacity;
  late final Animation<Offset> _slideOffset;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _slideOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut),
    );
    _slideOffset = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _startAutoAdvance();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _nextSlide();
    });
  }

  void _stopAutoAdvance() => _autoAdvanceTimer?.cancel();

  void _goToLogin() {
    _stopAutoAdvance();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _nextSlide() {
    if (_currentPage < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _manualNext() {
    _stopAutoAdvance();
    _nextSlide();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _slideCtrl.forward(from: 0);
    _startAutoAdvance();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;
    return Scaffold(
      backgroundColor: AppColors.authBg,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: _onPageChanged,
              itemCount: _slides.length,
              itemBuilder: (_, index) => _SlideContent(
                data: _slides[index],
                slideCtrl: _slideCtrl,
                slideOpacity: _slideOpacity,
                slideOffset: _slideOffset,
              ),
            ),
          ),

          // ── Footer ──
          Container(
            color: AppColors.authBg,
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final isActive = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.green
                            : AppColors.borderColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // Next / Get Started button
                _GreenPillBtn(
                  label: isLast ? 'Get Started' : 'Next',
                  onTap: _manualNext,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Individual slide
// ─────────────────────────────────────────────────────────────
class _SlideContent extends StatelessWidget {
  const _SlideContent({
    required this.data,
    required this.slideCtrl,
    required this.slideOpacity,
    required this.slideOffset,
  });

  final _SlideData data;
  final AnimationController slideCtrl;
  final Animation<double> slideOpacity;
  final Animation<Offset> slideOffset;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: slideCtrl,
      builder: (_, child) => FadeTransition(
        opacity: slideOpacity,
        child: SlideTransition(position: slideOffset, child: child),
      ),
      child: Column(
        children: [
          // ── Green hero with image ──
          ClipPath(
            clipper: _OnboardWaveClipper(),
            child: Container(
              width: double.infinity,
              height: size.height * 0.50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: data.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Dot pattern overlay
                  Positioned.fill(
                    child: CustomPaint(painter: _DotPatternPainter()),
                  ),
                  // Logo top-left
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4)),
                            ),
                            child: Center(
                              child: CustomPaint(
                                size: const Size(18, 18),
                                painter: _LogoEyePainter(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.nunito(
                                  fontSize: 18, fontWeight: FontWeight.w900),
                              children: const [
                                TextSpan(
                                    text: 'Vision',
                                    style: TextStyle(color: Colors.white)),
                                TextSpan(
                                    text: 'Screen',
                                    style: TextStyle(color: Colors.black)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Centered image
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 50),
                        child: Image.asset(
                          data.imagePath,
                          height: size.height * 0.30,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_not_supported_outlined,
                            size: 60,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── White text area ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Headline
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.nunito(
                          fontSize: 26, fontWeight: FontWeight.w900),
                      children: [
                        TextSpan(
                          text: data.headline,
                          style: const TextStyle(color: AppColors.greenDark),
                        ),
                        TextSpan(
                          text: data.headlineAccent,
                          style: const TextStyle(color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Body
                  Text(
                    data.body,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      height: 1.7,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
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
// Green pill button
// ─────────────────────────────────────────────────────────────
class _GreenPillBtn extends StatefulWidget {
  const _GreenPillBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_GreenPillBtn> createState() => _GreenPillBtnState();
}

class _GreenPillBtnState extends State<_GreenPillBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.green, AppColors.greenDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              widget.label,
              key: ValueKey(widget.label),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Wave clipper
// ─────────────────────────────────────────────────────────────
class _OnboardWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 45);
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height - 22);
    path.quadraticBezierTo(
        size.width * 0.75, size.height - 45, size.width, size.height - 12);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_OnboardWaveClipper old) => false;
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
        canvas.drawCircle(Offset(x, y), 2.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// Logo eye painter
// ─────────────────────────────────────────────────────────────
class _LogoEyePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width * 0.9,
          height: size.height * 0.5),
      paint,
    );
    canvas.drawCircle(Offset(cx, cy), size.width * 0.18, paint);
    canvas.drawCircle(
        Offset(cx, cy), size.width * 0.09, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
