import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// VisionScreen Monochrome Eye Mark
//
// Simplified brand mark:
//   • Optional outer halo ring
//   • Teal outer disc
//   • Light-teal iris core
//   • Deep-teal pupil
//   • Minimal white highlight
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
      child: CustomPaint(painter: _EyeMarkPainter(showRing: showRing)),
    );
  }
}

class VsLogoAnimated extends StatefulWidget {
  const VsLogoAnimated({super.key, this.size = 56});

  final double size;

  @override
  State<VsLogoAnimated> createState() => _VsLogoAnimatedState();
}

class _VsLogoAnimatedState extends State<VsLogoAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.985,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: VsLogo(size: widget.size),
    );
  }
}

class _EyeMarkPainter extends CustomPainter {
  const _EyeMarkPainter({required this.showRing});

  final bool showRing;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final outerRadius = radius * 0.74;
    final irisRadius = outerRadius * 0.63;
    final pupilRadius = outerRadius * 0.29;

    if (showRing) {
      canvas.drawCircle(
        center,
        radius * 0.92,
        Paint()
          ..color = VsColors.brandLight.withValues(alpha: 0.34)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.shortestSide * 0.055,
      );
    }

    canvas.drawCircle(center, outerRadius, Paint()..color = VsColors.brand);

    canvas.drawCircle(center, irisRadius, Paint()..color = VsColors.brandLight);

    canvas.drawCircle(center, pupilRadius, Paint()..color = VsColors.brandDeep);

    canvas.drawCircle(
      Offset(center.dx - outerRadius * 0.18, center.dy - outerRadius * 0.17),
      outerRadius * 0.085,
      Paint()..color = Colors.white.withValues(alpha: 0.94),
    );

    canvas.drawCircle(
      Offset(center.dx + outerRadius * 0.11, center.dy + outerRadius * 0.12),
      outerRadius * 0.035,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_EyeMarkPainter oldDelegate) =>
      oldDelegate.showRing != showRing;
}

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
    final accentColor = color.computeLuminance() > 0.6
        ? VsColors.brandDark
        : VsColors.brandLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(logoSize * 0.28),
            border: Border.all(
              color: color.withValues(alpha: 0.24),
              width: 1.5,
            ),
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
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Screen',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildRing(_r3, widget.size * 0.95),
          _buildRing(_r2, widget.size * 0.74),
          _buildRing(_r1, widget.size * 0.52),
          widget.child,
        ],
      ),
    );
  }

  Widget _buildRing(AnimationController ctrl, double maxSize) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, _) {
        final t = ctrl.value;
        final scale = 0.86 + (t * 0.14);
        final opacity = 0.06 + ((1 - t) * 0.18);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: maxSize,
            height: maxSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withValues(alpha: opacity),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}
