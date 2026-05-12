import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Module illustrations — drawn entirely in CustomPainter.
// One unique illustration per module, animated.
// ─────────────────────────────────────────────────────────────

// ── Module 1: Patient Registration ───────────────────────────
// Shows a clipboard with a patient profile form + GPS pin
class Module1Illustration extends StatefulWidget {
  const Module1Illustration({super.key, required this.color});
  final Color color;
  @override
  State<Module1Illustration> createState() => _Module1IllustrationState();
}

class _Module1IllustrationState extends State<Module1Illustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _float = Tween<double>(begin: 0, end: -8)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, _) => Transform.translate(
        offset: Offset(0, _float.value),
        child: CustomPaint(
          size: const Size(double.infinity, 160),
          painter: _Module1Painter(color: widget.color),
        ),
      ),
    );
  }
}

class _Module1Painter extends CustomPainter {
  const _Module1Painter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = color.withValues(alpha: 0.08));

    final p = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round;
    final pf = Paint()..color = color.withValues(alpha: 0.15)..style = PaintingStyle.fill;
    final pf2 = Paint()..color = color.withValues(alpha: 0.35)..style = PaintingStyle.fill;

    // Clipboard body
    final clipRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 10, cy + 5), width: 110, height: 130),
        const Radius.circular(10));
    canvas.drawRRect(clipRect, pf);
    canvas.drawRRect(clipRect, p);

    // Clipboard top clip
    final topClip = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 10, cy - 58), width: 40, height: 14),
        const Radius.circular(7));
    canvas.drawRRect(topClip, pf2);
    canvas.drawRRect(topClip, p);

    // Avatar circle on clipboard
    canvas.drawCircle(Offset(cx - 10, cy - 22), 18, pf2);
    canvas.drawCircle(Offset(cx - 10, cy - 22), 18, p);

    // Face
    canvas.drawCircle(Offset(cx - 17, cy - 25), 2.5,
        Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx - 3, cy - 25), 2.5,
        Paint()..color = color..style = PaintingStyle.fill);
    final smile = Path()
      ..moveTo(cx - 17, cy - 15)
      ..quadraticBezierTo(cx - 10, cy - 9, cx - 3, cy - 15);
    canvas.drawPath(smile, p..strokeWidth = 1.8);

    // Form lines
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final y = cy + 8 + i * 14.0;
      final w = i == 0 ? 70.0 : i == 2 ? 50.0 : 60.0;
      canvas.drawLine(Offset(cx - 45, y), Offset(cx - 45 + w, y), linePaint);
    }

    // GPS pin floating top-right
    final pinX = cx + 55.0;
    final pinY = cy - 45.0;
    final pinPath = Path()
      ..moveTo(pinX, pinY + 22)
      ..cubicTo(pinX - 14, pinY + 8, pinX - 14, pinY - 10, pinX, pinY - 10)
      ..cubicTo(pinX + 14, pinY - 10, pinX + 14, pinY + 8, pinX, pinY + 22)
      ..close();
    canvas.drawPath(pinPath, pf2);
    canvas.drawPath(pinPath, p..strokeWidth = 2.0);
    canvas.drawCircle(Offset(pinX, pinY + 4), 5,
        Paint()..color = color..style = PaintingStyle.fill);

    // Pulse rings around pin
    for (int i = 1; i <= 2; i++) {
      canvas.drawCircle(Offset(pinX, pinY + 4), 5.0 + i * 8,
          Paint()
            ..color = color.withValues(alpha: 0.15 / i)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_Module1Painter old) => old.color != color;
}

// ── Module 2: Vision Testing ──────────────────────────────────
// Shows the Tumbling E chart with a measuring eye + scan line
class Module2Illustration extends StatefulWidget {
  const Module2Illustration({super.key, required this.color});
  final Color color;
  @override
  State<Module2Illustration> createState() => _Module2IllustrationState();
}

class _Module2IllustrationState extends State<Module2Illustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scan;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _scan = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scan,
      builder: (_, _) => CustomPaint(
        size: const Size(double.infinity, 160),
        painter: _Module2Painter(color: widget.color, scanProgress: _scan.value),
      ),
    );
  }
}

