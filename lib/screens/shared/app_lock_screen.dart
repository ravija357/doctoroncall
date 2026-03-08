import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctoroncall/core/providers/lock_provider.dart';
import 'package:doctoroncall/features/auth/presentation/providers/auth_provider.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  @override
  void initState() {
    super.initState();
    // Auto trigger biometric unlock on load with a small delay to avoid race conditions
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _handleUnlock();
    });
  }

  Future<void> _handleUnlock() async {
    debugPrint('AppLockScreen: Triggering unlock...');
    final success = await ref.read(lockProvider.notifier).unlock();
    debugPrint('AppLockScreen: Unlock result: $success');
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed. Please try again.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Illustration
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/images/app_lock_illustration.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                // Text
                Text(
                  'App Locked',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please authenticate to access your medical dashboard and records securely.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                // Unlock Button
                ElevatedButton.icon(
                  onPressed: _handleUnlock,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Unlock with Biometrics'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    shadowColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    // Fail-safe: if biometric keeps failing, allowed to logout and re-login
                    ref.read(authProvider.notifier).logout();
                  },
                  child: const Text(
                    'Login with Password',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
