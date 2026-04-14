import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'splash_screen.dart' show AppColors;

// ─────────────────────────────────────────────────────────────
// Slide data model
// ─────────────────────────────────────────────────────────────
class _SlideData {
  const _SlideData({
    required this.headline,
    required this.headlineAccent,
    required this.body,
    required this.iconBuilder,
    required this.iconBackground,
  });
  final String headline;
  final String headlineAccent;
  final String body;
  final Widget Function() iconBuilder;
  final Color iconBackground;
}

final List<_SlideData> _slides = [
  _SlideData(
    iconBackground: const Color(0x1A0D9488),
    headline: 'Community\n',
    headlineAccent: 'Health Workers',
    body:
        'Designed for field-based Community Health Workers conducting vision screenings in Ugandan communities. No specialist training required.',
    iconBuilder: () => const _CommunityIcon(),
  ),
  _SlideData(
    iconBackground: const Color(0x1A0D9488),
    headline: 'Tumbling E\n',
    headlineAccent: 'Vision Testing',
    body:
        'Uses the clinically validated Tumbling E chart, the literacy-independent optotype recommended for community settings. Works for children, adults and the elderly.',
    iconBuilder: () => const _TumblingEIcon(),
  ),
  _SlideData(
    iconBackground: const Color(0x1AF59E0B),
    headline: 'Patient\n',
    headlineAccent: 'Care',
    body:
        'Register patients, track test history per eye, generate structured referral documents and follow up on every referred patient. All data stored locally offline.',
    iconBuilder: () => const _PatientCareIcon(),
  ),
  _SlideData(
    iconBackground: const Color(0x1AEF4444),
    headline: 'Data\n',
    headlineAccent: 'Tracking',
    body:
        'Monitor your screening impact with live analytics. Data syncs automatically to MongoDB Atlas when internet is available. Core functions always work offline.',
    iconBuilder: () => const _DataTrackingIcon(),
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

  // Per-slide entry animation
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
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _goToLogin() {
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

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _slideCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          // ── Grid background ──
          const Positioned.fill(child: _OnboardingGrid()),

          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                // ── Slides area ──
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

                // ── Footer: dots + buttons ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dot indicators
                      _DotIndicator(
                        count: _slides.length,
                        current: _currentPage,
                      ),
                      const SizedBox(height: 18),

                      // Next / Get Started button
                      _PrimaryButton(
                        label: isLast ? 'Get Started' : 'Next',
                        onTap: _nextSlide,
                      ),
                      const SizedBox(height: 10),

                      // Skip button
                      _SecondaryButton(
                        label: 'Skip',
                        onTap: _goToLogin,
                      ),
                    ],
                  ),
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
// Individual slide content
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
    return AnimatedBuilder(
      animation: slideCtrl,
      builder: (_, child) => FadeTransition(
        opacity: slideOpacity,
        child: SlideTransition(
          position: slideOffset,
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 50, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Logo row ──
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.teal, AppColors.teal2],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(18, 18),
                      painter: _LogoEyePainter(),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 19,
                      color: Colors.white,
                    ),
                    children: const [
                      TextSpan(text: 'Vision'),
                      TextSpan(
                        text: 'Screen',
                        style: TextStyle(color: AppColors.teal3),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 44),

            // ── Illustration box ──
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: data.iconBackground,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
              child: Center(child: data.iconBuilder()),
            ),

            const SizedBox(height: 24),

            // ── Headline ──
            RichText(
              text: TextSpan(
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 32,
                  color: Colors.white,
                  height: 1.2,
                ),
                children: [
                  TextSpan(text: data.headline),
                  TextSpan(
                    text: data.headlineAccent,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 32,
                      color: AppColors.teal3,
                      fontStyle: FontStyle.italic,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Body text ──
            Expanded(
              child: Text(
                data.body,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: AppColors.teal3.withValues(alpha: 0.65),
                  height: 1.8,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dot indicator row
// ─────────────────────────────────────────────────────────────
class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 5),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.teal3
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Primary button — teal gradient, no arrow
// ─────────────────────────────────────────────────────────────
class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.teal, AppColors.teal2],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              widget.label,
              key: ValueKey(widget.label),
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
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
// Secondary button — white outlined, no arrow
// ─────────────────────────────────────────────────────────────
class _SecondaryButton extends StatefulWidget {
  const _SecondaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Slide 1 custom icon — two people + medical cross
// Painted with CustomPainter to look professional and clean
// ─────────────────────────────────────────────────────────────
class _CommunityIcon extends StatelessWidget {
  const _CommunityIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 40),
      painter: _CommunityIconPainter(),
    );
  }
}

class _CommunityIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final personPaint = Paint()
      ..color = AppColors.teal3
      ..style = PaintingStyle.fill;

    final crossPaint = Paint()
      ..color = AppColors.teal2
      ..style = PaintingStyle.fill;

    // ── Person 1 (left, slightly behind) ──
    // Head
    canvas.drawCircle(Offset(w * 0.30, h * 0.22), w * 0.10,
        personPaint..color = AppColors.teal3.withValues(alpha: 0.55));
    // Body
    final body1 = Path()
      ..moveTo(w * 0.10, h * 0.72)
      ..quadraticBezierTo(w * 0.10, h * 0.42, w * 0.30, h * 0.38)
      ..quadraticBezierTo(w * 0.50, h * 0.42, w * 0.50, h * 0.72)
      ..close();
    canvas.drawPath(
        body1, personPaint..color = AppColors.teal3.withValues(alpha: 0.35));

    // ── Person 2 (right, front) ──
    // Head
    canvas.drawCircle(Offset(w * 0.62, h * 0.20), w * 0.11,
        personPaint..color = AppColors.teal3);
    // Body
    final body2 = Path()
      ..moveTo(w * 0.38, h * 0.74)
      ..quadraticBezierTo(w * 0.38, h * 0.40, w * 0.62, h * 0.36)
      ..quadraticBezierTo(w * 0.86, h * 0.40, w * 0.86, h * 0.74)
      ..close();
    canvas.drawPath(body2, personPaint..color = AppColors.teal3);

    // ── Medical cross (top-right corner of icon box) ──
    const crossThick = 3.0;
    final crossCx = w * 0.84;
    final crossCy = h * 0.16;
    const crossArm = 5.0;

    // Horizontal bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(crossCx, crossCy),
          width: crossArm * 2,
          height: crossThick,
        ),
        const Radius.circular(1.5),
      ),
      crossPaint,
    );
    // Vertical bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(crossCx, crossCy),
          width: crossThick,
          height: crossArm * 2,
        ),
        const Radius.circular(1.5),
      ),
      crossPaint,
    );

    // ── Ground line ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.76, w * 0.84, 2.5),
        const Radius.circular(99),
      ),
      Paint()
        ..color = AppColors.teal3.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// Slide 2 — Tumbling E eye chart icon
