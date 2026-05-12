import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/patients_screen.dart';
import 'screens/new_screening_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'utils/app_theme.dart';
import 'utils/page_transitions.dart';
import 'utils/haptics.dart';
import 'widgets/vs_logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Status bar: transparent so the teal header bleeds through
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

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
        '/splash':          (_) => const SplashScreen(),
        '/onboarding':      (_) => const OnboardingScreen(),
        '/login':           (_) => const LoginScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/home':            (_) => const MainShell(),
      },
      // ── Lock text scaling only ─────────────────────────────
      // Prevents accessibility font size from breaking layouts.
      // Flutter's own layout system handles different screen sizes
      // correctly through logical pixels — no manual scaling needed.
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
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
  late final Animation<double>   _fabScale;

  // Nav item tap animation (one per item)
  late final List<AnimationController> _itemCtrls;

  static const _items = [
    _NavItem(Icons.home_rounded,        Icons.home_outlined,        'Home'),
    _NavItem(Icons.people_alt_rounded,  Icons.people_alt_outlined,  'Patients'),
    _NavItem(Icons.bar_chart_rounded,   Icons.bar_chart_outlined,   'Analytics'),
    _NavItem(Icons.settings_rounded,    Icons.settings_outlined,    'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;

    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _fabScale = Tween<double>(begin: 1.0, end: 0.92)
        .animate(CurvedAnimation(parent: _fabCtrl, curve: Curves.easeInOut));

    _itemCtrls = List.generate(
      _items.length,
      (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 200)),
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
      VsPageRoute(builder: (_) =>
          const NewScreeningScreen(startWithNewPatient: true)),
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
          AnalyticsScreen(),
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
          // ── Nav bar background — transparent bottom so scaffold shows through ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                    top: BorderSide(color: VsColors.border, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: VsColors.slate900.withValues(alpha: 0.07),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: 72,
                  child: Row(
                    children: [
                      ..._items.sublist(0, 2).asMap().entries.map((e) =>
                          _buildNavItem(e.key, e.value)),
                      const SizedBox(width: 80),
                      ..._items.sublist(2).asMap().entries.map((e) =>
                          _buildNavItem(e.key + 2, e.value)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── FAB — floats above the bar ──
          Positioned(
            top: -52,
            child: GestureDetector(
              onTapDown: (_) { VsHaptics.medium(); _fabCtrl.forward(); },
              onTapUp: (_) {
                _fabCtrl.reverse();
                _startNewScreening();
              },
              onTapCancel: () => _fabCtrl.reverse(),
              child: AnimatedBuilder(
                animation: _fabScale,
                builder: (_, child) =>
                    Transform.scale(scale: _fabScale.value, child: child),
                child: VsPulsingRings(
                  color: VsColors.brand,
                  size: 120,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: VsColors.brand.withValues(alpha: 0.45),
                          blurRadius: 24,
                          spreadRadius: 3,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: VsColors.brand.withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: VsLogoAnimated(size: 72),
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
    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavTap(i),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _itemCtrls[i],
          builder: (_, child) => Transform.scale(
            scale: 1.0 - _itemCtrls[i].value * 0.08,
            child: child,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 40 : 36,
                height: active ? 32 : 28,
                decoration: BoxDecoration(
                  color: active
                      ? VsColors.brand.withValues(alpha: 0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  active ? item.activeIcon : item.icon,
                  size: active ? 20 : 18,
                  color: active ? VsColors.brand : VsColors.slate400,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? VsColors.brand : VsColors.slate400,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: active ? 20 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  color: VsColors.brand,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
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
