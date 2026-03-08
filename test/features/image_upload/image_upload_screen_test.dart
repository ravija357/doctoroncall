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
    test('uploadImage returns Future<String?>', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final file = File('${tempDir.path}/fake_image.jpg')
        ..writeAsBytesSync([0]);

      final result = ImageUploadService.uploadImage(file);
      expect(result, isA<Future<String?>>());

      tempDir.deleteSync(recursive: true);
    });

    // 3️⃣ uploadImage returns null for non-existent file
    test('uploadImage returns null for non-existing file', () async {
      final file = File('non_existing_image.jpg');
      final result = await ImageUploadService.uploadImage(file);

      expect(result, null);
    });

    // 4️⃣ uploadImage handles empty path safely
    test('uploadImage handles empty path safely', () async {
      final file = File('');
      final result = await ImageUploadService.uploadImage(file);
      expect(result, null);
    });

    // 5️⃣ ImageUploadService class exists
    test('ImageUploadService class exists', () {
      expect(ImageUploadService, isNotNull);
    });
  });
}