// Large "E" letter with four directional arrows around it
// ─────────────────────────────────────────────────────────────
class _TumblingEIcon extends StatelessWidget {
  const _TumblingEIcon();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 40),
      painter: _TumblingEIconPainter(),
    );
  }
}

class _TumblingEIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final strokePaint = Paint()
      ..color = AppColors.teal3
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppColors.teal2
      ..style = PaintingStyle.fill;

    final dimPaint = Paint()
      ..color = AppColors.teal3.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // ── Central "E" letter drawn as three horizontal bars + vertical spine ──
    final eLeft   = cx - w * 0.14;
    final eRight  = cx + w * 0.14;
    final eTop    = cy - h * 0.18;
    final eMid    = cy;
    final eBot    = cy + h * 0.18;
    final eMidR   = cx + w * 0.08; // middle bar is shorter

    // Vertical spine
    canvas.drawLine(Offset(eLeft, eTop), Offset(eLeft, eBot), strokePaint);
    // Top bar
    canvas.drawLine(Offset(eLeft, eTop), Offset(eRight, eTop), strokePaint);
    // Middle bar (shorter)
    canvas.drawLine(Offset(eLeft, eMid), Offset(eMidR, eMid), strokePaint);
    // Bottom bar
    canvas.drawLine(Offset(eLeft, eBot), Offset(eRight, eBot), strokePaint);

    // ── Four directional arrows (up, down, left, right) ──
    const arrowLen = 5.0;
    const arrowHead = 3.0;

    void drawArrow(Offset from, Offset to, Offset tipLeft, Offset tipRight) {
      canvas.drawLine(from, to, dimPaint);
      canvas.drawLine(to, tipLeft, dimPaint);
      canvas.drawLine(to, tipRight, dimPaint);
    }

    // Up
    drawArrow(
      Offset(cx, cy - h * 0.36),
      Offset(cx, cy - h * 0.36 - arrowLen),
      Offset(cx - arrowHead, cy - h * 0.36 - arrowLen + arrowHead),
      Offset(cx + arrowHead, cy - h * 0.36 - arrowLen + arrowHead),
    );
    // Down
    drawArrow(
      Offset(cx, cy + h * 0.36),
      Offset(cx, cy + h * 0.36 + arrowLen),
      Offset(cx - arrowHead, cy + h * 0.36 + arrowLen - arrowHead),
      Offset(cx + arrowHead, cy + h * 0.36 + arrowLen - arrowHead),
    );
    // Left
    drawArrow(
      Offset(cx - w * 0.36, cy),
      Offset(cx - w * 0.36 - arrowLen, cy),
      Offset(cx - w * 0.36 - arrowLen + arrowHead, cy - arrowHead),
      Offset(cx - w * 0.36 - arrowLen + arrowHead, cy + arrowHead),
    );
    // Right
    drawArrow(
      Offset(cx + w * 0.36, cy),
      Offset(cx + w * 0.36 + arrowLen, cy),
      Offset(cx + w * 0.36 + arrowLen - arrowHead, cy - arrowHead),
      Offset(cx + w * 0.36 + arrowLen - arrowHead, cy + arrowHead),
    );

    // ── Small teal dot at centre ──
    canvas.drawCircle(Offset(cx, cy), 1.8, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// Slide 3 — Patient care icon
// Person silhouette + heart + clipboard lines
// ─────────────────────────────────────────────────────────────
class _PatientCareIcon extends StatelessWidget {
  const _PatientCareIcon();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 40),
      painter: _PatientCareIconPainter(),
    );
  }
}