class _Module2Painter extends CustomPainter {
  const _Module2Painter({required this.color, required this.scanProgress});
  final Color color;
  final double scanProgress;

  void _drawE(Canvas canvas, Offset center, double size, double rotation, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final u = size / 5;
    final path = Path()
      ..addRect(Rect.fromLTWH(-size / 2, -size / 2, u, size))
      ..addRect(Rect.fromLTWH(-size / 2, -size / 2, size, u))
      ..addRect(Rect.fromLTWH(-size / 2, -u / 2, size * 0.8, u))
      ..addRect(Rect.fromLTWH(-size / 2, size / 2 - u, size, u));
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = color.withValues(alpha: 0.08));

    final pf = Paint()..color = color..style = PaintingStyle.fill;
    final pStroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.0;

    // Chart frame
    final frame = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 15, cy), width: 120, height: 140),
        const Radius.circular(10));
    canvas.drawRRect(frame, Paint()..color = color.withValues(alpha: 0.12)..style = PaintingStyle.fill);
    canvas.drawRRect(frame, pStroke);

    // E rows
    final rows = [
      (cy - 52.0, 28.0, 0.0),
      (cy - 28.0, 20.0, pi / 2),
      (cy - 8.0,  15.0, pi),
      (cy + 8.0,  12.0, 3 * pi / 2),
      (cy + 22.0, 9.0,  0.0),
      (cy + 34.0, 7.0,  pi / 2),
    ];
    for (final (y, eSize, rot) in rows) {
      _drawE(canvas, Offset(cx - 15, y), eSize, rot, pf);
    }

    // Scan line
    final scanY = (cy - 60) + (120 * scanProgress);
    canvas.drawLine(
        Offset(cx - 75, scanY), Offset(cx + 45, scanY),
        Paint()..color = color.withValues(alpha: 0.6)..strokeWidth = 1.5);

    // Eye illustration (right side)
    final eyeCx = cx + 52.0;
    final eyeCy = cy - 10.0;
    final eyePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final eyePath = Path()
      ..moveTo(eyeCx - 28, eyeCy)
      ..cubicTo(eyeCx - 14, eyeCy - 16, eyeCx + 14, eyeCy - 16, eyeCx + 28, eyeCy)
      ..cubicTo(eyeCx + 14, eyeCy + 16, eyeCx - 14, eyeCy + 16, eyeCx - 28, eyeCy)
      ..close();
    canvas.drawPath(eyePath, Paint()..color = color.withValues(alpha: 0.15)..style = PaintingStyle.fill);
    canvas.drawPath(eyePath, eyePaint);
    canvas.drawCircle(Offset(eyeCx, eyeCy), 10, eyePaint);
    canvas.drawCircle(Offset(eyeCx, eyeCy), 5,
        Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(eyeCx + 3, eyeCy - 3), 2,
        Paint()..color = Colors.white.withValues(alpha: 0.8)..style = PaintingStyle.fill);

    // Distance arrow
    canvas.drawLine(Offset(cx + 30, cy + 50), Offset(cx + 70, cy + 50),
        Paint()..color = color.withValues(alpha: 0.5)..strokeWidth = 1.5..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(cx + 64, cy + 44), Offset(cx + 70, cy + 50),
        Paint()..color = color.withValues(alpha: 0.5)..strokeWidth = 1.5..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(cx + 64, cy + 56), Offset(cx + 70, cy + 50),
        Paint()..color = color.withValues(alpha: 0.5)..strokeWidth = 1.5..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_Module2Painter old) =>
      old.color != color || old.scanProgress != scanProgress;
}

// ── Module 3: Bulk Mode & Campaigns ──────────────────────────
// Shows a group of people with a campaign banner + checkmarks
class Module3Illustration extends StatefulWidget {
  const Module3Illustration({super.key, required this.color});
  final Color color;
  @override
  State<Module3Illustration> createState() => _Module3IllustrationState();
}

class _Module3IllustrationState extends State<Module3Illustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => Transform.scale(
        scale: _pulse.value,
        child: CustomPaint(
          size: const Size(double.infinity, 160),
          painter: _Module3Painter(color: widget.color),
        ),
      ),
    );
  }
}

