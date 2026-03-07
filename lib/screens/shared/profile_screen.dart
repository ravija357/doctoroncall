import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/features/auth/presentation/providers/auth_provider.dart';
import 'package:doctoroncall/core/utils/image_utils.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:doctoroncall/screens/shared/image_upload_screen.dart';
import 'package:doctoroncall/core/theme/theme_service.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/core/network/api_client.dart';
import 'package:doctoroncall/core/providers/lock_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isSaving = false;
  bool _isDarkMode = ThemeService().isDarkMode;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final box = Hive.box(HiveBoxes.users);
    final userData = box.get('currentUser');
    if (userData is Map) {
      _firstNameController.text = userData['firstName'] ?? '';
      _lastNameController.text = userData['lastName'] ?? '';
      _phoneController.text = userData['phone'] ?? '';
      _addressController.text = userData['address'] ?? '';
      _bioController.text = userData['bio'] ?? '';

      final prefs = userData['preferences'] as Map?;
      if (prefs != null) {
        _isDarkMode = prefs['darkMode'] as bool? ?? false;
        _notificationsEnabled = prefs['notifications'] as bool? ?? true;
      }
    }
  }

  Future<void> _syncPreferences({bool? dark, bool? notify}) async {
    try {
      final box = Hive.box(HiveBoxes.users);
      final userData = box.get('currentUser');
      if (userData is! Map) return;

      final userId = userData['id'] ?? userData['_id'];
      final apiClient = sl<ApiClient>();

      await apiClient.dio.put(
        '/auth/$userId',
        data: {
          'preferences': {
            'darkMode': dark ?? _isDarkMode,
            'notifications': notify ?? _notificationsEnabled,
          },
        },
      );
    } catch (_) {
      // Removed sync error print
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final box = Hive.box(HiveBoxes.users);
      final userData = box.get('currentUser');
      if (userData is! Map) return;

      final userId = userData['id'] ?? userData['_id'];
      final apiClient = sl<ApiClient>();

      final preferences = {
        'darkMode': _isDarkMode,
        'notifications': _notificationsEnabled,
        'newsletter': false,
      };

      final data = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'bio': _bioController.text,
        'preferences': preferences,
      };

      final response = await apiClient.dio.put('/auth/$userId', data: data);

      if (response.statusCode == 200) {
        // Sync local Hive
        final updatedUserMap = Map<String, dynamic>.from(userData);
        data.forEach((key, value) => updatedUserMap[key] = value);
        await box.put('currentUser', updatedUserMap);

        // Update theme globally
        ThemeService().updateTheme(_isDarkMode);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(HiveBoxes.users);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box box, _) {
          final userData = box.get('currentUser');
          final String? imageUrl = (userData is Map)
              ? userData['profileImage']
              : null;
          final String role = (userData is Map)
              ? userData['role'] ?? 'PATIENT'
              : 'PATIENT';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                _buildHeader(imageUrl, role, isDark),
                const SizedBox(height: 30),
                _buildPersonalInfoSection(isDark),
                const SizedBox(height: 20),
                _buildPreferencesSection(
                  isDark,
                  userData is Map ? userData : {},
                ),
                const SizedBox(height: 20),
                _buildDangerZone(isDark),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomAction(isDark),
    );
  }

  Widget _buildHeader(String? imageUrl, String role, bool isDark) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6AA9D8),
                    const Color(0xFF6AA9D8).withValues(alpha: 0.5),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6AA9D8).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 65,
              backgroundColor: Theme.of(context).cardColor,
              backgroundImage: ImageUtils.getImageProvider(imageUrl),
              child: imageUrl == null
                  ? Icon(Icons.person, size: 70, color: Colors.grey.shade400)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 5,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImageUploadScreen(),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6AA9D8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).cardColor,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: role.toUpperCase() == 'DOCTOR'
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                role.toUpperCase() == 'DOCTOR'
                    ? Icons.verified_user
                    : Icons.person_pin,
                size: 14,
                color: role.toUpperCase() == 'DOCTOR'
                    ? Colors.blue
                    : Colors.teal,
              ),
              const SizedBox(width: 6),
              const Text(
                'ACCOUNT VERIFIED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(bool isDark) {
    return _buildCard(
      isDark,
      title: 'Personal Information',
      icon: Icons.person_outline_rounded,
      children: [
        _buildTextField(
          'First Name',
          _firstNameController,
          Icons.person_outline,
        ),
        _buildTextField('Last Name', _lastNameController, Icons.person_outline),
        _buildTextField(
          'Phone Number',
          _phoneController,
          Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
        ),
        _buildTextField('Address', _addressController, Icons.map_outlined),
        _buildTextField(
          'Bio',
          _bioController,
          Icons.description_outlined,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(bool isDark, Map userData) {
    final prefs = userData['preferences'] as Map?;
    final bool darkMode = prefs?['darkMode'] as bool? ?? _isDarkMode;
    final bool notifyEnabled =
        prefs?['notifications'] as bool? ?? _notificationsEnabled;

    return _buildCard(
      isDark,
      title: 'App Preferences',
      icon: Icons.settings_outlined,
      children: [
        _buildToggleRow(
          'Dark Mode',
          'Optimize interface for low light',
          Icons.dark_mode_outlined,
          darkMode,
          (val) {
            setState(() => _isDarkMode = val);
            ThemeService().updateTheme(val);
            _syncPreferences(dark: val);
          },
        ),
        const Divider(height: 1, indent: 50),
        _buildToggleRow(
          'Push Notifications',
          'Get alerts for messages & appointments',
          Icons.notifications_none_rounded,
          notifyEnabled,
          (val) {
            setState(() => _notificationsEnabled = val);
            _syncPreferences(notify: val);
          },
        ),
      ],
    );
  }

  Widget _buildDangerZone(bool isDark) {
    return _buildCard(
      isDark,
      title: 'Account Security',
      icon: Icons.security_rounded,
      children: [
        _buildToggleRow(
          'Biometric Authentication',
          'Secure app access with Fingerprint/FaceID',
          Icons.fingerprint_rounded,
          ref.watch(lockProvider.notifier).isBiometricEnabled,
          (val) => ref.read(lockProvider.notifier).setBiometricEnabled(val),
        ),
        const Divider(height: 1, indent: 50),
        _buildActionTile('Change Password', Icons.lock_outline_rounded, () {}),
        _buildActionTile(
          'Delete Account',
          Icons.delete_outline_rounded,
          () {},
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildCard(
    bool isDark, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
      ),
      activeTrackColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildActionTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.redAccent : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.redAccent : null,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildBottomAction(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        15,
        20,
        15 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).popUntil((route) => route.isFirst);
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