class _PatientCareIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final tealFill = Paint()
      ..color = AppColors.teal3
      ..style = PaintingStyle.fill;

    final tealStroke = Paint()
      ..color = AppColors.teal3
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final amberFill = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;

    // ── Person head ──
    canvas.drawCircle(
      Offset(w * 0.32, h * 0.20),
      w * 0.10,
      tealFill..color = AppColors.teal3,
    );

    // ── Person body ──
    final body = Path()
      ..moveTo(w * 0.12, h * 0.70)
      ..quadraticBezierTo(w * 0.12, h * 0.40, w * 0.32, h * 0.36)
      ..quadraticBezierTo(w * 0.52, h * 0.40, w * 0.52, h * 0.70)
      ..close();
    canvas.drawPath(body, tealFill..color = AppColors.teal3);

    // ── Clipboard (right side) ──
    final clipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.52, h * 0.28, w * 0.40, h * 0.48),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      clipRect,
      Paint()
        ..color = AppColors.teal3.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      clipRect,
      tealStroke..color = AppColors.teal3.withValues(alpha: 0.5),
    );

    // Clipboard lines
    final lineX1 = w * 0.57;
    final lineX2 = w * 0.87;
    for (int i = 0; i < 3; i++) {
      final ly = h * 0.38 + i * h * 0.11;
      canvas.drawLine(
        Offset(lineX1, ly),
        Offset(i == 2 ? lineX1 + (lineX2 - lineX1) * 0.6 : lineX2, ly),
        tealStroke
          ..color = AppColors.teal3.withValues(alpha: 0.5)
          ..strokeWidth = 1.4,
      );
    }

    // ── Heart (amber, overlapping person + clipboard) ──
    final heartCx = w * 0.52;
    final heartCy = h * 0.62;
    const hr = 5.5;
    final heartPath = Path();
    heartPath.moveTo(heartCx, heartCy + hr * 0.6);
    heartPath.cubicTo(
      heartCx - hr * 1.6, heartCy - hr * 0.2,
      heartCx - hr * 1.6, heartCy - hr * 1.2,
      heartCx, heartCy - hr * 0.5,
    );
    heartPath.cubicTo(
      heartCx + hr * 1.6, heartCy - hr * 1.2,
      heartCx + hr * 1.6, heartCy - hr * 0.2,
      heartCx, heartCy + hr * 0.6,
    );
    canvas.drawPath(heartPath, amberFill);

    // ── Ground line ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.74, w * 0.46, 2.2),
        const Radius.circular(99),
      ),
      Paint()
        ..color = AppColors.teal3.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// Slide 4 — Data tracking icon
