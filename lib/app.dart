import 'package:doctoroncall/screen/dashboard_screen.dart';
import 'package:doctoroncall/screen/login_screen.dart';
import 'package:doctoroncall/screen/onboarding_screen.dart';
import 'package:doctoroncall/screen/role_selection_screen.dart';
import 'package:doctoroncall/theme_data/theme_data.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'doctoroncall',
      debugShowCheckedModeBanner: false,
      theme: getApplicationTheme(),
      home: RoleSelectionScreen(),
    );
  }
}
