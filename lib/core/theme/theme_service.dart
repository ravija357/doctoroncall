import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  Future<void> init() async {
    final box = Hive.box(HiveBoxes.users);
    final userData = box.get('currentUser');
    
    if (userData is Map) {
      final prefs = userData['preferences'] as Map?;
      if (prefs != null) {
        final isDark = prefs['darkMode'] as bool? ?? false;
        themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
      }
    }
  }

  Future<void> updateTheme(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    
    // Also persist locally immediately for speed
    final box = Hive.box(HiveBoxes.users);
    final userData = box.get('currentUser');
    if (userData is Map) {
      final updatedUserMap = Map<String, dynamic>.from(userData);
      final prefs = Map<String, dynamic>.from(userData['preferences'] ?? {});
      prefs['darkMode'] = isDark;
      updatedUserMap['preferences'] = prefs;
      await box.put('currentUser', updatedUserMap);
    }
  }

  bool get isDarkMode => themeMode.value == ThemeMode.dark;
}