// Bar chart with upward trend + cloud sync dot
// ─────────────────────────────────────────────────────────────
class _DataTrackingIcon extends StatelessWidget {
  const _DataTrackingIcon();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 40),
      painter: _DataTrackingIconPainter(),
    );
  }
}

class _DataTrackingIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final baseLine = h * 0.76;
    final barWidth = w * 0.12;
    final gap      = w * 0.06;
    final startX   = w * 0.08;

    // Bar heights (ascending trend)
    final heights = [h * 0.22, h * 0.34, h * 0.46, h * 0.58, h * 0.44];
    final colors  = [
      AppColors.teal3.withValues(alpha: 0.35),
      AppColors.teal3.withValues(alpha: 0.50),
      AppColors.teal2,
      AppColors.teal3,
      AppColors.teal3.withValues(alpha: 0.60),
    ];

    // ── Bars ──
    for (int i = 0; i < heights.length; i++) {
      final bx = startX + i * (barWidth + gap);
      final bh = heights[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, baseLine - bh, barWidth, bh),
          const Radius.circular(3),
        ),
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.fill,
      );
    }

    // ── Baseline ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, baseLine, w * 0.88, 2.0),
        const Radius.circular(99),
      ),
      Paint()
        ..color = AppColors.teal3.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );

    // ── Trend line over bars ──
    final trendPaint = Paint()
      ..color = AppColors.teal2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final trendPath = Path();
    for (int i = 0; i < heights.length; i++) {
      final bx = startX + i * (barWidth + gap) + barWidth / 2;
      final by = baseLine - heights[i];
      if (i == 0) {
        trendPath.moveTo(bx, by);
      } else {
        trendPath.lineTo(bx, by);
      }
    }
    canvas.drawPath(trendPath, trendPaint);

    // ── Cloud sync dot (top-right) ──
    final cloudCx = w * 0.84;
    final cloudCy = h * 0.14;

    // Cloud body
    canvas.drawCircle(
      Offset(cloudCx - 3.5, cloudCy + 1),
      4.5,
      Paint()
        ..color = AppColors.teal3.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cloudCx + 2, cloudCy + 1.5),
      3.5,
      Paint()
        ..color = AppColors.teal3.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cloudCx - 7.5, cloudCy + 1, 13, 4),
        const Radius.circular(2),
      ),
      Paint()
        ..color = AppColors.teal3.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill,
    );

    // Sync arrow (down arrow below cloud)
    final arrowPaint = Paint()
      ..color = AppColors.teal2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cloudCx, cloudCy + 6),
      Offset(cloudCx, cloudCy + 10),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(cloudCx, cloudCy + 10),
      Offset(cloudCx - 2.5, cloudCy + 7.5),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(cloudCx, cloudCy + 10),
      Offset(cloudCx + 2.5, cloudCy + 7.5),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// Logo eye painter — used in the top-left brand row
// ─────────────────────────────────────────────────────────────
class _LogoEyePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width * 0.9,
        height: size.height * 0.5,
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(
      Offset(cx, cy), size.width * 0.18,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(
      Offset(cx, cy), size.width * 0.09,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// Subtle grid background for onboarding
// ─────────────────────────────────────────────────────────────
class _OnboardingGrid extends StatelessWidget {
  const _OnboardingGrid();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _OnboardingGridPainter());
}

class _OnboardingGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
