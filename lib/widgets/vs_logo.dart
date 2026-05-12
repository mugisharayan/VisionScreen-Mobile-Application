import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// VisionScreen Eyeball Logo
//
// Matches the reference image:
//   • Outer dark border ring
//   • Teal iris with radiating fiber lines
//   • Amber/orange inner iris ring
//   • Deep dark pupil with glossy highlight
//
// Adapted to app theme: teal (#0D9488) iris, amber inner ring,
// dark pupil with white highlight.
// ─────────────────────────────────────────────────────────────

class VsLogo extends StatelessWidget {
  const VsLogo({super.key, this.size = 56, this.showRing = true});

  final double size;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _EyeballPainter(showRing: showRing)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Animated logo — iris slowly rotates + pupil dilates
// ─────────────────────────────────────────────────────────────
class VsLogoAnimated extends StatefulWidget {
  const VsLogoAnimated({super.key, this.size = 56});

  final double size;

  @override
  State<VsLogoAnimated> createState() => _VsLogoAnimatedState();
}

class _VsLogoAnimatedState extends State<VsLogoAnimated>
    with TickerProviderStateMixin {
  late final AnimationController _rotateCtrl;
  late final AnimationController _dilateCtrl;
  late final Animation<double> _rotation;
  late final Animation<double> _dilate;

  @override
  void initState() {
    super.initState();

    // Slow iris rotation
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _rotation = Tween<double>(begin: 0, end: 2 * pi).animate(_rotateCtrl);

    // Pupil dilation — slow breathe
    _dilateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _dilate = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _dilateCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _dilateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotation, _dilate]),
      builder: (_, _) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _EyeballPainter(
            irisRotation: _rotation.value,
            pupilScale: _dilate.value,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Core eyeball painter
// ─────────────────────────────────────────────────────────────
class _EyeballPainter extends CustomPainter {
  const _EyeballPainter({
    this.irisRotation = 0,
    this.pupilScale = 1.0,
    this.showRing = true,
  });

  final double irisRotation;
  final double pupilScale;
  final bool showRing;

  // App theme colors
  static const _teal = Color(0xFF0D9488);
  static const _tealLight = Color(0xFF14B8A6);
  static const _tealDark = Color(0xFF0F766E);
  static const _tealDeep = Color(0xFF134E4A);
  static const _amber = Color(0xFFF59E0B);
  static const _amberDark = Color(0xFFD97706);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // ── 1. Outer dark border ring ──────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF0A2A28), const Color(0xFF051A18)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );

    // ── 2. Teal iris (outer) ───────────────────────────────
    final irisR = r * 0.88;
    canvas.drawCircle(
      Offset(cx, cy),
      irisR,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            _tealLight.withValues(alpha: 0.9),
            _teal,
            _tealDark,
            _tealDeep,
          ],
          stops: const [0.0, 0.4, 0.75, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: irisR)),
    );

    // ── 3. Iris fiber lines (radiating) ───────────────────
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(irisRotation);

    final fiberPaint = Paint()
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round;

    final fiberCount = 36;
    for (int i = 0; i < fiberCount; i++) {
      final angle = (i / fiberCount) * 2 * pi;
      final opacity = (i % 3 == 0) ? 0.35 : 0.18;
      fiberPaint.color = Colors.white.withValues(alpha: opacity);

      final innerR = irisR * 0.38;
      final outerR = irisR * 0.96;
      canvas.drawLine(
        Offset(cos(angle) * innerR, sin(angle) * innerR),
        Offset(cos(angle) * outerR, sin(angle) * outerR),
        fiberPaint,
      );
    }

    // Secondary finer fibers
    final fineFiberCount = 72;
    for (int i = 0; i < fineFiberCount; i++) {
      final angle = (i / fineFiberCount) * 2 * pi;
      fiberPaint.color = Colors.white.withValues(alpha: 0.08);
      fiberPaint.strokeWidth = size.width * 0.006;
      final innerR = irisR * 0.45;
      final outerR = irisR * 0.88;
      canvas.drawLine(
        Offset(cos(angle) * innerR, sin(angle) * innerR),
        Offset(cos(angle) * outerR, sin(angle) * outerR),
        fiberPaint,
      );
    }

    canvas.restore();

