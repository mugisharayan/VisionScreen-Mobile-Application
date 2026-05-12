import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Onboarding Illustrations — rich, animated, full-size
// ─────────────────────────────────────────────────────────────

// ── Slide 1: CHW with phone + community network ──────────────
class ChwIllustration extends StatefulWidget {
  const ChwIllustration({super.key, this.color = Colors.white});
  final Color color;
  @override
  State<ChwIllustration> createState() => _ChwIllustrationState();
}

class _ChwIllustrationState extends State<ChwIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _pingCtrl;
  late final Animation<double> _float;
  late final Animation<double> _pulse;
  late final Animation<double> _ping;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pingCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _float = Tween<double>(begin: 0, end: -14).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _ping  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _pingCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _floatCtrl.dispose(); _pulseCtrl.dispose(); _pingCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatCtrl, _pulseCtrl, _pingCtrl]),
      builder: (_, _) => Transform.translate(
        offset: Offset(0, _float.value),
        child: Transform.scale(
          scale: _pulse.value,
          child: CustomPaint(
            size: const Size(280, 280),
            painter: _ChwPainter(color: widget.color, ping: _ping.value),
          ),
        ),
      ),
    );
  }
}

class _ChwPainter extends CustomPainter {
  const _ChwPainter({required this.color, required this.ping});
  final Color color;
  final double ping;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2 + 10;

    final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.8..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final fill   = Paint()..color = color.withValues(alpha: 0.20)..style = PaintingStyle.fill;
    final fill2  = Paint()..color = color.withValues(alpha: 0.40)..style = PaintingStyle.fill;
    final bright = Paint()..color = color.withValues(alpha: 0.85)..style = PaintingStyle.fill;

    // ── Ping rings ──
    for (int r = 1; r <= 3; r++) {
      final radius = 30.0 + r * 22 * ping;
      final opacity = (1 - ping) * 0.18 / r;
      canvas.drawCircle(Offset(cx, cy - 30),
        radius,
        Paint()..color = color.withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }

    // ── Ground shadow ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 105), width: 90, height: 14),
      Paint()..color = color.withValues(alpha: 0.12)..style = PaintingStyle.fill,
    );

