import 'package:flutter/material.dart';

ThemeData getApplicationTheme({bool isDark = false}) {
  // --- Premium Color Palette ---
  // Using a sophisticated Slate & Indigo palette for a modern clinical feel.
  final primaryColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF70c0fa);
  final secondaryColor = isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED);
  final accentColor = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);
  
  final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
  final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
  
  final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
  final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  return ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    primaryColor: primaryColor,
    secondaryHeaderColor: secondaryColor,
    
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: surfaceColor,
      background: backgroundColor,
      onSurface: textPrimary,
      onBackground: textPrimary,
      onPrimary: Colors.white,
      surfaceVariant: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
    ),

    fontFamily: "Roboto",
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent, // Favor surface-aware app bars
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textPrimary, size: 22),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFamily: 'Roboto',
        color: textPrimary,
        letterSpacing: -0.5,
      ),
    ),

    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32, 
        fontWeight: FontWeight.w800, 
        color: textPrimary, 
        fontFamily: 'Roboto',
        letterSpacing: -1.0,
      ),
      displayMedium: TextStyle(
        fontSize: 28, 
        fontWeight: FontWeight.w700, 
        color: textPrimary, 
        fontFamily: 'Roboto',
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        fontSize: 20, 
        fontWeight: FontWeight.w700, 
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      titleMedium: TextStyle(
        fontSize: 16, 
        fontWeight: FontWeight.w600, 
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16, 
        color: textPrimary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14, 
        color: textSecondary,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.2,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0, // Solid look is more modern
        shadowColor: primaryColor.withOpacity(0.3),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor.withOpacity(0.5), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),

    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), 
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.all(20),
      hintStyle: TextStyle(color: textSecondary.withOpacity(0.5)),
      prefixIconColor: textSecondary,
      suffixIconColor: textSecondary,
    ),

    dividerTheme: DividerThemeData(
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      thickness: 1,
      space: 1,
    ),

    iconTheme: IconThemeData(
      color: primaryColor,
      size: 24,
    ),
  );
}