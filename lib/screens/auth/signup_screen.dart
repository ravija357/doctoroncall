import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctoroncall/features/auth/presentation/providers/auth_provider.dart';
import 'package:doctoroncall/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:doctoroncall/screens/patient/patient_main_screen.dart';
import 'package:doctoroncall/screens/doctor/doctor_main_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final String? initialRole;
  const SignupScreen({super.key, this.initialRole});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // Role is locked based on which portal was selected — no manual toggle
  late final bool _isDoctor = widget.initialRole?.toUpperCase() == 'DOCTOR';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignUpPressed() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    ref
        .read(authProvider.notifier)
        .signup(
          firstName,
          lastName,
          email,
          password,
          _isDoctor ? 'DOCTOR' : 'PATIENT',
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        final userRole = next.user.role.toUpperCase();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => userRole == 'DOCTOR'
                ? const DoctorMainScreen()
                : const PatientMainScreen(),
          ),
          (route) => false,
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

          Positioned(
            top: -150,
            left: -100,
            child: _AmbientCircle(
              size: 400,
              color: theme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: _AmbientCircle(
              size: 350,
              color: Colors.tealAccent.withValues(alpha: isDark ? 0.15 : 0.1),
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
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
                              height: 60,
                              width: 60,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Join Our Network',
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1F24),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Register as a ${_isDoctor ? "Specialist" : "Patient"}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // ── Form Area ──
                        Row(
                          children: [
                            Expanded(
                              child: _GlassField(
                                controller: _firstNameController,
                                hint: 'First Name',
                                icon: Icons.badge_outlined,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _GlassField(
                                controller: _lastNameController,
                                hint: 'Last Name',
                                icon: Icons.badge_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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

                        const SizedBox(height: 48),

                        // ── Sign Up Button ──
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _onSignUpPressed,
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
                              'Create Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already part of the family? ',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Shared UI Components ──

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
