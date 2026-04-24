import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/patients_screen.dart';
import 'screens/new_screening_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    GoogleFonts.pendingFonts([
      GoogleFonts.sora(),
      GoogleFonts.dmSerifDisplay(),
      GoogleFonts.ibmPlexSans(),
      GoogleFonts.barlow(),
      GoogleFonts.plusJakartaSans(),
      GoogleFonts.inter(),
      GoogleFonts.spaceGrotesk(),
    ]),
  ]);
  runApp(const VisionScreenApp());
}

class VisionScreenApp extends StatelessWidget {
  const VisionScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VisionScreen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.soraTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8FAFB),
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const MainShell(),
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class BottomNavClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const radius = 40.0;
    const notchHeight = 40.0;

    // Start from bottom left
    path.lineTo(0, 0);

    // Top left arc
    path.arcToPoint(
      Offset(size.width / 2 - radius, 0),
      radius: const Radius.circular(0),
      largeArc: false,
      clockwise: true,
    );

    // Left curve of notch - goes up
    path.arcToPoint(
      Offset(size.width / 2, notchHeight),
      radius: Radius.circular(radius),
      largeArc: false,
      clockwise: false,
    );

    // Right curve of notch - comes back down
    path.arcToPoint(
      Offset(size.width / 2 + radius, 0),
      radius: Radius.circular(radius),
      largeArc: false,
      clockwise: false,
    );

    // Top right line
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(BottomNavClipper oldClipper) => false;
}

class _MainShellState extends State<MainShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  static const _items = [
    {'icon': Icons.home_rounded, 'label': 'Home'},
    {'icon': Icons.people_alt_rounded, 'label': 'Patients'},
    {'icon': Icons.bar_chart_rounded, 'label': 'Analytics'},
    {'icon': Icons.settings_rounded, 'label': 'Settings'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF8FAFB),
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          PatientsScreen(),
          AnalyticsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    final firstItems = _items.sublist(0, 2);
    final lastItems = _items.sublist(2);

    return SizedBox(
      height: 82,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Bottom nav bar background with curved cutout
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 62,
            child: ClipPath(
              clipper: BottomNavClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ...firstItems.asMap().entries.map((e) {
                      final active = e.key == _index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _index = e.key),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF0D9488).withOpacity(0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  e.value['icon'] as IconData,
                                  size: active ? 20 : 18,
                                  color: active
                                      ? const Color(0xFF0D9488)
                                      : const Color(0xFF8FA0B4),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  e.value['label'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: active ? 9.5 : 9,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: active
                                        ? const Color(0xFF0D9488)
                                        : const Color(0xFF8FA0B4),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (active)
                                  Container(
                                    width: 18,
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 58),
                    ...lastItems.asMap().entries.map((e) {
                      final index = e.key + 2;
                      final active = index == _index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _index = index),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF0D9488).withOpacity(0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  e.value['icon'] as IconData,
                                  size: active ? 20 : 18,
                                  color: active
                                      ? const Color(0xFF0D9488)
                                      : const Color(0xFF8FA0B4),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  e.value['label'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: active ? 9.5 : 9,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: active
                                        ? const Color(0xFF0D9488)
                                        : const Color(0xFF8FA0B4),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (active)
                                  Container(
                                    width: 18,
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          // Large eye icon button with glow ring
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: _startNewScreening,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withOpacity(0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                    ),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.remove_red_eye_rounded,
                      size: 38,
                      color: Colors.white,
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

  void _startNewScreening() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const NewScreeningScreen(startWithNewPatient: true),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}
