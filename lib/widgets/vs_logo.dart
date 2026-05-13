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
  const VsLogo({
    super.key,
    this.size = 56,
    this.showRing = true,
    this.onDark = false,
  });

  final double size;
  final bool showRing;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EyeMarkPainter(showRing: showRing, onDark: onDark),
      ),
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
  const _EyeMarkPainter({required this.showRing, required this.onDark});

  final bool showRing;
  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final outerRadius = radius * 0.74;
    final irisRadius = outerRadius * 0.63;
    final pupilRadius = outerRadius * 0.29;
    final ringColor = onDark
        ? Colors.white.withValues(alpha: 0.42)
        : VsColors.brandLight.withValues(alpha: 0.34);
    final outerColor = onDark ? Colors.white : VsColors.brand;
    final irisColor = onDark
        ? VsColors.brandLight.withValues(alpha: 0.98)
        : VsColors.brandLight;
    final highlightColor = onDark
        ? VsColors.brandDeep.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.94);
    final secondaryHighlightColor = onDark
        ? VsColors.brand.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.55);

    if (showRing) {
      canvas.drawCircle(
        center,
        radius * 0.92,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.shortestSide * 0.055,
      );
    }

    canvas.drawCircle(center, outerRadius, Paint()..color = outerColor);

    canvas.drawCircle(center, irisRadius, Paint()..color = irisColor);

    canvas.drawCircle(center, pupilRadius, Paint()..color = VsColors.brandDeep);

    canvas.drawCircle(
      Offset(center.dx - outerRadius * 0.18, center.dy - outerRadius * 0.17),
      outerRadius * 0.085,
      Paint()..color = highlightColor,
    );

    canvas.drawCircle(
      Offset(center.dx + outerRadius * 0.11, center.dy + outerRadius * 0.12),
      outerRadius * 0.035,
      Paint()..color = secondaryHighlightColor,
    );
  }

  @override
  bool shouldRepaint(_EyeMarkPainter oldDelegate) =>
      oldDelegate.showRing != showRing || oldDelegate.onDark != onDark;
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
