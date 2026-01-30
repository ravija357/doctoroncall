import 'dart:io';
import 'package:http/http.dart' as http;

class ImageUploadService {
  static Future<bool> uploadImage(File imageFile) async {
    final uri = Uri.parse("http://YOUR_SERVER_IP:5000/upload");

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ),
    );

    final response = await request.send();
    return response.statusCode == 200;
  }
}
