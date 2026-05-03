import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Onboarding slide illustrations — drawn entirely in code.
// No external image assets required.
// ─────────────────────────────────────────────────────────────

// Slide 1: CHW with phone — stylized figure holding a device
class ChwIllustration extends StatefulWidget {
  const ChwIllustration({super.key, this.color = Colors.white});
  final Color color;
  @override
  State<ChwIllustration> createState() => _ChwIllustrationState();
}

class _ChwIllustrationState extends State<ChwIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _float;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _float = Tween<double>(begin: 0, end: -10)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _pulse = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _float.value),
        child: Transform.scale(
          scale: _pulse.value,
          child: CustomPaint(
            size: const Size(220, 220),
            painter: _ChwPainter(color: widget.color),
          ),
        ),
      ),
    );
  }
}

class _ChwPainter extends CustomPainter {
  const _ChwPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pf = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final pf2 = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // ── Body / torso ──
    final torsoPath = Path()
      ..moveTo(cx - 28, cy + 10)
      ..cubicTo(cx - 32, cy + 40, cx - 30, cy + 70, cx - 20, cy + 90)
      ..lineTo(cx + 20, cy + 90)
      ..cubicTo(cx + 30, cy + 70, cx + 32, cy + 40, cx + 28, cy + 10)
      ..close();
    canvas.drawPath(torsoPath, pf2);
    canvas.drawPath(torsoPath, p);

    // ── Head ──
    canvas.drawCircle(Offset(cx, cy - 28), 26, pf2);
    canvas.drawCircle(Offset(cx, cy - 28), 26, p);

    // ── Hair / cap ──
    final capPath = Path()
      ..moveTo(cx - 26, cy - 28)
      ..arcTo(Rect.fromCenter(center: Offset(cx, cy - 28), width: 52, height: 52),
          pi, pi, false)
      ..close();
    canvas.drawPath(capPath, pf);
    canvas.drawPath(capPath, p);

    // ── Cross on cap ──
    final crossP = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy - 50), Offset(cx, cy - 38), crossP);
    canvas.drawLine(Offset(cx - 6, cy - 44), Offset(cx + 6, cy - 44), crossP);

    // ── Left arm holding phone ──
    final armPath = Path()
      ..moveTo(cx - 28, cy + 15)
      ..cubicTo(cx - 55, cy + 20, cx - 62, cy + 45, cx - 55, cy + 60);
    canvas.drawPath(armPath, p);

    // ── Phone ──
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 52, cy + 72), width: 28, height: 40),
      const Radius.circular(5),
    );
    canvas.drawRRect(phoneRect, pf2);
    canvas.drawRRect(phoneRect, p);

    // Phone screen
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 52, cy + 70), width: 20, height: 28),
      const Radius.circular(3),
    );
    canvas.drawRRect(screenRect, pf);

    // Screen content — mini E chart lines
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(cx - 58, cy + 60 + i * 5.0),
        Offset(cx - 46, cy + 60 + i * 5.0),
        linePaint,
      );
    }

    // ── Right arm ──
    final rArmPath = Path()
      ..moveTo(cx + 28, cy + 15)
      ..cubicTo(cx + 50, cy + 25, cx + 55, cy + 50, cx + 45, cy + 65);
    canvas.drawPath(rArmPath, p);

    // ── Legs ──
    canvas.drawLine(Offset(cx - 10, cy + 90), Offset(cx - 15, cy + 130), p);
    canvas.drawLine(Offset(cx + 10, cy + 90), Offset(cx + 15, cy + 130), p);

    // ── Feet ──
    canvas.drawLine(Offset(cx - 15, cy + 130), Offset(cx - 28, cy + 133), p);
    canvas.drawLine(Offset(cx + 15, cy + 130), Offset(cx + 28, cy + 133), p);

    // ── Heartbeat line floating above ──
    final hbPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final hbPath = Path()
      ..moveTo(cx - 50, cy - 75)
      ..lineTo(cx - 30, cy - 75)
      ..lineTo(cx - 18, cy - 95)
      ..lineTo(cx - 5, cy - 60)
      ..lineTo(cx + 8, cy - 82)
      ..lineTo(cx + 20, cy - 75)
      ..lineTo(cx + 50, cy - 75);
    canvas.drawPath(hbPath, hbPaint);

    // ── Community dots ──
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    for (final pos in [
      Offset(cx + 65, cy - 20),
      Offset(cx + 75, cy + 10),
      Offset(cx - 70, cy - 10),
      Offset(cx - 65, cy + 20),
    ]) {
      canvas.drawCircle(pos, 5, dotPaint);
      canvas.drawCircle(pos, 5, p..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_ChwPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────
// Slide 2: Tumbling E chart with measurement lines
// ─────────────────────────────────────────────────────────────
class EChartIllustration extends StatefulWidget {
  const EChartIllustration({super.key, this.color = Colors.white});
  final Color color;
  @override
  State<EChartIllustration> createState() => _EChartIllustrationState();
}

class _EChartIllustrationState extends State<EChartIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scan;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _scan = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scan,
      builder: (_, __) => CustomPaint(
        size: const Size(220, 220),
        painter: _EChartPainter(color: widget.color, scanProgress: _scan.value),
      ),
    );
  }
}

