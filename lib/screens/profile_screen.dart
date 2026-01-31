import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/hive_boxes.dart';
import '../features/image_upload/image_upload_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(HiveBoxes.users);

    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: ['profileImage']),
      builder: (context, Box box, _) {
        final imageUrl = box.get('profileImage');

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 20),

            // ✅ PROFILE IMAGE (AUTO-UPDATES AFTER UPLOAD)
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                backgroundImage:
                    imageUrl != null ? NetworkImage(imageUrl) : null,
                child: imageUrl == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            const ListTile(
              leading: Icon(Icons.person),
              title: Text('My Profile'),
              subtitle: Text('View profile information'),
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Update Profile Image'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ImageUploadScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
