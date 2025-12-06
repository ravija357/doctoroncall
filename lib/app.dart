import 'package:doctoroncall/screen/login_screen.dart';
import 'package:doctoroncall/screen/onboarding_screen.dart';
import 'package:doctoroncall/screen/role_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:doctoroncall/screen/signup_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OnboardingScreen(),
    );
  }
}
