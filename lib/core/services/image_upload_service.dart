import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class ImageUploadService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 2),
    receiveTimeout: const Duration(seconds: 2),
    sendTimeout: const Duration(seconds: 2),
  ));

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last;
      
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/upload',
        data: formData,
      ); // Dio timeouts (sendTimeout, receiveTimeout) will handle the limit

      if (response.statusCode == 200) {
        return response.data['path'];
      }
      return null;
    } on DioException catch (e) {
      debugPrint('Dio Upload Error: ${e.type} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected Upload Error: $e');
      return null;
    }
  }
}
