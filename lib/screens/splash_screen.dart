import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _blinkCtrl;
  late final AnimationController _loadCtrl;
  late final AnimationController _ring1Ctrl;
  late final AnimationController _ring2Ctrl;

  late final Animation<double> _entryOpacity;
  late final Animation<Offset> _entrySlide;
  late final Animation<double> _textScale;
  late final Animation<double> _blinkOpacity;
  late final Animation<double> _loadProgress;
  late final Animation<double> _ring1Scale;
  late final Animation<double> _ring1Opacity;
  late final Animation<double> _ring2Scale;
  late final Animation<double> _ring2Opacity;

  int _loadingMsgIndex = 0;
  static const _loadingMessages = [
    'Preparing your workspace...',
    'Loading patient records...',
    'Syncing health data...',
    'Almost ready...',
  ];

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _entryOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _entrySlide = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entryCtrl, curve: Curves.easeOutCubic));
    _textScale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.3, 1.0, curve: Curves.elasticOut)));

    _ring1Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _ring1Scale = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _ring1Ctrl, curve: Curves.easeInOut));
    _ring1Opacity = Tween<double>(begin: 0.25, end: 0.6).animate(
        CurvedAnimation(parent: _ring1Ctrl, curve: Curves.easeInOut));

    _ring2Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600));
    _ring2Scale = Tween<double>(begin: 1.0, end: 1.18).animate(
        CurvedAnimation(parent: _ring2Ctrl, curve: Curves.easeInOut));
    _ring2Opacity = Tween<double>(begin: 0.1, end: 0.35).animate(
        CurvedAnimation(parent: _ring2Ctrl, curve: Curves.easeInOut));

    _blinkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _blinkOpacity = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 12.5),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 12.5),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25.0),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 12.5),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 12.5),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25.0),
    ]).animate(_blinkCtrl);

    _loadCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200));
    _loadProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _loadCtrl, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 200),
        () { if (mounted) _entryCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 800),
        () { if (mounted) _ring2Ctrl.repeat(reverse: true); });
    Future.delayed(const Duration(milliseconds: 1100),
        () { if (mounted) _blinkCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 600),
        () { if (mounted) _loadCtrl.forward(); });

    // Rotate loading messages every 900ms
    Future.delayed(const Duration(milliseconds: 900), _rotateMessages);

    Future.delayed(const Duration(milliseconds: 4200), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final remembered = prefs.getBool('remember_me') ?? false;
      final email = prefs.getString('remembered_email') ?? '';
      if (remembered && email.isNotEmpty) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    });
  }

  void _rotateMessages() {
    if (!mounted) return;
    setState(() =>
        _loadingMsgIndex = (_loadingMsgIndex + 1) % _loadingMessages.length);
    Future.delayed(const Duration(milliseconds: 900), _rotateMessages);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _blinkCtrl.dispose();
    _loadCtrl.dispose();
    _ring1Ctrl.dispose();
    _ring2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.authBg,
      body: Column(
        children: [
          ClipPath(
            clipper: _SplashWaveClipper(),
            child: Container(
              width: double.infinity,
              height: size.height * 0.62,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.greenDark, AppColors.green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    // Dot pattern overlay
                    Positioned.fill(
                      child: CustomPaint(
                          painter: _DotPatternPainter()),
                    ),
                    SizedBox.expand(
                      child: SlideTransition(
                      position: _entrySlide,
                      child: FadeTransition(
                        opacity: _entryOpacity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _ring2Scale,
                                builder: (_, child) => Transform.scale(
                                  scale: _ring2Scale.value,
                                  child: Opacity(
                                      opacity: _ring2Opacity.value,
                                      child: child),
                                ),
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _ring1Scale,
                                builder: (_, child) => Transform.scale(
                                  scale: _ring1Scale.value,
                                  child: Opacity(
                                      opacity: _ring1Opacity.value,
                                      child: child),
                                ),
                                child: Container(
                                  width: 144,
                                  height: 144,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withValues(
                                            alpha: 0.7),
                                        width: 1.5),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _blinkOpacity,
                                builder: (_, child) => Opacity(
                                    opacity: _blinkOpacity.value,
                                    child: child),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                        color: Colors.white.withValues(
                                            alpha: 0.5),
                                        width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.15),
                                        blurRadius: 30,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: CustomPaint(
                                      size: Size(56, 56),
                                      painter: _SplashEyePainter(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        AnimatedBuilder(
                          animation: _textScale,
                          builder: (_, child) => Transform.scale(
                            scale: _textScale.value,
                            child: child,
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.nunito(
                                  fontSize: 44, fontWeight: FontWeight.w900),
                              children: const [
                                TextSpan(
                                    text: 'Vision',
                                    style: TextStyle(color: Colors.white)),
                                TextSpan(
                                    text: 'Screen',
                                    style: TextStyle(color: Colors.black)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Offline-first · Tumbling E · Community Health',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 0, 48, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _SplashBadge(Icons.verified_outlined, 'WHO'),
                      SizedBox(width: 10),
                      _SplashBadge(
                          Icons.local_hospital_outlined, 'Uganda MOH'),
                      SizedBox(width: 10),
                      _SplashBadge(Icons.lock_outline_rounded, 'AES-256'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  AnimatedBuilder(
                    animation: _loadProgress,
                    builder: (_, __) => Column(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.borderColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _loadProgress.value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.green,
                                    AppColors.greenDark,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            _loadingMessages[_loadingMsgIndex],
                            key: ValueKey(_loadingMsgIndex),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '© 2025 VisionScreen',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.greenHero,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Text(
                    'v1.0.0',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                    ),
                  ),
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

  // ── Dark theme (kept for other screens) ──
  static const Color ink = Color(0xFF04091A);
  static const Color ink2 = Color(0xFF0B1530);
  static const Color ink3 = Color(0xFF162040);
  static const Color teal = Color(0xFF0D9488);
  static const Color teal2 = Color(0xFF14B8A6);
  static const Color teal3 = Color(0xFF5EEAD4);
  static const Color sky = Color(0xFF38BDF8);

  // ── Green palette ──
  static const Color green = Color(0xFF2ECC71);
  static const Color greenDark = Color(0xFF27AE60);
  static const Color greenDeep = Color(0xFF1A7A3E);
  static const Color greenHero = Color(0xFFEAFFF3);
  static const Color greenHero2 = Color(0xFFC8F5D8);
  static const Color greenForgot = Color(0xFF27AE60);

  // ── Neutral ──
  static const Color authBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF7A8394);
  static const Color borderColor = Color(0xFFD4E9DC);
  static const Color cardShadow = Color(0x2E2ECC71);
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    const radius = 2.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter old) => false;
}

class _SplashWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height - 25);
    path.quadraticBezierTo(
        size.width * 0.75, size.height - 50, size.width, size.height - 15);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_SplashWaveClipper old) => false;
}

class _SplashEyePainter extends CustomPainter {
  const _SplashEyePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width * 0.9,
          height: size.height * 0.52),
      paint,
    );
    canvas.drawCircle(Offset(cx, cy), size.width * 0.18, paint);
    canvas.drawCircle(
        Offset(cx, cy), size.width * 0.09, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(cx, cy),
        size.width * 0.04,
        Paint()..color = AppColors.green);
  }

  @override
  bool shouldRepaint(_SplashEyePainter old) => false;
}

class _SplashBadge extends StatelessWidget {
  const _SplashBadge(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.greenHero,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.greenDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.greenDark,
            ),
          ),
        ],
      ),
    );
  }
}
