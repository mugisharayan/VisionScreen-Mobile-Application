import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/referrals_screen.dart';
import 'screens/patients_screen.dart';

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
        '/splash':     (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login':      (_) => const LoginScreen(),
        '/home':       (_) => const MainShell(),
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

class _MainShellState extends State<MainShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  static const _items = [
    {'icon': Icons.home_rounded,       'label': 'Home'},
    {'icon': Icons.people_alt_rounded, 'label': 'Patients'},
    {'icon': Icons.assignment_rounded, 'label': 'Referrals'},
    {'icon': Icons.bar_chart_rounded,  'label': 'Analytics'},
    {'icon': Icons.settings_rounded,   'label': 'Settings'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          PatientsScreen(),
          ReferralsScreen(),
          AnalyticsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEF2F6), width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Row(
        children: _items.asMap().entries.map((e) {
          final active = e.key == _index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _index = e.key),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF0D9488).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      e.value['icon'] as IconData,
                      size: active ? 22 : 20,
                      color: active ? const Color(0xFF0D9488) : const Color(0xFF8FA0B4),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.value['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? const Color(0xFF0D9488) : const Color(0xFF8FA0B4),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: active ? 16 : 0,
                      height: 2,
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
        }).toList(),
      ),
    );
  }
}