    // ── Legs ──
    canvas.drawLine(Offset(cx - 12, cy + 72), Offset(cx - 18, cy + 105), stroke..strokeWidth = 8);
    canvas.drawLine(Offset(cx + 12, cy + 72), Offset(cx + 18, cy + 105), stroke..strokeWidth = 8);
    // Shoes
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 22, cy + 108), width: 22, height: 8), const Radius.circular(4)), fill2);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 22, cy + 108), width: 22, height: 8), const Radius.circular(4)), fill2);

    // ── Torso ──
    final torso = Path()
      ..moveTo(cx - 26, cy + 10)
      ..cubicTo(cx - 30, cy + 40, cx - 28, cy + 65, cx - 18, cy + 72)
      ..lineTo(cx + 18, cy + 72)
      ..cubicTo(cx + 28, cy + 65, cx + 30, cy + 40, cx + 26, cy + 10)
      ..close();
    canvas.drawPath(torso, fill2);
    canvas.drawPath(torso, stroke..strokeWidth = 2.5);

    // Vest / uniform detail
    canvas.drawLine(Offset(cx, cy + 12), Offset(cx, cy + 68), stroke..strokeWidth = 1.5..color = color.withValues(alpha: 0.4));
    // Cross badge
    canvas.drawLine(Offset(cx + 14, cy + 22), Offset(cx + 14, cy + 32), stroke..strokeWidth = 2.5..color = color);
    canvas.drawLine(Offset(cx + 9, cy + 27), Offset(cx + 19, cy + 27), stroke..strokeWidth = 2.5..color = color);

    // ── Left arm (holding phone) ──
    final lArm = Path()
      ..moveTo(cx - 26, cy + 14)
      ..cubicTo(cx - 52, cy + 22, cx - 62, cy + 50, cx - 56, cy + 68);
    canvas.drawPath(lArm, stroke..strokeWidth = 8..color = fill2.color);
    canvas.drawPath(lArm, stroke..strokeWidth = 2.5..color = color);

    // ── Phone ──
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 54, cy + 80), width: 32, height: 48),
      const Radius.circular(6),
    );
    canvas.drawRRect(phoneRect, fill2);
    canvas.drawRRect(phoneRect, stroke..strokeWidth = 2.0..color = color);
    // Screen
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 54, cy + 78), width: 24, height: 34),
      const Radius.circular(3),
    );
    canvas.drawRRect(screenRect, fill);
    // E chart on screen
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(cx - 62, cy + 66 + i * 6.0),
        Offset(cx - 46, cy + 66 + i * 6.0),
        Paint()..color = color.withValues(alpha: 0.7)..strokeWidth = 1.8..strokeCap = StrokeCap.round,
      );
    }
    // Home button
    canvas.drawCircle(Offset(cx - 54, cy + 100), 3, bright);

    // ── Right arm ──
    final rArm = Path()
      ..moveTo(cx + 26, cy + 14)
      ..cubicTo(cx + 50, cy + 28, cx + 55, cy + 55, cx + 46, cy + 68);
    canvas.drawPath(rArm, stroke..strokeWidth = 8..color = fill2.color);
    canvas.drawPath(rArm, stroke..strokeWidth = 2.5..color = color);

    // ── Head ──
    canvas.drawCircle(Offset(cx, cy - 30), 30, fill2);
    canvas.drawCircle(Offset(cx, cy - 30), 30, stroke..strokeWidth = 2.5..color = color);

    // Face
    canvas.drawCircle(Offset(cx - 10, cy - 34), 3.5, bright);
    canvas.drawCircle(Offset(cx + 10, cy - 34), 3.5, bright);
    final smile = Path()..moveTo(cx - 10, cy - 20)..quadraticBezierTo(cx, cy - 13, cx + 10, cy - 20);
    canvas.drawPath(smile, stroke..strokeWidth = 2.5..color = color);

    // ── Cap ──
    final cap = Path()
      ..moveTo(cx - 30, cy - 30)
      ..arcTo(Rect.fromCenter(center: Offset(cx, cy - 30), width: 60, height: 60), pi, pi, false)
      ..close();
    canvas.drawPath(cap, fill);
    canvas.drawPath(cap, stroke..strokeWidth = 2.0..color = color);
    // Cap brim
    canvas.drawLine(Offset(cx - 34, cy - 30), Offset(cx + 34, cy - 30), stroke..strokeWidth = 3.0..color = color);
    // Red cross on cap
    canvas.drawLine(Offset(cx, cy - 52), Offset(cx, cy - 40), stroke..strokeWidth = 3.0..color = color);
    canvas.drawLine(Offset(cx - 6, cy - 46), Offset(cx + 6, cy - 46), stroke..strokeWidth = 3.0..color = color);

    // ── Floating heartbeat line ──
    final hbPaint = Paint()..color = color.withValues(alpha: 0.55)..strokeWidth = 2.2..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    final hb = Path()
      ..moveTo(cx - 65, cy - 85)
      ..lineTo(cx - 40, cy - 85)
      ..lineTo(cx - 25, cy - 108)
      ..lineTo(cx - 8, cy - 68)
      ..lineTo(cx + 8, cy - 96)
      ..lineTo(cx + 25, cy - 85)
      ..lineTo(cx + 65, cy - 85);
    canvas.drawPath(hb, hbPaint);

    // ── Community nodes ──
    final nodes = [
      Offset(cx + 80, cy - 40), Offset(cx + 90, cy + 10),
      Offset(cx - 85, cy - 30), Offset(cx - 80, cy + 20),
    ];
    for (final n in nodes) {
      canvas.drawCircle(n, 7, fill);
      canvas.drawCircle(n, 7, stroke..strokeWidth = 1.8..color = color.withValues(alpha: 0.6));
      canvas.drawLine(Offset(cx, cy), n, Paint()..color = color.withValues(alpha: 0.15)..strokeWidth = 1.0);
    }
  }

  @override
  bool shouldRepaint(_ChwPainter old) => old.ping != ping || old.color != color;
}

