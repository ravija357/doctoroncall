import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top right profile avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage:
                        AssetImage('assets/images/doctor_profile.png'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Find Your Doctor',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                'Book an appointment for consultation',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),

              const Text(
                'Browse by Category',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // Category row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _CategoryCard(
                    title: 'WheelChair',
                    icon: Icons.accessible,
                  ),
                  _CategoryCard(
                    title: 'NutrisI',
                    icon: Icons.local_drink,
                  ),
                  _CategoryCard(
                    title: 'Heart',
                    icon: Icons.favorite_border,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Doctor cards
              const _DoctorCard(
                name: 'Dr.Steave Smith',
                degree: 'MBBS, ND-DNB',
                timing: 'Opening Timings: 9:00am - 5:00pm.',
                imageAsset: 'assets/images/doc1.png',
              ),
              const SizedBox(height: 24),
              const _DoctorCard(
                name: 'Dr.Josepin Clara',
                degree: 'MBBS, ND-DNB',
                timing: 'Opening Timings: 9:00am - 5:00pm.',
                imageAsset: 'assets/images/doc2.png',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const _CategoryCard({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 95,
      height: 95,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6AA9D8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 34,
            color: const Color(0xFF6AA9D8),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 14,
              color: Color(0xFF6AA9D8),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final String name;
  final String degree;
  final String timing;
  final String imageAsset;

  const _DoctorCard({
    required this.name,
    required this.degree,
    required this.timing,
    required this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children:[
          CircleAvatar(
            radius: 28,
            backgroundImage: AssetImage(imageAsset),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  degree,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  timing,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                // TODO: handle booking tap
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6AA9D8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Book',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