class _Module3Painter extends CustomPainter {
  const _Module3Painter({required this.color});
  final Color color;

  void _drawPerson(Canvas canvas, double cx, double cy, double scale, Color c) {
    final p = Paint()..color = c..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final pf = Paint()..color = c.withValues(alpha: 0.3)..style = PaintingStyle.fill;
    // Head
    canvas.drawCircle(Offset(cx, cy - 18 * scale), 9 * scale, pf);
    canvas.drawCircle(Offset(cx, cy - 18 * scale), 9 * scale, p);
    // Body
    final body = Path()
      ..moveTo(cx - 10 * scale, cy - 5 * scale)
      ..cubicTo(cx - 12 * scale, cy + 15 * scale, cx - 10 * scale, cy + 30 * scale, cx - 8 * scale, cy + 40 * scale)
      ..lineTo(cx + 8 * scale, cy + 40 * scale)
      ..cubicTo(cx + 10 * scale, cy + 30 * scale, cx + 12 * scale, cy + 15 * scale, cx + 10 * scale, cy - 5 * scale)
      ..close();
    canvas.drawPath(body, pf);
    canvas.drawPath(body, p);
    // Arms
    canvas.drawLine(Offset(cx - 10 * scale, cy + 5 * scale),
        Offset(cx - 22 * scale, cy + 18 * scale), p);
    canvas.drawLine(Offset(cx + 10 * scale, cy + 5 * scale),
        Offset(cx + 22 * scale, cy + 18 * scale), p);
    // Legs
    canvas.drawLine(Offset(cx - 5 * scale, cy + 40 * scale),
        Offset(cx - 8 * scale, cy + 58 * scale), p);
    canvas.drawLine(Offset(cx + 5 * scale, cy + 40 * scale),
        Offset(cx + 8 * scale, cy + 58 * scale), p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = color.withValues(alpha: 0.08));

    // Campaign banner
    final bannerRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 45), width: 200, height: 32),
        const Radius.circular(8));
    canvas.drawRRect(bannerRect,
        Paint()..color = color.withValues(alpha: 0.2)..style = PaintingStyle.fill);
    canvas.drawRRect(bannerRect,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Banner text lines
    final lp = Paint()..color = color.withValues(alpha: 0.6)..strokeWidth = 2.0..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 70, cy - 47), Offset(cx - 20, cy - 47), lp);
    canvas.drawLine(Offset(cx - 70, cy - 41), Offset(cx + 10, cy - 41), lp);

    // Checkmark on banner
    final checkPath = Path()
      ..moveTo(cx + 50, cy - 50)
      ..lineTo(cx + 58, cy - 42)
      ..lineTo(cx + 72, cy - 58);
    canvas.drawPath(checkPath,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

    // 3 people
    _drawPerson(canvas, cx - 55, cy + 10, 0.75, color);
    _drawPerson(canvas, cx, cy, 0.9, color);
    _drawPerson(canvas, cx + 55, cy + 10, 0.75, color);

    // Checkmarks above outer people
    for (final x in [cx - 55.0, cx + 55.0]) {
      final cp = Path()
        ..moveTo(x - 8, cy - 42)
        ..lineTo(x - 2, cy - 36)
        ..lineTo(x + 10, cy - 50);
      canvas.drawPath(cp,
          Paint()..color = color.withValues(alpha: 0.7)..style = PaintingStyle.stroke
            ..strokeWidth = 2.0..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(_Module3Painter old) => old.color != color;
}

// ── Module 4: Referrals & Follow-Up ──────────────────────────
// Shows a referral letter with an arrow + appointment calendar
class Module4Illustration extends StatefulWidget {
  const Module4Illustration({super.key, required this.color});
  final Color color;
  @override
  State<Module4Illustration> createState() => _Module4IllustrationState();
}

class _Module4IllustrationState extends State<Module4Illustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _arrow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _arrow = Tween<double>(begin: 0, end: 12)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _arrow,
      builder: (_, _) => CustomPaint(
        size: const Size(double.infinity, 160),
        painter: _Module4Painter(color: widget.color, arrowOffset: _arrow.value),
      ),
    );
  }
}

