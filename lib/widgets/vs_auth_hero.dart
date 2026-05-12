import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import 'vs_logo.dart';
import 'vs_ui.dart';

class VsAuthHero extends StatelessWidget {
  const VsAuthHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.compact = false,
    this.leading,
  });

  final String title;
  final String subtitle;
  final bool compact;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final height = compact
        ? 132.0
        : (screenHeight * 0.42).clamp(280.0, 336.0).toDouble();
    return ClipPath(
      clipper: compact ? null : _AuthHeroClipper(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        width: double.infinity,
        height: height,
        decoration: const BoxDecoration(gradient: VsGradients.hero),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: VsDotPatternPainter(alpha: 0.08)),
            ),
            if (!compact) const Positioned.fill(child: _AuthTargetRings()),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
                child: compact ? _compactContent() : _fullContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactContent() {
    return Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: VsSpace.md)],
        const VsLogo(size: 40, showRing: false),
        const SizedBox(width: VsSpace.sm),
        Text('VisionScreen', style: VsText.title(color: Colors.white)),
      ],
    );
  }

  Widget _fullContent() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: leading ?? const SizedBox(height: 40),
        ),
        const Spacer(),
        const VsLogo(size: 96),
        const SizedBox(height: VsSpace.lg),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Vision',
                style: VsText.display(
                  color: Colors.white,
                ).copyWith(fontSize: 42),
              ),
              TextSpan(
                text: 'Screen',
                style: VsText.display(
                  color: VsColors.brandLight,
                ).copyWith(fontSize: 42),
              ),
            ],
          ),
        ),
        const SizedBox(height: VsSpace.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: VsText.headline(color: Colors.white),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: VsText.body(
            color: Colors.white.withValues(alpha: 0.72),
            w: FontWeight.w500,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _AuthTargetRings extends StatelessWidget {
  const _AuthTargetRings();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AuthTargetPainter());
  }
}

class _AuthTargetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = Colors.white.withValues(alpha: 0.16);

    for (final radius in <double>[72, 118, 164]) {
      canvas.drawCircle(center, radius, paint);
    }

    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.15),
      112,
      paint..color = Colors.white.withValues(alpha: 0.08),
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.92),
      92,
      paint..color = Colors.white.withValues(alpha: 0.07),
    );
  }

  @override
  bool shouldRepaint(_AuthTargetPainter oldDelegate) => false;
}

class _AuthHeroClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 42)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height + 20,
        size.width * 0.62,
        size.height - 18,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height - 44,
        size.width,
        size.height - 12,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(_AuthHeroClipper oldClipper) => false;
}
