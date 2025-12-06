import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
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
              const SizedBox(height: 60),

              const _LabelText('Name'),
              const SizedBox(height: 8),
              _RoundedField(width: size.width * 0.8),
              const SizedBox(height: 24),

              const _LabelText('Email'),
              const SizedBox(height: 8),
              _RoundedField(width: size.width * 0.8),
              const SizedBox(height: 24),

              const _LabelText('Password'),
              const SizedBox(height: 8),
              const _RoundedField(obscure: true),
              const SizedBox(height: 40),

              SizedBox(
                width: size.width * 0.8,
                height: 70,
                child: ElevatedButton(
                  onPressed: () {},
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
      ),
    );
  }
}
class _LabelText extends StatelessWidget {
  final String text;
  const _LabelText(this.text, {super.key});

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

  const _RoundedField({
    this.obscure = false,
    this.width,
    super.key,
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: TextField(
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
