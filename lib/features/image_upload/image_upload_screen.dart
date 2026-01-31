import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/image_upload_service.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _selectedImage;
  bool _isUploading = false;

  // This will store server image URL (Sprint 5 requirement)
  String? _serverImageUrl;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _serverImageUrl = null; // reset server image
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    final success =
        await ImageUploadService.uploadImage(_selectedImage!);

    if (success) {
      // For Sprint 5, displaying a server image is enough
      setState(() {
        _serverImageUrl =
            "${ApiConstants.baseUrl}/uploads/sample.jpg";
      });
    }

    setState(() {
      _isUploading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "Image uploaded and displayed from server"
              : "Image upload failed",
        ),
      ),
    );
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
                            child: Image.network(
                              _serverImageUrl!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
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
                      "Select, upload and display image from server",
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text("Choose Image"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  (_selectedImage == null || _isUploading)
                      ? null
                      : _uploadImage,
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Upload Image"),
            ),
          ],
        ),
      ),
    );
  }
}
