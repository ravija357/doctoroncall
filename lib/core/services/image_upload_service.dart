import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ImageUploadService {
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/upload');

      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // must match multer field name
          imageFile.path,
        ),
      );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 10));

      if (streamedResponse.statusCode == 200) {
        final response =
            await http.Response.fromStream(streamedResponse);
        final data = json.decode(response.body);

        // backend returns: { success, message, path }
        return data['path'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
