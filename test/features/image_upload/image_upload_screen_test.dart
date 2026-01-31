import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:doctoroncall/core/services/image_upload_service.dart';
import 'package:doctoroncall/core/constants/api_constants.dart';

void main() {
  group('ImageUploadService Unit Tests', () {
    // 1️⃣ API baseUrl should not be empty
    test('API baseUrl should not be empty', () {
      expect(ApiConstants.baseUrl.isNotEmpty, true);
    });

    // 2️⃣ uploadImage returns Future<String?>
    test('uploadImage returns Future<String?>', () {
      final file = File('fake_image.jpg');
      final result = ImageUploadService.uploadImage(file);

      expect(result, isA<Future<String?>>());
    });

    // 3️⃣ uploadImage returns null for invalid file
    test('uploadImage returns null for invalid file', () async {
      final file = File('non_existing_image.jpg');
      final result = await ImageUploadService.uploadImage(file);

      expect(result, null);
    });

    // 4️⃣ uploadImage handles exceptions safely
    test('uploadImage handles exceptions safely', () async {
      try {
        final file = File('');
        final result = await ImageUploadService.uploadImage(file);
        expect(result, null);
      } catch (e) {
        fail('Exception should be handled internally');
      }
    });

    // 5️⃣ ImageUploadService class exists
    test('ImageUploadService class exists', () {
      expect(ImageUploadService, isNotNull);
    });
  });
}
