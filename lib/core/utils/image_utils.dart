import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctoroncall/core/constants/api_constants.dart';

class ImageUtils {
  static ImageProvider? getImageProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) {
      return CachedNetworkImageProvider(path);
    }
    if (path.startsWith('/uploads') || path.startsWith('uploads')) {
      final formattedPath = path.startsWith('/') ? path : '/$path';
      return CachedNetworkImageProvider('${ApiConstants.baseUrl}$formattedPath');
    }
    return FileImage(File(path));
  }
}
