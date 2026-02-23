import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctoroncall/features/auth/presentation/bloc/auth_event.dart';
import 'package:doctoroncall/core/utils/image_utils.dart';
import 'package:doctoroncall/screens/auth/splash_screen.dart';

import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:doctoroncall/screens/shared/image_upload_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(HiveBoxes.users);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontFamily: 'PlayfairDisplay')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box box, _) {
          final imageUrl = box.get('profileImage');
          final firstName = box.get('firstName') ?? 'User';
          final lastName = box.get('lastName') ?? '';
          final email = box.get('email') ?? 'No email provided';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF6AA9D8).withValues(alpha: 0.2), width: 4),
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage: ImageUtils.getImageProvider(imageUrl),
                        child: imageUrl == null
                            ? const Icon(Icons.person, size: 70, color: Colors.grey)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ImageUploadScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6AA9D8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '$firstName $lastName',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 40),

                _buildSectionHeader('Account Settings'),
                const SizedBox(height: 12),
                _buildProfileItem(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  subtitle: 'Update your name and basic info',
                ),
                _buildProfileItem(
                  icon: Icons.lock_outline,
                  title: 'Security',
                  subtitle: 'Change password or enable 2FA',
                ),
                _buildProfileItem(
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  subtitle: 'Manage your alerts',
                ),
                const SizedBox(height: 32),

                _buildSectionHeader('More'),
                const SizedBox(height: 12),
                _buildProfileItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get assistance or contact us',
                ),
                _buildProfileItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  isDestructive: true,
                  onTap: () {
                    context.read<AuthBloc>().add(LogoutRequested());
                    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const SplashScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red.withValues(alpha: 0.1) : const Color(0xFF6AA9D8).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isDestructive ? Colors.red : const Color(0xFF6AA9D8)),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}
