import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──
  late final AnimationController _entryCtrl;
  late final AnimationController _ring1Ctrl;
  late final AnimationController _ring2Ctrl;
  late final AnimationController _loadCtrl;

  // ── Animations ──
  late final Animation<double> _entryScale;
  late final Animation<double> _entryOpacity;
  late final Animation<double> _ring1Scale;
  late final Animation<double> _ring1Opacity;
  late final Animation<double> _ring2Scale;
  late final Animation<double> _ring2Opacity;
  late final Animation<double> _loadProgress;

  @override
  void initState() {
    super.initState();

    // Entry: scale 0.75→1.0 + fade, elasticOut matches CSS cubic-bezier(.34,1.56,.64,1)
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entryScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut),
    );
    _entryOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    // Ring 1 pulse: 3 s loop, scale 1.0→1.06, opacity 0.5→1.0
    _ring1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _ring1Scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _ring1Ctrl, curve: Curves.easeInOut),
    );
    _ring1Opacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ring1Ctrl, curve: Curves.easeInOut),
    );

    // Ring 2 pulse: same but starts 1 s later
    _ring2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _ring2Scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _ring2Ctrl, curve: Curves.easeInOut),
    );
    _ring2Opacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ring2Ctrl, curve: Curves.easeInOut),
    );

    // Loading bar: 0→1.0 over 3 s
    _loadCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _loadProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadCtrl, curve: Curves.easeInOut),
    );

    // Skip button fade-in — removed, splash no longer has buttons

    // ── Timed sequence ──
    Future.delayed(const Duration(milliseconds: 500),  () { if (mounted) _entryCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 1000), () { if (mounted) _ring2Ctrl.repeat(reverse: true); });
    Future.delayed(const Duration(milliseconds: 1200), () { if (mounted) _loadCtrl.forward(); });

    // Auto-navigate to onboarding after 3.8 s
    Future.delayed(const Duration(milliseconds: 3800), () {
      if (mounted) _goToOnboarding();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _ring1Ctrl.dispose();
    _ring2Ctrl.dispose();
    _loadCtrl.dispose();
    super.dispose();
  }

  void _goToOnboarding() {
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          const Positioned.fill(child: _GridPattern()),
          const Positioned.fill(child: _MeshGradient()),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: _entryCtrl,
                  builder: (_, child) => Opacity(
                    opacity: _entryOpacity.value,
                    child: Transform.scale(
                      scale: _entryScale.value,
                      child: child,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _EyeLogo(
                        ring1Scale:   _ring1Scale,
                        ring1Opacity: _ring1Opacity,
                        ring2Scale:   _ring2Scale,
                        ring2Opacity: _ring2Opacity,
                      ),
                      const SizedBox(height: 28),
                      _AppName(),
                      const SizedBox(height: 8),
                      _Tagline(),
                      const SizedBox(height: 60),
                      _LoadingBar(progress: _loadProgress),
                      const SizedBox(height: 10),
                      _LoadingLabel(),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Colour palette — exact match to prototype CSS variables
// ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();
  static const Color ink  = Color(0xFF04091A);
  static const Color ink2 = Color(0xFF0B1530);
  static const Color ink3 = Color(0xFF162040);
  static const Color teal  = Color(0xFF0D9488);
  static const Color teal2 = Color(0xFF14B8A6);
  static const Color teal3 = Color(0xFF5EEAD4);
  static const Color sky   = Color(0xFF38BDF8);
}

// ─────────────────────────────────────────────────────────────
// App name "VisionScreen" with teal accent
// ─────────────────────────────────────────────────────────────
class _AppName extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.dmSerifDisplay(
          fontSize: 44,
          color: Colors.white,
          letterSpacing: -1.5,
        ),
        children: const [
          TextSpan(text: 'Vision'),
          TextSpan(
            text: 'Screen',
            style: TextStyle(color: AppColors.teal3),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tagline
// ─────────────────────────────────────────────────────────────
class _Tagline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'OFFLINE-FIRST · TUMBLING E · COMMUNITY HEALTH',
      style: GoogleFonts.sora(
        fontSize: 9,
        color: AppColors.teal3.withValues(alpha: 0.6),
        letterSpacing: 3.5,
        fontWeight: FontWeight.w400,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LOADING label
// ─────────────────────────────────────────────────────────────
class _LoadingLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'LOADING',
      style: GoogleFonts.sora(
        fontSize: 9,
        color: Colors.white.withValues(alpha: 0.2),
        letterSpacing: 2.5,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Eye logo with two pulsing rings + rounded square icon box
// ─────────────────────────────────────────────────────────────
class _EyeLogo extends StatelessWidget {
  const _EyeLogo({
    required this.ring1Scale,
    required this.ring1Opacity,
    required this.ring2Scale,
    required this.ring2Opacity,
  });

  final Animation<double> ring1Scale;
  final Animation<double> ring1Opacity;
  final Animation<double> ring2Scale;
  final Animation<double> ring2Opacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 135,
      height: 135,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring (ring 2)
          AnimatedBuilder(
            animation: ring2Scale,
            builder: (_, child) => Transform.scale(
              scale: ring2Scale.value,
              child: Opacity(
                opacity: ring2Opacity.value * 0.08,
                child: child,
              ),
            ),
            child: Container(
              width: 135,
              height: 135,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.teal, width: 1),
              ),
            ),
          ),

          // Inner ring (ring 1)
          AnimatedBuilder(
            animation: ring1Scale,
            builder: (_, child) => Transform.scale(
              scale: ring1Scale.value,
              child: Opacity(
                opacity: ring1Opacity.value * 0.15,
                child: child,
              ),
            ),
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.teal, width: 1),
              ),
            ),
          ),

          // Logo box
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.ink2, AppColors.ink3],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.teal.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.25),
                  blurRadius: 40,
                ),
              ],
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(50, 50),
                painter: _EyePainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SVG eye icon replicated as CustomPainter
// ─────────────────────────────────────────────────────────────
class _EyePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Outer ellipse
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width * 0.8,
        height: size.height * 0.48,
      ),
      Paint()
        ..color = AppColors.teal3.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Iris
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.16,
      Paint()
        ..color = AppColors.teal2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Pupil
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.08,
      Paint()..color = AppColors.teal2,
    );

    // White dot
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.036,
      Paint()..color = Colors.white,
    );

    // Highlight
    canvas.drawCircle(
      Offset(cx + size.width * 0.04, cy - size.height * 0.04),
      size.width * 0.02,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// Animated loading bar
// ─────────────────────────────────────────────────────────────
class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.progress});
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, child) => Container(
        width: 140,
        height: 1.5,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.value,
          child: child,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.teal, AppColors.teal3],
          ),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────
// Grid pattern background (32 px grid lines)
// ─────────────────────────────────────────────────────────────
class _GridPattern extends StatelessWidget {
  const _GridPattern();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GridPainter());
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.07)
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

// ─────────────────────────────────────────────────────────────
// Radial mesh gradient overlay (two blobs)
// ─────────────────────────────────────────────────────────────
class _MeshGradient extends StatelessWidget {
  const _MeshGradient();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _MeshPainter());
}

class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Top-left teal blob
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.6),
          radius: 0.7,
          colors: [
            AppColors.teal.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // Bottom-right sky blob
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.6, 0.4),
          radius: 0.55,
          colors: [
            AppColors.sky.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
