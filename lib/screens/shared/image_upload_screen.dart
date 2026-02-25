import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/hive_boxes.dart';
import '../../core/services/image_upload_service.dart';

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

        setState(() {
          _serverImageUrl = imageUrl;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image uploaded successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Upload failed. Connection too slow or server error."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Fatal upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fatal Error: $e"), backgroundColor: Colors.red),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Image"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _serverImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: _serverImageUrl!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            ),
                          )
                        : _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
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
                                color: theme.colorScheme.primary,
                              ),
                    const SizedBox(height: 12),
                    Text(
                      "Profile Image",
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Select image from gallery and upload",
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickImage,
              icon: _isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.photo_library),
              label: Text(_isUploading ? "Uploading..." : "Choose & Upload Image"),
            ),
          ],
        ),
      ),
    );
  }
}
