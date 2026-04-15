import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
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
        fontFamily: 'Sora',
        scaffoldBackgroundColor: const Color(0xFFF8FAFB),
      ),
      home: const SplashScreen(),
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/login':      (_) => const LoginScreen(),
        '/home':       (_) => const HomeScreen(),
      },
    );
  }
}