class _Module4Painter extends CustomPainter {
  const _Module4Painter({required this.color, required this.arrowOffset});
  final Color color;
  final double arrowOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = color.withValues(alpha: 0.08));

    final p = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round;
    final pf = Paint()..color = color.withValues(alpha: 0.15)..style = PaintingStyle.fill;
    final pf2 = Paint()..color = color.withValues(alpha: 0.35)..style = PaintingStyle.fill;

    // Referral letter (left)
    final letterRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 55, cy), width: 90, height: 110),
        const Radius.circular(8));
    canvas.drawRRect(letterRect, pf);
    canvas.drawRRect(letterRect, p);

    // Letter header
    final headerRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 100, cy - 55, 90, 22),
        const Radius.circular(6));
    canvas.drawRRect(headerRect, pf2);

    // Letter lines
    final lp = Paint()..color = color.withValues(alpha: 0.5)..strokeWidth = 1.8..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final y = cy - 22 + i * 14.0;
      final w = i == 0 ? 60.0 : i == 2 ? 45.0 : 55.0;
      canvas.drawLine(Offset(cx - 95, y), Offset(cx - 95 + w, y), lp);
    }

    // Eye icon on letter
    final eyeP = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeCap = StrokeCap.round;
    final eyePath = Path()
      ..moveTo(cx - 65, cy + 30)
      ..cubicTo(cx - 55, cy + 22, cx - 45, cy + 22, cx - 35, cy + 30)
      ..cubicTo(cx - 45, cy + 38, cx - 55, cy + 38, cx - 65, cy + 30)
      ..close();
    canvas.drawPath(eyePath, Paint()..color = color.withValues(alpha: 0.15)..style = PaintingStyle.fill);
    canvas.drawPath(eyePath, eyeP);
    canvas.drawCircle(Offset(cx - 50, cy + 30), 4, Paint()..color = color..style = PaintingStyle.fill);

    // Animated arrow
    final arrowX = cx - 5 + arrowOffset;
    canvas.drawLine(Offset(arrowX - 15, cy), Offset(arrowX + 15, cy),
        Paint()..color = color..strokeWidth = 2.5..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(arrowX + 8, cy - 7), Offset(arrowX + 15, cy),
        Paint()..color = color..strokeWidth = 2.5..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(arrowX + 8, cy + 7), Offset(arrowX + 15, cy),
        Paint()..color = color..strokeWidth = 2.5..strokeCap = StrokeCap.round);

    // Calendar (right)
    final calRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 55, cy + 5), width: 80, height: 90),
        const Radius.circular(8));
    canvas.drawRRect(calRect, pf);
    canvas.drawRRect(calRect, p);

    // Calendar header
    final calHeader = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 15, cy - 40, 80, 22),
        const Radius.circular(6));
    canvas.drawRRect(calHeader, pf2);

    // Calendar grid
    final dotPaint = Paint()..color = color.withValues(alpha: 0.5)..style = PaintingStyle.fill;
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 4; col++) {
        final dx = cx + 22 + col * 17.0;
        final dy = cy - 8 + row * 16.0;
        canvas.drawCircle(Offset(dx, dy), 3.5, dotPaint);
      }
    }

    // Highlighted date
    canvas.drawCircle(Offset(cx + 56, cy + 8), 8,
        Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx + 56, cy + 8), 8,
        Paint()..color = Colors.white.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Bell notification
    final bellX = cx + 80.0;
    final bellY = cy - 50.0;
    canvas.drawCircle(Offset(bellX, bellY), 12,
        Paint()..color = color.withValues(alpha: 0.2)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(bellX, bellY), 12, p..strokeWidth = 1.5);
    canvas.drawLine(Offset(bellX - 5, bellY - 3), Offset(bellX - 5, bellY + 3),
        Paint()..color = color..strokeWidth = 2.0..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(bellX, bellY - 5), Offset(bellX, bellY + 3),
        Paint()..color = color..strokeWidth = 2.0..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(bellX + 5, bellY - 3), Offset(bellX + 5, bellY + 3),
        Paint()..color = color..strokeWidth = 2.0..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_Module4Painter old) =>
      old.color != color || old.arrowOffset != arrowOffset;
}