// ── Slide 2: Tumbling E chart with scan beam ─────────────────
class EChartIllustration extends StatefulWidget {
  const EChartIllustration({super.key, this.color = Colors.white});
  final Color color;
  @override
  State<EChartIllustration> createState() => _EChartIllustrationState();
}

class _EChartIllustrationState extends State<EChartIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double> _scan;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat(reverse: true);
    _scan  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));
    _float = Tween<double>(begin: 0, end: -10).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _scanCtrl.dispose(); _floatCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scanCtrl, _floatCtrl]),
      builder: (_, _) => Transform.translate(
        offset: Offset(0, _float.value),
        child: CustomPaint(
          size: const Size(280, 280),
          painter: _EChartPainter(color: widget.color, scanProgress: _scan.value),
        ),
      ),
    );
  }
}

class _EChartPainter extends CustomPainter {
  const _EChartPainter({required this.color, required this.scanProgress});
  final Color color;
  final double scanProgress;

  void _drawE(Canvas canvas, Offset center, double sz, double rotation, Paint p) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final u = sz / 5;
    final path = Path()
      ..addRect(Rect.fromLTWH(-sz / 2, -sz / 2, u, sz))
      ..addRect(Rect.fromLTWH(-sz / 2, -sz / 2, sz, u))
      ..addRect(Rect.fromLTWH(-sz / 2, -u / 2, sz * 0.78, u))
      ..addRect(Rect.fromLTWH(-sz / 2, sz / 2 - u, sz, u));
    canvas.drawPath(path, p);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;

    final fill  = Paint()..color = color.withValues(alpha: 0.15)..style = PaintingStyle.fill;
    final fill2 = Paint()..color = color.withValues(alpha: 0.35)..style = PaintingStyle.fill;
    final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeCap = StrokeCap.round;
    final eFill  = Paint()..color = color..style = PaintingStyle.fill;

