import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/hive_boxes.dart';
import '../../core/services/image_upload_service.dart';
import '../../core/di/injection_container.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _selectedImage;
  bool _isUploading = false;
  String? _serverImageUrl;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 25,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _serverImageUrl = null;
        });

        // ✅ OPTIMISTIC UPDATE
        final box = Hive.box(HiveBoxes.users);
        box.put('profileImage', pickedFile.path);

        // --- AUTO UPLOAD ---
        await _uploadImage();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      debugPrint('🚀 Starting upload for: ${_selectedImage!.path}');
      final serverPath = await ImageUploadService.uploadImage(_selectedImage!);
      debugPrint('🏁 Upload finished. Result: $serverPath');

      if (!mounted) return;

      if (serverPath != null) {
        final imageUrl = "${ApiConstants.baseUrl}$serverPath";

        // ✅ SAVE IMAGE URL FOR PROFILE LOGO
        final box = Hive.box(HiveBoxes.users);

        // Update loose key for legacy
        box.put('profileImage', imageUrl);

        // Update the full currentUser map so ProfileScreen reacts instantly
        final userData = box.get('currentUser');
        if (userData is Map) {
          final updatedUser = Map<dynamic, dynamic>.from(userData);
          updatedUser['profileImage'] = imageUrl;
          box.put('currentUser', updatedUser);
        }

        // ✅ PERSIST TO BACKEND (Triggers socket sync for web)
        try {
          await sl<AuthRepository>().updateProfile({'image': serverPath});
          debugPrint('✅ Server profile updated with new image path');
        } catch (e) {
          debugPrint('⚠️ Error persisting image to backend: $e');
        }

        setState(() {
          _serverImageUrl = imageUrl;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image uploaded successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Upload failed. Connection too slow or server error.",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Fatal upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fatal Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Upload Image"),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isDark
                    ? Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ).top
                    : BorderSide.none,
              ),
              elevation: isDark ? 0 : 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _serverImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: _serverImageUrl!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(
                                  color: theme.primaryColor,
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                          )
                        : _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.account_circle,
                            size: 120,
                            color: theme.primaryColor.withValues(alpha: 0.5),
                          ),
                    const SizedBox(height: 16),
                    Text(
                      "Profile Image",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Select image from gallery and upload",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.photo_library),
              label: Text(
                _isUploading ? "Uploading..." : "Choose & Upload Image",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
