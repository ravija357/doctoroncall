import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctoroncall/features/auth/presentation/providers/auth_provider.dart';
import 'package:doctoroncall/features/auth/presentation/bloc/auth_state.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:doctoroncall/screens/auth/signup_screen.dart';
import 'package:doctoroncall/screens/doctor/doctor_main_screen.dart';
import 'package:doctoroncall/screens/patient/patient_main_screen.dart';
import 'package:doctoroncall/screens/auth/forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? initialRole;
  const LoginScreen({super.key, this.initialRole});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    ref.read(authProvider.notifier).login(email, password);
  }

  Future<void> _onGoogleLoginPressed() async {
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId:
            '909560290491-7kcrj5eim8a1qu8nndbrh5pc48uob64n.apps.googleusercontent.com',
      );
      final account = await googleSignIn.signIn();
      if (account == null) return;

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get Google ID Token');
      }

      await ref.read(authProvider.notifier).googleLogin(idToken);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google Login failed: $e')));
    }
  }

  void _goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignupScreen(initialRole: widget.initialRole),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        final selectedPortal = widget.initialRole?.toUpperCase();
        final userRole = next.user.role.toUpperCase();

        if (selectedPortal != null && userRole != selectedPortal) {
          ref.read(authProvider.notifier).logout();
          final portalLabel = selectedPortal == 'DOCTOR' ? 'Doctor' : 'Patient';
          final accountLabel = userRole == 'DOCTOR' ? 'Doctor' : 'Patient';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This is the $portalLabel portal. Your account is registered as $accountLabel. Please use the correct portal.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              backgroundColor: const Color(0xFFE53935),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => userRole == 'DOCTOR'
                ? const DoctorMainScreen()
                : const PatientMainScreen(),
          ),
        );
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.message,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      }
    });

    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          // ── Ambient Background ──
          Container(
            color: isDark ? const Color(0xFF0A0E12) : const Color(0xFFF8FAFF),
          ),

          // Blobs for mesh effect
          Positioned(
            top: -100,
            right: -50,
            child: _AmbientCircle(
              size: 300,
              color: theme.primaryColor.withValues(alpha: isDark ? 0.3 : 0.2),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: _AmbientCircle(
              size: 400,
              color: Colors.blueAccent.withValues(alpha: isDark ? 0.2 : 0.1),
            ),
          ),

          // Main Content
          SafeArea(
            child: authState is AuthLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.primaryColor,
                      strokeWidth: 5,
                    ),
                  )
                : Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ── Header Area (Logo Integration) ──
                          const SizedBox(height: 40),
                          Hero(
                            tag: 'logo',
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/doctoroncall_logo.png',
                                height: 80,
                                width: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Doctor On Call',
                            style: TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1F24),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Personalized healthcare, simplified.',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 48),

                          // ── Form Area ──
                          _GlassField(
                            controller: _emailController,
                            hint: 'Email Address',
                            icon: Icons.alternate_email_rounded,
                          ),
                          const SizedBox(height: 20),
                          _GlassField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscure: true,
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Login Button ──
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton(
                              onPressed: _onLoginPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: theme.primaryColor.withValues(
                                  alpha: 0.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'CONTINUE WITH',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.black38,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // ── Social Login (Responsive) ──
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 320) {
                                // Stack on ultra-narrow screens
                                return Column(
                                  children: [
                                    _SocialCard(
                                      onTap: _onGoogleLoginPressed,
                                      iconUrl:
                                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                      label: 'Google Account',
                                    ),
                                    const SizedBox(height: 16),
                                    _SocialCard(
                                      onTap: () {},
                                      icon: Icons.apple_rounded,
                                      label: 'Apple ID',
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(
                                    child: _SocialCard(
                                      onTap: _onGoogleLoginPressed,
                                      iconUrl:
                                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                      label: 'Google',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _SocialCard(
                                      onTap: () {},
                                      icon: Icons.apple_rounded,
                                      label: 'Apple',
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 48),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: _goToSignup,
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AmbientCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 20)],
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;

  const _GlassField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.black26,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }
}

class _SocialCard extends StatelessWidget {
  final VoidCallback onTap;
  final String? iconUrl;
  final IconData? icon;
  final String label;

  const _SocialCard({
    required this.onTap,
    this.iconUrl,
    this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white12
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconUrl != null)
              Image.network(iconUrl!, height: 24)
            else if (icon != null)
              Icon(icon, size: 24, color: isDark ? Colors.white : Colors.black),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