    // ── Chart board ──
    final board = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 190, height: 210),
      const Radius.circular(16),
    );
    canvas.drawRRect(board, fill);
    canvas.drawRRect(board, stroke..strokeWidth = 2.0);

    // Board stand
    canvas.drawLine(Offset(cx, cy + 110), Offset(cx, cy + 130), stroke..strokeWidth = 4.0);
    canvas.drawLine(Offset(cx - 24, cy + 130), Offset(cx + 24, cy + 130), stroke..strokeWidth = 4.0);

    // ── E rows ──
    final rows = [
      (cy - 82.0, 36.0, 0.0),
      (cy - 52.0, 28.0, pi / 2),
      (cy - 26.0, 22.0, pi),
      (cy - 4.0,  17.0, 3 * pi / 2),
      (cy + 14.0, 13.0, 0.0),
      (cy + 30.0, 10.0, pi / 2),
      (cy + 43.0,  8.0, pi),
    ];
    for (final (y, eSize, rot) in rows) {
      _drawE(canvas, Offset(cx, y), eSize, rot, eFill);
    }

    // ── Scan beam ──
    final scanY = (cy - 95) + (210 * scanProgress);
    // Glow
    canvas.drawRect(
      Rect.fromLTWH(cx - 95, scanY - 6, 190, 12),
      Paint()..color = color.withValues(alpha: 0.08)..style = PaintingStyle.fill,
    );
    // Line
    canvas.drawLine(
      Offset(cx - 95, scanY),
      Offset(cx + 95, scanY),
      Paint()..color = color.withValues(alpha: 0.7)..strokeWidth = 2.0,
    );
    // Scan arrows on sides
    canvas.drawLine(Offset(cx - 100, scanY - 5), Offset(cx - 95, scanY), stroke..strokeWidth = 1.5..color = color.withValues(alpha: 0.6));
    canvas.drawLine(Offset(cx - 100, scanY + 5), Offset(cx - 95, scanY), stroke..strokeWidth = 1.5..color = color.withValues(alpha: 0.6));

    // ── Left ruler ──
    final rulerPaint = Paint()..color = color.withValues(alpha: 0.4)..strokeWidth = 1.2..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 108, cy - 95), Offset(cx - 108, cy + 110), rulerPaint);
    for (int i = 0; i <= 7; i++) {
      final y = cy - 95 + i * 29.0;
      canvas.drawLine(Offset(cx - 114, y), Offset(cx - 108, y), rulerPaint);
    }

    // ── Floating badge: 6/6 ──
    canvas.save();
    canvas.translate(cx + 110, cy - 60);
    final badge = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 56, height: 36),
      const Radius.circular(18),
    );
    canvas.drawRRect(badge, fill2);
    canvas.drawRRect(badge, stroke..strokeWidth = 1.5..color = color);
    final tp = TextPainter(
      text: TextSpan(text: '6/6', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();

    // ── Eye icon floating top-left ──
    canvas.save();
    canvas.translate(cx - 105, cy - 70);
    final eyePath = Path()
      ..moveTo(-18, 0)
      ..cubicTo(-10, -12, 10, -12, 18, 0)
      ..cubicTo(10, 12, -10, 12, -18, 0);
    canvas.drawPath(eyePath, fill2);
    canvas.drawPath(eyePath, stroke..strokeWidth = 1.8..color = color);
    canvas.drawCircle(Offset.zero, 6, fill2);
    canvas.drawCircle(Offset.zero, 6, stroke..strokeWidth = 1.5..color = color);
    canvas.drawCircle(Offset.zero, 2.5, Paint()..color = color..style = PaintingStyle.fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EChartPainter old) => old.scanProgress != scanProgress || old.color != color;
}

// â”€â”€ Slide 3: Patient clipboard + referral card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class PatientCareIllustration extends StatefulWidget {
  const PatientCareIllustration({super.key, this.color = Colors.white});
  final Color color;
  @override
  State<PatientCareIllustration> createState() => _PatientCareIllustrationState();
}
class _PatientCareIllustrationState extends State<PatientCareIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double> _check;
  late final Animation<double> _float;
  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _check = Tween<double>(begin: 0.88, end: 1.0).animate(CurvedAnimation(parent: _checkCtrl, curve: Curves.easeInOut));
    _float = Tween<double>(begin: 0, end: -12).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _checkCtrl.dispose(); _floatCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_checkCtrl, _floatCtrl]),
      builder: (_, _) => Transform.translate(
        offset: Offset(0, _float.value),
        child: CustomPaint(
          size: const Size(280, 280),
          painter: _PatientCarePainter(color: widget.color, checkScale: _check.value),
        ),
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
    final cx = size.width / 2, cy = size.height / 2;
    final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final fill   = Paint()..color = color.withValues(alpha: 0.15)..style = PaintingStyle.fill;
    final fill2  = Paint()..color = color.withValues(alpha: 0.35)..style = PaintingStyle.fill;
    final bright = Paint()..color = color..style = PaintingStyle.fill;
    final clip = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 18, cy + 8), width: 150, height: 185), const Radius.circular(14));
    canvas.drawRRect(clip, fill);
    canvas.drawRRect(clip, stroke..strokeWidth = 2.2);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 18, cy - 84), width: 60, height: 18), const Radius.circular(9)), fill2);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 18, cy - 84), width: 60, height: 18), const Radius.circular(9)), stroke..strokeWidth = 1.8);
    canvas.drawCircle(Offset(cx - 18, cy - 42), 22, fill2);
    canvas.drawCircle(Offset(cx - 18, cy - 42), 22, stroke..strokeWidth = 2.0);
    canvas.drawCircle(Offset(cx - 26, cy - 46), 3, bright);
    canvas.drawCircle(Offset(cx - 10, cy - 46), 3, bright);
    final smile = Path()..moveTo(cx - 26, cy - 33)..quadraticBezierTo(cx - 18, cy - 26, cx - 10, cy - 33);
    canvas.drawPath(smile, stroke..strokeWidth = 2.2..color = color);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 18, cy - 10), width: 90, height: 8), const Radius.circular(4)), fill2);
    final linePaint = Paint()..color = color.withValues(alpha: 0.45)..strokeWidth = 2.0..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final y = cy + 14 + i * 16.0;
      canvas.drawCircle(Offset(cx - 78, y), 3, Paint()..color = color.withValues(alpha: 0.5)..style = PaintingStyle.fill);
      canvas.drawLine(Offset(cx - 68, y), Offset(cx + 42, y), linePaint);
    }
    for (int i = 0; i < 2; i++) {
      final bx = cx - 50 + i * 44.0;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(bx, cy + 100), width: 36, height: 20), const Radius.circular(10)), fill2);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(bx, cy + 100), width: 36, height: 20), const Radius.circular(10)), stroke..strokeWidth = 1.5);
      final tp = TextPainter(text: TextSpan(text: i == 0 ? 'OD' : 'OS', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(bx - tp.width / 2, cy + 100 - tp.height / 2));
    }
    canvas.save();
    canvas.translate(cx + 72, cy - 28);
    canvas.rotate(-0.18);
    final card = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 96, height: 66), const Radius.circular(12));
    canvas.drawRRect(card, fill2);
    canvas.drawRRect(card, stroke..strokeWidth = 2.0..color = color);
    canvas.drawLine(const Offset(0, -12), const Offset(0, 12), stroke..strokeWidth = 3.5..color = color);
    canvas.drawLine(const Offset(-12, 0), const Offset(12, 0), stroke..strokeWidth = 3.5..color = color);
    canvas.drawLine(const Offset(-30, 22), const Offset(30, 22), stroke..strokeWidth = 2.0..color = color.withValues(alpha: 0.6));
    canvas.drawLine(const Offset(22, 16), const Offset(30, 22), stroke..strokeWidth = 2.0..color = color.withValues(alpha: 0.6));
    canvas.drawLine(const Offset(22, 28), const Offset(30, 22), stroke..strokeWidth = 2.0..color = color.withValues(alpha: 0.6));
    canvas.restore();
    canvas.save();
    canvas.translate(cx + 52, cy + 72);
    canvas.scale(checkScale);
    canvas.drawCircle(Offset.zero, 22, Paint()..color = color.withValues(alpha: 0.30)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset.zero, 22, stroke..strokeWidth = 2.2..color = color);
    final check = Path()..moveTo(-10, 0)..lineTo(-3, 9)..lineTo(11, -8);
    canvas.drawPath(check, stroke..strokeWidth = 3.5..color = color);
    canvas.restore();
  }
  @override
  bool shouldRepaint(_PatientCarePainter old) => old.checkScale != checkScale || old.color != color;
}

