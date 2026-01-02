import 'package:doctoroncall/features/auth/presentation/pages/role_selection_screen.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final Color _blue = const Color(0xFF6AA9D8);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RoleSelectionScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: const [
                  _OnboardPage(
                    title: 'Welcome to\nDoctor On Call',
                    subtitle: 'Find trusted doctors and\nbook appointments easily.',
                  ),
                  _OnboardPage(
                    title: 'Browse by Category',
                    subtitle: 'Wheelchair, heart, nutrition\nand many more specialties.',
                  ),
                  _OnboardPage(
                    title: 'Book in Minutes',
                    subtitle: 'Choose a doctor, pick a time\nand confirm your visit.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

         
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: _index == i ? 14 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _index == i ? _blue : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _next, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _index == 2 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final String title;
  final String subtitle;

  const _OnboardPage({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          
          Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF6AA9D8).withValues(alpha: 0.05), 
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                size: 90,
                color: Color(0xFF6AA9D8),
              ),
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
