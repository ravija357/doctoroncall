import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctoroncall/features/auth/presentation/bloc/auth_event.dart';
import 'package:doctoroncall/features/auth/presentation/bloc/auth_state.dart';
import 'package:doctoroncall/screens/patient/patient_main_screen.dart';
import 'package:doctoroncall/screens/doctor/doctor_main_screen.dart';

class SignupScreen extends StatefulWidget {
  final String? initialRole;
  const SignupScreen({super.key, this.initialRole});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isDoctor = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRole == 'DOCTOR') {
      _isDoctor = true;
    }
  }

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

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    context.read<AuthBloc>().add(
          SignupRequested(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
            role: _isDoctor ? 'DOCTOR' : 'PATIENT',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => state.user.role == 'DOCTOR'
                    ? const DoctorMainScreen()
                    : const PatientMainScreen(),
              ),
              (route) => false,
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6AA9D8)));
          }
          
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              const Text(
                'Doctor On Call',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),

              const _LabelText('First Name'),
              const SizedBox(height: 8),
              _RoundedField(
                width: size.width * 0.8,
                controller: _firstNameController,
              ),
              const SizedBox(height: 20),

              const _LabelText('Last Name'),
              const SizedBox(height: 8),
              _RoundedField(
                width: size.width * 0.8,
                controller: _lastNameController,
              ),
              const SizedBox(height: 20),

              const _LabelText('Email'),
              const SizedBox(height: 8),
              _RoundedField(
                width: size.width * 0.8,
                controller: _emailController,
              ),
              const SizedBox(height: 24),

              const _LabelText('Password'),
              const SizedBox(height: 8),
              _RoundedField(
                obscure: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    const Text(
                      'Register as Doctor',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isDoctor,
                      onChanged: (value) {
                        setState(() {
                          _isDoctor = value;
                        });
                      },
                      activeThumbColor: const Color(0xFF6AA9D8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: size.width * 0.8,
                height: 70,
                child: ElevatedButton(
                  onPressed: _onSignUpPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6AA9D8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
      },
      ),
    );
  }
}

class _LabelText extends StatelessWidget {
  final String text;
  const _LabelText(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  final bool obscure;
  final double? width;
  final TextEditingController? controller;

  const _RoundedField({
    this.obscure = false,
    this.width,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? MediaQuery.of(context).size.width * 0.8,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        style: const TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 18,
        ),
      ),
    );
  }
}