// â”€â”€ Slide 4: Analytics dashboard â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class AnalyticsIllustration extends StatefulWidget {
  const AnalyticsIllustration({super.key, this.color = Colors.white});
  final Color color;
  @override
  State<AnalyticsIllustration> createState() => _AnalyticsIllustrationState();
}
class _AnalyticsIllustrationState extends State<AnalyticsIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _growCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double> _grow;
  late final Animation<double> _float;
  @override
  void initState() {
    super.initState();
    _growCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))..repeat(reverse: true);
    _grow  = Tween<double>(begin: 0.82, end: 1.0).animate(CurvedAnimation(parent: _growCtrl, curve: Curves.easeInOut));
    _float = Tween<double>(begin: 0, end: -10).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _growCtrl.dispose(); _floatCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_growCtrl, _floatCtrl]),
      builder: (_, _) => Transform.translate(
        offset: Offset(0, _float.value),
        child: CustomPaint(
          size: const Size(280, 280),
          painter: _AnalyticsPainter(color: widget.color, growFactor: _grow.value),
        ),
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
    final cx = size.width / 2, cy = size.height / 2;
    final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final fill   = Paint()..color = color.withValues(alpha: 0.15)..style = PaintingStyle.fill;
    final fill2  = Paint()..color = color.withValues(alpha: 0.35)..style = PaintingStyle.fill;
    final frame = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 220, height: 185), const Radius.circular(18));
    canvas.drawRRect(frame, fill);
    canvas.drawRRect(frame, stroke..strokeWidth = 2.2);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 110, cy - 92, 220, 28), const Radius.circular(18)), fill2);
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(cx - 90 + i * 14.0, cy - 78), 4, Paint()..color = color.withValues(alpha: 0.6)..style = PaintingStyle.fill);
    }
    final axisP = Paint()..color = color.withValues(alpha: 0.35)..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 88, cy - 52), Offset(cx - 88, cy + 72), axisP);
    canvas.drawLine(Offset(cx - 88, cy + 72), Offset(cx + 88, cy + 72), axisP);
    final barData = [0.42, 0.68, 0.52, 0.85, 0.60, 0.92, 0.74];
    const barW = 16.0, maxH = 100.0;
    final startX = cx - 76.0, baseY = cy + 72.0;
    for (int i = 0; i < barData.length; i++) {
      final h = barData[i] * maxH * growFactor;
      final x = startX + i * 24.0;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - barW / 2, baseY - h, barW, h), const Radius.circular(5)), fill2);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - barW / 2, baseY - h, barW, h), const Radius.circular(5)), stroke..strokeWidth = 1.5);
    }
    final trendPaint = Paint()..color = color.withValues(alpha: 0.85)..strokeWidth = 2.8..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    final trendPath = Path();
    for (int i = 0; i < barData.length; i++) {
      final h = barData[i] * maxH * growFactor;
      final x = startX + i * 24.0;
      final y = baseY - h - 8;
      if (i == 0) { trendPath.moveTo(x, y); }
      else {
        final prevX = startX + (i - 1) * 24.0;
        final prevY = baseY - barData[i - 1] * maxH * growFactor - 8;
        trendPath.cubicTo(prevX + 12, prevY, x - 12, y, x, y);
      }
    }
    canvas.drawPath(trendPath, trendPaint);
    for (int i = 0; i < barData.length; i++) {
      final h = barData[i] * maxH * growFactor;
      final x = startX + i * 24.0;
      final y = baseY - h - 8;
      canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = color..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(x, y), 4.5, stroke..strokeWidth = 1.5);
    }
    canvas.save();
    canvas.translate(cx - 70, cy - 105);
    final c1 = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 72, height: 38), const Radius.circular(12));
    canvas.drawRRect(c1, fill2);
    canvas.drawRRect(c1, stroke..strokeWidth = 1.5);
    final tp1 = TextPainter(text: TextSpan(text: '94%', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr)..layout();
    tp1.paint(canvas, Offset(-tp1.width / 2, -tp1.height / 2 - 4));
    final tp1b = TextPainter(text: TextSpan(text: 'Pass Rate', style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 7, fontWeight: FontWeight.w600)), textDirection: TextDirection.ltr)..layout();
    tp1b.paint(canvas, Offset(-tp1b.width / 2, 6));
    canvas.restore();
    canvas.save();
    canvas.translate(cx + 72, cy - 105);
    final c2 = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 72, height: 38), const Radius.circular(12));
    canvas.drawRRect(c2, fill2);
    canvas.drawRRect(c2, stroke..strokeWidth = 1.5);
    final arrow = Path()..moveTo(0, 8)..lineTo(0, -6)..moveTo(-7, 0)..lineTo(0, -8)..lineTo(7, 0);
    canvas.drawPath(arrow, stroke..strokeWidth = 2.5..color = color);
    final tp2 = TextPainter(text: TextSpan(text: '+12%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)), textDirection: TextDirection.ltr)..layout();
    tp2.paint(canvas, Offset(8, -tp2.height / 2));
    canvas.restore();
    canvas.save();
    canvas.translate(cx + 80, cy + 55);
    for (int r = 1; r <= 3; r++) {
      canvas.drawArc(Rect.fromCenter(center: Offset.zero, width: r * 16.0, height: r * 16.0), 3.14159 + 3.14159 / 4, 3.14159 / 2, false,
          Paint()..color = color.withValues(alpha: 0.5 - r * 0.1)..strokeWidth = 2.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    }
    canvas.drawCircle(Offset.zero, 2.5, Paint()..color = color..style = PaintingStyle.fill);
    canvas.restore();
  }
  @override
  bool shouldRepaint(_AnalyticsPainter old) => old.growFactor != growFactor || old.color != color;
}