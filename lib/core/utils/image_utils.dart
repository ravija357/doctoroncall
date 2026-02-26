import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctoroncall/core/constants/api_constants.dart';

class ImageUtils {
  /// Converts a DiceBear SVG URL to PNG so Flutter's image codec can handle it.
  static String _sanitizeUrl(String url) {
    if (url.contains('dicebear.com') && url.contains('/svg')) {
      return url.replaceFirst('/svg', '/png');
    }
    return url;
  }

  static ImageProvider? getImageProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) {
      return CachedNetworkImageProvider(_sanitizeUrl(path));
    }
    if (path.startsWith('/uploads') || path.startsWith('uploads')) {
      final formattedPath = path.startsWith('/') ? path : '/$path';
      return CachedNetworkImageProvider('${ApiConstants.baseUrl}$formattedPath');
    }
    return FileImage(File(path));
  }

  /// A safer image widget that shows a grey avatar placeholder on any error
  /// instead of propagating codec exceptions up to the Flutter engine.
  static Widget buildAvatar({
    required String? imageUrl,
    required double radius,
    IconData fallbackIcon = Icons.person,
    Color fallbackColor = const Color(0xFF9E9E9E),
  }) {
    final provider = getImageProvider(imageUrl);

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: provider,
      onBackgroundImageError: provider != null
          ? (_, __) {} // silently swallow codec errors
          : null,
      child: provider == null
          ? Icon(fallbackIcon, size: radius, color: fallbackColor)
          : null,
    );
  }
}

