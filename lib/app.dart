import 'package:doctoroncall/features/auth/presentation/pages/onboarding_screen.dart';
import 'package:doctoroncall/features/home/presentation/pages/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:doctoroncall/theme_data/theme_data.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'doctoroncall',
      debugShowCheckedModeBanner: false,
      theme: getApplicationTheme(),
      home: const OnboardingScreen(),
    );
  }
}
