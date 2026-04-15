import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _ring1Ctrl;
  late final AnimationController _ring2Ctrl;
  late final AnimationController _loadCtrl;

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

    _ring1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _ring1Scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _ring1Ctrl, curve: Curves.easeInOut),
    );
    _ring1Opacity = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ring1Ctrl, curve: Curves.easeInOut),
    );

    _ring2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _ring2Scale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _ring2Ctrl, curve: Curves.easeInOut),
    );
    _ring2Opacity = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _ring2Ctrl, curve: Curves.easeInOut),
    );

    _loadCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _loadProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadCtrl, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 300),  () { if (mounted) _entryCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 900),  () { if (mounted) _ring2Ctrl.repeat(reverse: true); });
    Future.delayed(const Duration(milliseconds: 1000), () { if (mounted) _loadCtrl.forward(); });

    Future.delayed(const Duration(milliseconds: 4200), () {
      if (mounted) Navigator.of(context).pushReplacementNamed('/onboarding');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Grid background
          CustomPaint(painter: _GridPainter()),
          // Mesh gradient overlay
          CustomPaint(painter: _MeshPainter()),

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
                      const SizedBox(height: 32),
                      _AppName(),
                      const SizedBox(height: 10),
                      _Tagline(),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                // Loading bar pinned near bottom
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 0, 48, 12),
                  child: _LoadingBar(progress: _loadProgress),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: _LoadingLabel(),
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
// Colour palette
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
// App name
// ─────────────────────────────────────────────────────────────
class _AppName extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.dmSerifDisplay(
          fontSize: 46,
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
        fontSize: 9.5,
        color: AppColors.teal3.withValues(alpha: 0.65),
        letterSpacing: 3.0,
        fontWeight: FontWeight.w400,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Loading label
// ─────────────────────────────────────────────────────────────
class _LoadingLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'LOADING',
      style: GoogleFonts.sora(
        fontSize: 9,
        color: Colors.white.withValues(alpha: 0.35),
        letterSpacing: 3.0,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Eye logo with two pulsing rings
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
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring (ring 2)
          AnimatedBuilder(
            animation: ring2Scale,
            builder: (_, child) => Transform.scale(
              scale: ring2Scale.value,
              child: Opacity(
                opacity: ring2Opacity.value,
                child: child,
              ),
            ),
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.teal,
                  width: 1.5,
                ),
              ),
            ),
          ),

          // Inner ring (ring 1)
          AnimatedBuilder(
            animation: ring1Scale,
            builder: (_, child) => Transform.scale(
              scale: ring1Scale.value,
              child: Opacity(
                opacity: ring1Opacity.value,
                child: child,
              ),
            ),
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.teal2,
                  width: 1.5,
                ),
              ),
            ),
          ),

          // Logo box
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.ink2, AppColors.ink3],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.teal.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.35),
                  blurRadius: 48,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(52, 52),
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
// Eye painter
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
        width: size.width * 0.85,
        height: size.height * 0.50,
      ),
      Paint()
        ..color = AppColors.teal3
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Iris
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.17,
      Paint()
        ..color = AppColors.teal2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Pupil
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.09,
      Paint()..color = AppColors.teal2,
    );

    // White centre dot
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.038,
      Paint()..color = Colors.white,
    );

    // Highlight
    canvas.drawCircle(
      Offset(cx + size.width * 0.045, cy - size.height * 0.045),
      size.width * 0.022,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
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
      builder: (_, __) => Container(
        height: 3,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(99),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.teal3],
              ),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Grid pattern background
// ─────────────────────────────────────────────────────────────
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
// Radial mesh gradient overlay
// ─────────────────────────────────────────────────────────────
class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.6),
          radius: 0.7,
          colors: [
            AppColors.teal.withValues(alpha: 0.22),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.6, 0.4),
          radius: 0.55,
          colors: [
            AppColors.sky.withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