class _EChartPainter extends CustomPainter {
  const _EChartPainter({required this.color, required this.scanProgress});
  final Color color;
  final double scanProgress;

  void _drawE(Canvas canvas, Offset center, double size, double rotation,
      Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final u = size / 5;
    final path = Path()
      ..addRect(Rect.fromLTWH(-size / 2, -size / 2, u, size)) // spine
      ..addRect(Rect.fromLTWH(-size / 2, -size / 2, size, u)) // top
      ..addRect(Rect.fromLTWH(-size / 2, -u / 2, size * 0.8, u)) // mid
      ..addRect(Rect.fromLTWH(-size / 2, size / 2 - u, size, u)); // bottom
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final pStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final pFaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // ── Chart frame ──
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: 160, height: 180),
      const Radius.circular(12),
    );
    canvas.drawRRect(frameRect, pFaint);
    canvas.drawRRect(frameRect, pStroke);

    // ── E rows (decreasing size) ──
    final rows = [
      (cy - 72.0, 32.0, 0.0),
      (cy - 42.0, 24.0, pi / 2),
      (cy - 16.0, 18.0, pi),
      (cy + 8.0, 14.0, 3 * pi / 2),
      (cy + 28.0, 10.0, 0.0),
      (cy + 44.0, 8.0, pi / 2),
    ];

    for (final (y, eSize, rot) in rows) {
      _drawE(canvas, Offset(cx, y), eSize, rot, p);
    }

    // ── Scan line ──
    final scanY = (cy - 80) + (160 * scanProgress);
    final scanPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(cx - 80, scanY), Offset(cx + 80, scanY), scanPaint);

    // ── Measurement arrows ──
    final arrowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Left ruler
    for (int i = 0; i < 6; i++) {
      final y = cy - 72 + i * 24.0;
      canvas.drawLine(Offset(cx - 90, y), Offset(cx - 82, y), arrowPaint);
    }
    canvas.drawLine(Offset(cx - 86, cy - 72), Offset(cx - 86, cy + 68), arrowPaint);

    // ── LogMAR label ──
    final textPainter = TextPainter(
      text: TextSpan(
        text: '6/6',
        style: TextStyle(
          color: color.withValues(alpha: 0.7),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(cx + 72, cy + 40));
  }

  @override
  bool shouldRepaint(_EChartPainter old) =>
      old.color != color || old.scanProgress != scanProgress;
}

// ─────────────────────────────────────────────────────────────
// Slide 3: Patient clipboard + referral card
// ─────────────────────────────────────────────────────────────
class PatientCareIllustration extends StatefulWidget {
  const PatientCareIllustration({super.key, this.color = Colors.white});
  final Color color;
  @override
  State<PatientCareIllustration> createState() =>
      _PatientCareIllustrationState();
}

class _PatientCareIllustrationState extends State<PatientCareIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _checkAnim = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _checkAnim,
      builder: (_, __) => CustomPaint(
        size: const Size(220, 220),
        painter: _PatientCarePainter(
            color: widget.color, checkScale: _checkAnim.value),
      ),
    );
  }
}

