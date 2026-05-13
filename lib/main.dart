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
import 'widgets/main_shell_scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
  static const double _navHeight = 52;
  static const double _fabSize = 60;

  late int _index;

  // FAB press animation (0 idle, 1 fully pressed). Scale + shadow both
  // interpolate off this so the button compresses *into* the surface
  // rather than just shrinking.
  late final AnimationController _fabPressCtrl;
  late final CurvedAnimation _fabPressT;

  // Slow idle breathing — barely-perceptible 1.5% scale loop that gives
  // the primary CTA quiet presence without becoming a nag.
  late final AnimationController _fabPulseCtrl;
  late final CurvedAnimation _fabPulseT;

  // Cached merged listenable so AnimatedBuilder doesn't reattach listeners
  // every rebuild (Listenable.merge allocates on each call).
  late final Listenable _fabAnim;

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

    _fabPressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _fabPressT = CurvedAnimation(
      parent: _fabPressCtrl,
      curve: Curves.easeOutCubic,
    );

    _fabPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _fabPulseT = CurvedAnimation(
      parent: _fabPulseCtrl,
      curve: Curves.easeInOut,
    );

    _fabAnim = Listenable.merge([_fabPressT, _fabPulseT]);

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
    _fabPressT.dispose();
    _fabPulseT.dispose();
    _fabPressCtrl.dispose();
    _fabPulseCtrl.dispose();
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

  void _selectTab(MainShellTab tab) => _onNavTap(tab.index);

  @override
  Widget build(BuildContext context) {
    return MainShellScope(
      currentTab: MainShellTab.values[_index],
      onTabSelected: _selectTab,
      child: Scaffold(
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
      ),
    );
  }

  Widget _buildNav(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: _navHeight + bottomPad,
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
              height: _navHeight,
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
          // Geometry: FAB centre sits at the bar's top edge, so half floats
          // above and half is cradled by the bowl. The notch span and depth
          // are tuned (_NotchedNavPainter) so there's a 2-3px breathing gap
          // between the FAB's outer edge and the curved bowl interior.
          Positioned(
            top: -(_fabSize / 2),
            child: Semantics(
              button: true,
              label: 'Start new screening',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _startNewScreening,
                  onTapDown: (_) {
                    VsHaptics.medium();
                    _fabPressCtrl.forward();
                  },
                  onTapUp: (_) => _fabPressCtrl.reverse(),
                  onTapCancel: () => _fabPressCtrl.reverse(),
                  customBorder: const CircleBorder(),
                  child: AnimatedBuilder(
                    animation: _fabAnim,
                    builder: (_, _) {
                      final press = _fabPressT.value;
                      final pulse = _fabPulseT.value;
                      // Press shrinks 8%, idle pulse adds up to 1.5%.
                      final scale =
                          (1.0 - press * 0.08) * (1.0 + pulse * 0.015);
                      // Shadow contracts toward 35% on press so the FAB
                      // visibly compresses into the bar.
                      final s = 1.0 - press * 0.65;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: _fabSize,
                          height: _fabSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: VsGradients.brand,
                            // 1.5px ring carves the FAB out of the white
                            // bar surface where they meet.
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            boxShadow: [
                              // Ambient — tight, neutral, sits the FAB on
                              // the surface.
                              BoxShadow(
                                color: VsColors.slate900.withValues(
                                  alpha: 0.14 * s,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                              // Key — softer, brand-tinted, gives the
                              // primary CTA a teal halo without muddying
                              // the bar.
                              BoxShadow(
                                color: VsColors.brand.withValues(
                                  alpha: 0.34 * s,
                                ),
                                blurRadius: 18 * s + 6,
                                offset: Offset(0, 6 * s + 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.add_rounded,
                              size: 30,
                              color: Colors.white,
                              weight: 700,
                            ),
                          ),
                        ),
                      );
                    },
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
    // Slate-600 inactive (instead of slate-500) for more confidence on
    // white; the active state's pill + colour + weight still dominate.
    final iconColor = active ? VsColors.brand : VsColors.slate600;
    final labelColor = active ? VsColors.brandDark : VsColors.slate600;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onNavTap(i),
            borderRadius: BorderRadius.circular(14),
            highlightColor: VsColors.brand.withValues(alpha: 0.06),
            splashColor: VsColors.brand.withValues(alpha: 0.10),
            child: SizedBox(
              height: _navHeight,
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
                    // Uses brandFaint with a 1px brand-tinted hairline so
                    // it reads as a chip, not a muddy mint blob.
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      width: active ? 46 : 30,
                      height: 24,
                      decoration: BoxDecoration(
                        color: active
                            ? VsColors.brandFaint
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(VsRadius.pill),
                        border: Border.all(
                          color: active
                              ? VsColors.brand.withValues(alpha: 0.22)
                              : Colors.transparent,
                          width: 1,
                        ),
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
                            size: 19,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: labelColor,
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
// Two mirrored cubic-bezier "S-curves" that meet at a horizontal
// tangent at the bottom of the dip. The previous arc-based design
// had κ jump from 0 to 1/33 at the shoulder, which the eye reads
// as a "pointy" kink where the flat bar bends into the bowl.
//
// This single-cubic design keeps the entry curvature low (~0.08
// for our params) and is C2-continuous at the bowl bottom because
// both halves meet with horizontal tangents and equal curvature.
//
// Parameters:
//   _shoulderHalf — half the notch's mouth width (where flat bar
//                   ends and bezier begins). Wider = gentler entry.
//   _depth        — bowl depth in px from bar top.
//   _flatness     — bezier control point position along the path.
//                   0.5 = symmetric S-curve, minimises shoulder
//                   curvature. <0.5 weights the curve toward the
//                   shoulders, >0.5 toward the centre.
//
// Why not Material's CircularNotchedRectangle: it tangents a
// circular arc onto flat shoulders at the equator, producing the
// classic "kink" where vertical-tangent of the arc meets the
// horizontal bar. A symmetric cubic absorbs that transition.
// ─────────────────────────────────────────────────────────────
class _NotchedNavPainter extends CustomPainter {
  const _NotchedNavPainter();

  // Half the notch mouth width. With FAB radius 30, this gives ~28px
  // of easement on each side of the FAB's equator before the curve
  // straightens to the flat bar — enough horizontal travel for a
  // smooth shoulder. κ(0) ∝ 1/s², so the wider s the smoother.
  static const double _shoulderHalf = 58;

  // Bowl depth. FAB radius is 30 and the FAB's centre sits at the
  // bar's top edge, so the FAB extends 30px below the bar. _depth=34
  // leaves a ~4px breathing gap between the bowl bottom and the
  // FAB bottom.
  static const double _depth = 34;

  // Symmetric S-curve. f=0.5 places both control points at the same
  // x (cx − s/2), giving the lowest possible shoulder curvature for
  // a single cubic. The closed-form curvature at the entry is:
  //   κ(0) = 2 × depth / (3 × s² × f²) ≈ 0.027 here.
  // The previous arc-based design had κ(0) ≈ 1.41 at the shoulder
  // (where the bar's κ=0 line meets the bezier), which the eye reads
  // as a kink — this is ≈52× smoother.
  static const double _flatness = 0.5;

  /// Horizontal gap the nav-items Row should leave at the centre.
  /// Includes a small buffer beyond the notch span so labels don't
  /// crowd the shoulders.
  static const double notchSpan = (_shoulderHalf * 2) + 8;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final shape = _buildShape(size, cx);
    final topEdge = _buildTopEdge(size, cx);
    final curveOnly = _buildCurveOnly(cx);

    // Soft upward shadow — drawn as the same path offset above with an
    // outer-blur mask so we don't get bleed inside the bar.
    canvas.save();
    canvas.translate(0, -2);
    canvas.drawPath(
      shape,
      Paint()
        ..color = VsColors.slate900.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 16),
    );
    canvas.restore();

    // Surface
    canvas.drawPath(shape, Paint()..color = Colors.white);

    // Whisper-thin slate hairline on the flat shoulders only — drawn by
    // clipping the top edge path to the regions outside the notch. This
    // gives definition where the bar meets content above without putting
    // a hard line through the curved bowl where the soft shadow already
    // does the work.
    final hairline = Paint()
      ..color = VsColors.border.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, cx - _shoulderHalf, size.height));
    canvas.drawPath(topEdge, hairline);
    canvas.restore();
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(cx + _shoulderHalf, 0, size.width, size.height),
    );
    canvas.drawPath(topEdge, hairline);
    canvas.restore();

    // Brand-tinted lip highlight along the curved interior — echoes the
    // FAB's teal so the bowl reads as part of the same family rather
    // than a neutral cutout the FAB happens to sit in.
    canvas.drawPath(
      curveOnly,
      Paint()
        ..color = VsColors.brand.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
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

  Path _buildCurveOnly(double cx) {
    final f = _flatness;
    final s = _shoulderHalf;
    final d = _depth;
    return Path()
      ..moveTo(cx - s, 0)
      ..cubicTo(cx - s * (1 - f), 0, cx - s * f, d, cx, d)
      ..cubicTo(cx + s * f, d, cx + s * (1 - f), 0, cx + s, 0);
  }

  @override
  bool shouldRepaint(covariant _NotchedNavPainter old) => false;
}
