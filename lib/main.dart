import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/patients_screen.dart';
import 'screens/new_screening_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'utils/app_theme.dart';
import 'utils/page_transitions.dart';
import 'utils/haptics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Status bar: transparent so the teal header bleeds through
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const VisionScreenApp());
}

class VisionScreenApp extends StatelessWidget {
  const VisionScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VisionScreen',
      debugShowCheckedModeBanner: false,
      theme: VsTheme.light,
      home: const SplashScreen(),
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/home': (_) => const MainShell(),
      },
      // ── Lock text scaling only ─────────────────────────────
      // Prevents accessibility font size from breaking layouts.
      // Flutter's own layout system handles different screen sizes
      // correctly through logical pixels — no manual scaling needed.
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MainShell — bottom nav + FAB
// ─────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});
  final int initialIndex;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  late int _index;

  // FAB press animation
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabScale;

  // Nav item tap animation (one per item)
  late final List<AnimationController> _itemCtrls;

  static const _items = [
    _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavItem(Icons.people_alt_rounded, Icons.people_alt_outlined, 'Patients'),
    _NavItem(Icons.list_alt_rounded, Icons.list_alt_outlined, 'Activity'),
    _NavItem(Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;

    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _fabScale = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _fabCtrl, curve: Curves.easeInOut));

    _itemCtrls = List.generate(
      _items.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    for (final c in _itemCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _onNavTap(int i) {
    if (_index == i) return;
    VsHaptics.selection();
    _itemCtrls[i].forward(from: 0).then((_) => _itemCtrls[i].reverse());
    setState(() => _index = i);
  }

  void _startNewScreening() {
    Navigator.push(
      context,
      VsPageRoute(
        builder: (_) => const NewScreeningScreen(startWithNewPatient: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: VsColors.scaffold,
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          PatientsScreen(),
          ActivityScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildNav(context),
    );
  }

  Widget _buildNav(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: 72 + bottomPad,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── Notched bar surface ──
          // Custom-painted so the notch is a smooth bezier curve, not
          // Material's default tangent-arc CircularNotchedRectangle which
          // looks visibly steep where shoulder meets arc.
          const Positioned.fill(
            child: CustomPaint(painter: _NotchedNavPainter()),
          ),

          // ── Nav items ──
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  ..._items
                      .sublist(0, 2)
                      .asMap()
                      .entries
                      .map((e) => _buildNavItem(e.key, e.value)),
                  const SizedBox(width: _NotchedNavPainter.notchSpan),
                  ..._items
                      .sublist(2)
                      .asMap()
                      .entries
                      .map((e) => _buildNavItem(e.key + 2, e.value)),
                ],
              ),
            ),
          ),

          // ── FAB — nests inside the notch ──
          Positioned(
            top: -40,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _startNewScreening,
                onTapDown: (_) {
                  VsHaptics.medium();
                  _fabCtrl.forward();
                },
                onTapUp: (_) => _fabCtrl.reverse(),
                onTapCancel: () => _fabCtrl.reverse(),
                customBorder: const CircleBorder(),
                child: AnimatedBuilder(
                  animation: _fabScale,
                  builder: (_, child) =>
                      Transform.scale(scale: _fabScale.value, child: child),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VsColors.brand,
                      // Slim 2px ring matches the notch lip thickness so the
                      // FAB reads as nested rather than floating apart.
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: VsColors.brand.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.remove_red_eye_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int i, _NavItem item) {
    final active = _index == i;
    final tint = active ? VsColors.brand : VsColors.slate500;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNavTap(i),
          borderRadius: BorderRadius.circular(14),
          highlightColor: VsColors.brand.withValues(alpha: 0.06),
          splashColor: VsColors.brand.withValues(alpha: 0.10),
          child: SizedBox(
            height: 72,
            child: AnimatedBuilder(
              animation: _itemCtrls[i],
              builder: (_, child) => Transform.scale(
                scale: 1.0 - _itemCtrls[i].value * 0.06,
                child: child,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Active indicator pill — single confident state.
                  // No background when inactive; the pill itself announces
                  // selection, so there's no need for a competing underline.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    width: active ? 56 : 36,
                    height: 32,
                    decoration: BoxDecoration(
                      color: active
                          ? VsColors.brand.withValues(alpha: 0.13)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(VsRadius.pill),
                    ),
                    alignment: Alignment.center,
                    // Subtle upward lift on active so the icon feels "raised"
                    // out of the pill rather than sitting flat in it.
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      offset: active ? const Offset(0, -0.02) : Offset.zero,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(scale: anim, child: child),
                        ),
                        child: Icon(
                          active ? item.activeIcon : item.icon,
                          key: ValueKey<bool>(active),
                          size: 20,
                          color: tint,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: tint,
                      letterSpacing: active ? 0.1 : 0.0,
                    ),
                    child: Text(item.label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.activeIcon, this.icon, this.label);
  final IconData activeIcon;
  final IconData icon;
  final String label;
}

// ─────────────────────────────────────────────────────────────
// Notched nav background
//
// The default Material `CircularNotchedRectangle` joins a circular arc to
// flat shoulders with tangent points — the visible "kink" at that join is
// the steep look we want to avoid. Here we use two mirrored cubic-bezier
// shoulders that meet at a horizontal tangent at the bottom of the dip,
// so the curve is continuous and visually smooth.
//
// Geometry:
//   - Total notch span: 2 * _shoulderHalf
//   - Depth: _depth pixels down from the bar top
//   - _flatness controls how long the curve stays near horizontal at top
//     and bottom of the dip. Higher = flatter shoulders, more "bowl" shape.
// ─────────────────────────────────────────────────────────────
class _NotchedNavPainter extends CustomPainter {
  const _NotchedNavPainter();

  static const double _shoulderHalf = 64;
  static const double _depth = 30;
  static const double _flatness = 0.38;

  /// Horizontal gap the nav-items Row should leave at the centre. Includes a
  /// small buffer beyond the notch span so labels don't crowd the shoulders.
  static const double notchSpan = (_shoulderHalf * 2) + 8;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final shape = _buildShape(size, cx);

    // Soft upward shadow — drawn as the same path offset above with an
    // outer-blur mask so we don't get bleed inside the bar.
    canvas.save();
    canvas.translate(0, -3);
    canvas.drawPath(
      shape,
      Paint()
        ..color = VsColors.slate900.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12),
    );
    canvas.restore();

    // Surface
    canvas.drawPath(shape, Paint()..color = Colors.white);

    // Top hairline — traces just the notched top edge, not the bottom.
    canvas.drawPath(
      _buildTopEdge(size, cx),
      Paint()
        ..color = VsColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  Path _buildShape(Size size, double cx) {
    final f = _flatness;
    final s = _shoulderHalf;
    final d = _depth;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(cx - s, 0)
      ..cubicTo(cx - s * (1 - f), 0, cx - s * f, d, cx, d)
      ..cubicTo(cx + s * f, d, cx + s * (1 - f), 0, cx + s, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  Path _buildTopEdge(Size size, double cx) {
    final f = _flatness;
    final s = _shoulderHalf;
    final d = _depth;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(cx - s, 0)
      ..cubicTo(cx - s * (1 - f), 0, cx - s * f, d, cx, d)
      ..cubicTo(cx + s * f, d, cx + s * (1 - f), 0, cx + s, 0)
      ..lineTo(size.width, 0);
  }

  @override
  bool shouldRepaint(covariant _NotchedNavPainter old) => false;
}
