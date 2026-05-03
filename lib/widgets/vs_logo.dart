import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// VisionScreen "Sight Mark" Logo
//
// Design: Eye shape + crosshair target ring inside iris +
//         heartbeat pulse integrated into lower eyelid +
//         solid teal pupil with white highlight
//
// Works on both light (teal) and dark (white) backgrounds.
// ─────────────────────────────────────────────────────────────

class VsLogo extends StatelessWidget {
  const VsLogo({
    super.key,
    this.size = 56,
    this.color = Colors.white,
    this.showRing = true,
  });

  final double size;
  final Color color;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SightMarkPainter(color: color, showRing: showRing),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Animated logo — blinks the pupil
// ─────────────────────────────────────────────────────────────
class VsLogoAnimated extends StatefulWidget {
  const VsLogoAnimated({
    super.key,
    this.size = 56,
    this.color = Colors.white,
  });

  final double size;
  final Color color;

  @override
  State<VsLogoAnimated> createState() => _VsLogoAnimatedState();
}

class _VsLogoAnimatedState extends State<VsLogoAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _blink;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // Blink: quick close (80ms) then open (120ms), rest open
    _blink = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.05)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 8),
      TweenSequenceItem(
          tween: Tween(begin: 0.05, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 12),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 10),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blink,
      builder: (_, __) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _SightMarkPainter(
            color: widget.color,
            blinkFactor: _blink.value,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────
class _SightMarkPainter extends CustomPainter {
  const _SightMarkPainter({
    required this.color,
    this.blinkFactor = 1.0,
    this.showRing = true,
  });

  final Color color;
  final double blinkFactor; // 1.0 = fully open, 0.0 = closed
  final bool showRing;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // ── Eye outline (almond shape) ──────────────────────────
    // Vertical scale by blinkFactor to simulate blinking
    final eyeH = h * 0.44 * blinkFactor;
    final eyeW = w * 0.88;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(1.0, blinkFactor.clamp(0.05, 1.0));
    canvas.translate(-cx, -cy);

    final eyePath = Path();
    // Upper lid — gentle arc
    eyePath.moveTo(cx - eyeW / 2, cy);
    eyePath.cubicTo(
      cx - eyeW * 0.25, cy - eyeH * 1.1,
      cx + eyeW * 0.25, cy - eyeH * 1.1,
      cx + eyeW / 2, cy,
    );
    // Lower lid — with subtle pulse bump in center
    eyePath.cubicTo(
      cx + eyeW * 0.25, cy + eyeH * 0.9,
      cx + eyeW * 0.05, cy + eyeH * 0.9,
      cx, cy + eyeH * 0.75,
    );
    eyePath.cubicTo(
      cx - eyeW * 0.05, cy + eyeH * 0.9,
      cx - eyeW * 0.25, cy + eyeH * 0.9,
      cx - eyeW / 2, cy,
    );
    eyePath.close();
    canvas.drawPath(eyePath, strokePaint);
    canvas.restore();

    if (blinkFactor < 0.15) return; // fully closed — skip iris

    // ── Iris circle ─────────────────────────────────────────
    final irisR = w * 0.20;
    canvas.drawCircle(Offset(cx, cy), irisR, strokePaint);

    // ── Crosshair target lines inside iris ──────────────────
    if (showRing) {
      final crossPaint = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round;

      final gap = irisR * 0.35;
      final arm = irisR * 0.55;

      // Top
      canvas.drawLine(
          Offset(cx, cy - gap), Offset(cx, cy - gap - arm), crossPaint);
      // Bottom
      canvas.drawLine(
          Offset(cx, cy + gap), Offset(cx, cy + gap + arm), crossPaint);
      // Left
      canvas.drawLine(
          Offset(cx - gap, cy), Offset(cx - gap - arm, cy), crossPaint);
      // Right
      canvas.drawLine(
          Offset(cx + gap, cy), Offset(cx + gap + arm, cy), crossPaint);
    }

    // ── Pupil (solid filled circle) ─────────────────────────
    canvas.drawCircle(Offset(cx, cy), w * 0.09, fillPaint);

    // ── Highlight dot ────────────────────────────────────────
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(cx + w * 0.04, cy - w * 0.04), w * 0.03, highlightPaint);

    // ── Heartbeat pulse on lower eyelid ─────────────────────
    // Small ECG-style bump drawn below the iris
    final pulsePaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final py = cy + irisR + w * 0.08;
    final pw2 = w * 0.28;
    final pulsePath = Path();
    pulsePath.moveTo(cx - pw2, py);
    pulsePath.lineTo(cx - pw2 * 0.5, py);
    pulsePath.lineTo(cx - pw2 * 0.25, py - w * 0.09);
    pulsePath.lineTo(cx, py + w * 0.06);
    pulsePath.lineTo(cx + pw2 * 0.25, py - w * 0.04);
    pulsePath.lineTo(cx + pw2 * 0.5, py);
    pulsePath.lineTo(cx + pw2, py);
    canvas.drawPath(pulsePath, pulsePaint);
  }

  @override
  bool shouldRepaint(_SightMarkPainter old) =>
      old.color != color ||
      old.blinkFactor != blinkFactor ||
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
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(logoSize * 0.28),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Center(
            child: animate
                ? VsLogoAnimated(size: logoSize * 0.58, color: color)
                : VsLogo(size: logoSize * 0.58, color: color),
          ),
        ),
        SizedBox(width: logoSize * 0.22),
        Text(
          'VisionScreen',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.5,
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
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _r2 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);
    _r3 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _r1.dispose();
    _r2.dispose();
    _r3.dispose();
    super.dispose();
  }

  Widget _ring(AnimationController ctrl, double baseSize,
      double scaleEnd, double opacityStart, double opacityEnd) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
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
                border: Border.all(
                    color: widget.color, width: 1.2),
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
