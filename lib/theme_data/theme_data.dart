
import 'package:flutter/material.dart';

ThemeData getApplicationTheme(){
  return ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        // useMaterial3: true,
        fontFamily: "OpenSans Regular",
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle:const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontFamily: 'OpenSans Regular'),
            backgroundColor: Color(0xFF6AA9D8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          )
        ),

        appBarTheme: AppBarThemeData(
          backgroundColor: Colors.red,
        )
      );
}