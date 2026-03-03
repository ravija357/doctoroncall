import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctoroncall/screens/auth/splash_screen.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFF6AA9D8),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: Image.asset(
                  'assets/images/doctoroncall_logo.png',
                  fit: BoxFit.contain,
                  color: isDark ? Colors.white.withValues(alpha: 0.9) : null,
                  colorBlendMode: isDark ? BlendMode.modulate : null,
                ),
              ),
            ),
            const SizedBox(height: 40),

            const Text(
              "I'm a",
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // Doctor button
            SizedBox(
              width: size.width * 0.7,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SplashScreen(initialRole: 'DOCTOR'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? Theme.of(context).cardColor
                      : Colors.white,
                  foregroundColor: isDark
                      ? Colors.white
                      : const Color(0xFF6AA9D8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Doctor',
                  style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 22),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Patient button
            SizedBox(
              width: size.width * 0.7,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const SplashScreen(initialRole: 'PATIENT'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? Theme.of(context).cardColor
                      : Colors.white,
                  foregroundColor: isDark
                      ? Colors.white
                      : const Color(0xFF6AA9D8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Patient',
                  style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