    // ── 4. Iris texture dots (flecks) ─────────────────────
    final rng = Random(42); // fixed seed for consistent pattern
    final fleckPaint = Paint()
      ..color = _tealDeep.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 20; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = irisR * (0.45 + rng.nextDouble() * 0.45);
      final fx = cx + cos(angle) * dist;
      final fy = cy + sin(angle) * dist;
      canvas.drawCircle(Offset(fx, fy), size.width * 0.012, fleckPaint);
    }

    // ── 5. Amber inner iris ring ───────────────────────────
    final amberR = irisR * 0.42;
    canvas.drawCircle(
      Offset(cx, cy),
      amberR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFBBF24),
            _amber,
            _amberDark,
            const Color(0xFF92400E),
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: amberR)),
    );

    // Amber ring texture lines
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-irisRotation * 0.5); // counter-rotate slightly
    final amberFiberPaint = Paint()
      ..strokeWidth = size.width * 0.008
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * pi;
      amberFiberPaint.color = Colors.white.withValues(alpha: 0.15);
      canvas.drawLine(
        Offset(cos(angle) * amberR * 0.55, sin(angle) * amberR * 0.55),
        Offset(cos(angle) * amberR * 0.95, sin(angle) * amberR * 0.95),
        amberFiberPaint,
      );
    }
    canvas.restore();

    // ── 6. Pupil (dark) ────────────────────────────────────
    final pupilR = amberR * 0.62 * pupilScale;
    canvas.drawCircle(
      Offset(cx, cy),
      pupilR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.2),
          radius: 1.0,
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF0A0A14),
            Colors.black,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: pupilR)),
    );

    // ── 7. Pupil glossy highlights ─────────────────────────
    // Main highlight — top-left
    final h1Paint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.85),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(cx - pupilR * 0.28, cy - pupilR * 0.32),
              radius: pupilR * 0.32,
            ),
          );
    canvas.drawCircle(
      Offset(cx - pupilR * 0.28, cy - pupilR * 0.32),
      pupilR * 0.32,
      h1Paint,
    );

    // Secondary smaller highlight
    canvas.drawCircle(
      Offset(cx + pupilR * 0.18, cy + pupilR * 0.22),
      pupilR * 0.12,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // ── 8. Outer glow ring (optional) ─────────────────────
    if (showRing) {
      canvas.drawCircle(
        Offset(cx, cy),
        r * 0.96,
        Paint()
          ..color = _teal.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.025,
      );
    }
  }

  @override
  bool shouldRepaint(_EyeballPainter old) =>
      old.irisRotation != irisRotation ||
      old.pupilScale != pupilScale ||
      old.showRing != showRing;
}

// ─────────────────────────────────────────────────────────────
// Logo + wordmark combo widget
// ─────────────────────────────────────────────────────────────
class VsLogoWordmark extends StatelessWidget {
  const VsLogoWordmark({
    super.key,
    this.logoSize = 40,
    this.color = Colors.white,
    this.fontSize = 22,
    this.animate = false,
  });

  final double logoSize;
  final Color color;
  final double fontSize;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo in a rounded container
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(logoSize * 0.28),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Center(
            child: animate
                ? VsLogoAnimated(size: logoSize * 0.72)
                : VsLogo(size: logoSize * 0.72),
          ),
        ),
        SizedBox(width: logoSize * 0.22),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Vision',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Screen',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Pulsing rings widget (used on splash)
// ─────────────────────────────────────────────────────────────
class VsPulsingRings extends StatefulWidget {
  const VsPulsingRings({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.size = 180,
  });

  final Widget child;
  final Color color;
  final double size;

  @override
  State<VsPulsingRings> createState() => _VsPulsingRingsState();
}

class _VsPulsingRingsState extends State<VsPulsingRings>
    with TickerProviderStateMixin {
  late final AnimationController _r1;
  late final AnimationController _r2;
  late final AnimationController _r3;

  @override
  void initState() {
    super.initState();
    _r1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _r2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _r3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _r1.dispose();
    _r2.dispose();
    _r3.dispose();
    super.dispose();
  }

  Widget _ring(
    AnimationController ctrl,
    double baseSize,
    double scaleEnd,
    double opacityStart,
    double opacityEnd,
  ) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, _) {
        final t = ctrl.value;
        final scale = 1.0 + (scaleEnd - 1.0) * t;
        final opacity = opacityStart + (opacityEnd - opacityStart) * t;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: baseSize,
              height: baseSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.color, width: 1.2),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ring(_r3, s * 0.95, 1.15, 0.08, 0.22),
          _ring(_r2, s * 0.78, 1.12, 0.15, 0.38),
          _ring(_r1, s * 0.62, 1.10, 0.22, 0.55),
          widget.child,
        ],
      ),
    );
  }
}
