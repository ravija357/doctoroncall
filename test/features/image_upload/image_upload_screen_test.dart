import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:doctoroncall/core/services/image_upload_service.dart';
import 'package:doctoroncall/core/constants/api_constants.dart';

void main() {
  group('ImageUploadService Unit Tests', () {
    test('API baseUrl should not be empty', () {
      expect(ApiConstants.baseUrl.isNotEmpty, true);
    });

    test('uploadImage returns null when file does not exist', () async {
      final fakeFile = File('non_existing_file.jpg');

      final result =
          await ImageUploadService.uploadImage(fakeFile);

      expect(result, null);
    });

    test('uploadImage method returns Future<String?>', () {
      final fakeFile = File('fake.jpg');
      final result =
          ImageUploadService.uploadImage(fakeFile);

      expect(result, isA<Future<String?>>());
    });

    test('uploadImage handles exceptions safely', () async {
      try {
        final fakeFile = File('');
        final result =
            await ImageUploadService.uploadImage(fakeFile);
        expect(result, null);
      } catch (e) {
        fail('Exception should be handled internally');
      }
    });

    test('ImageUploadService class exists', () {
      expect(ImageUploadService, isNotNull);
    });
  });
}