class _PatientCarePainter extends CustomPainter {
  const _PatientCarePainter({required this.color, required this.checkScale});
  final Color color;
  final double checkScale;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pf = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final pf2 = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // ── Clipboard ──
    final clipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 15, cy + 10), width: 130, height: 160),
      const Radius.circular(10),
    );
    canvas.drawRRect(clipRect, pf);
    canvas.drawRRect(clipRect, p);

    // Clip top
    final clipTop = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 15, cy - 68), width: 50, height: 16),
      const Radius.circular(8),
    );
    canvas.drawRRect(clipTop, pf2);
    canvas.drawRRect(clipTop, p);

    // ── Patient avatar on clipboard ──
    canvas.drawCircle(Offset(cx - 15, cy - 30), 18, pf2);
    canvas.drawCircle(Offset(cx - 15, cy - 30), 18, p);

    // Face features
    canvas.drawCircle(Offset(cx - 22, cy - 33), 2.5,
        Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx - 8, cy - 33), 2.5,
        Paint()..color = color..style = PaintingStyle.fill);
    final smilePath = Path()
      ..moveTo(cx - 22, cy - 22)
      ..quadraticBezierTo(cx - 15, cy - 16, cx - 8, cy - 22);
    canvas.drawPath(smilePath, p..strokeWidth = 2.0);

    // ── Lines on clipboard ──
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(cx - 55, cy + 10 + i * 14.0),
        Offset(cx + 25, cy + 10 + i * 14.0),
        linePaint,
      );
    }

    // ── Referral card (floating, rotated) ──
    canvas.save();
    canvas.translate(cx + 55, cy - 20);
    canvas.rotate(-0.2);
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 80, height: 55),
      const Radius.circular(8),
    );
    canvas.drawRRect(cardRect, pf2);
    canvas.drawRRect(cardRect, p..strokeWidth = 2.0);

    // Arrow on card
    final arrowPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-20, 0), const Offset(15, 0), arrowPaint);
    canvas.drawLine(const Offset(8, -7), const Offset(15, 0), arrowPaint);
    canvas.drawLine(const Offset(8, 7), const Offset(15, 0), arrowPaint);
    canvas.restore();

    // ── Animated checkmark ──
    canvas.save();
    canvas.translate(cx + 40, cy + 55);
    canvas.scale(checkScale);
    final checkBg = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 18, checkBg);
    canvas.drawCircle(Offset.zero, 18, p..strokeWidth = 2.0);
    final checkPath = Path()
      ..moveTo(-8, 0)
      ..lineTo(-2, 7)
      ..lineTo(9, -6);
    canvas.drawPath(checkPath, p..strokeWidth = 3.0);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PatientCarePainter old) =>
      old.color != color || old.checkScale != checkScale;
}

// ─────────────────────────────────────────────────────────────
// Slide 4: Analytics bar chart with trend line
// ─────────────────────────────────────────────────────────────
class AnalyticsIllustration extends StatefulWidget {
  const AnalyticsIllustration({super.key, this.color = Colors.white});
  final Color color;
  @override
  State<AnalyticsIllustration> createState() => _AnalyticsIllustrationState();
}

class _AnalyticsIllustrationState extends State<AnalyticsIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _grow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _grow = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _grow,
      builder: (_, __) => CustomPaint(
        size: const Size(220, 220),
        painter: _AnalyticsPainter(color: widget.color, growFactor: _grow.value),
      ),
    );
  }
}

class _AnalyticsPainter extends CustomPainter {
  const _AnalyticsPainter({required this.color, required this.growFactor});
  final Color color;
  final double growFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final pf = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final pf2 = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    // ── Chart frame ──
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: 170, height: 150),
      const Radius.circular(12),
    );
    canvas.drawRRect(frameRect, pf);
    canvas.drawRRect(frameRect, p);

    // ── Axes ──
    final axisP = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 70, cy + 55), Offset(cx - 70, cy - 55), axisP);
    canvas.drawLine(Offset(cx - 70, cy + 55), Offset(cx + 70, cy + 55), axisP);

    // ── Bars ──
    final barData = [0.4, 0.65, 0.5, 0.8, 0.6, 0.9, 0.75];
    final barW = 14.0;
    final maxH = 90.0;
    final startX = cx - 60.0;
    final baseY = cy + 55.0;

    for (int i = 0; i < barData.length; i++) {
      final h = barData[i] * maxH * growFactor;
      final x = startX + i * 20.0;
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barW / 2, baseY - h, barW, h),
        const Radius.circular(4),
      );
      canvas.drawRRect(barRect, pf2);
      canvas.drawRRect(barRect, p..strokeWidth = 1.5);
    }

    // ── Trend line ──
    final trendPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final trendPath = Path();
    for (int i = 0; i < barData.length; i++) {
      final h = barData[i] * maxH * growFactor;
      final x = startX + i * 20.0;
      final y = baseY - h - 6;
      if (i == 0) {
        trendPath.moveTo(x, y);
      } else {
        trendPath.lineTo(x, y);
      }
    }
    canvas.drawPath(trendPath, trendPaint);

    // ── Data points on trend ──
    for (int i = 0; i < barData.length; i++) {
      final h = barData[i] * maxH * growFactor;
      final x = startX + i * 20.0;
      final y = baseY - h - 6;
      canvas.drawCircle(Offset(x, y), 3.5,
          Paint()..color = color..style = PaintingStyle.fill);
    }

    // ── Floating stat badge ──
    canvas.save();
    canvas.translate(cx + 55, cy - 55);
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 52, height: 28),
      const Radius.circular(14),
    );
    canvas.drawRRect(badgeRect, pf2);
    canvas.drawRRect(badgeRect, p..strokeWidth = 1.5);

    // Up arrow
    final upArrow = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-8, 4), const Offset(-8, -4), upArrow);
    canvas.drawLine(const Offset(-12, 0), const Offset(-8, -4), upArrow);
    canvas.drawLine(const Offset(-4, 0), const Offset(-8, -4), upArrow);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AnalyticsPainter old) =>
      old.color != color || old.growFactor != growFactor;
}
