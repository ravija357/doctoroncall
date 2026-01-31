
import 'package:flutter/material.dart';

ThemeData getApplicationTheme(){
  return ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF6AA9D8)),
        // useMaterial3: true,
        fontFamily: "Roboto",
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle:const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontFamily: 'Roboto'),
            backgroundColor: Color(0xFF6AA9D8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          )
        ),

        appBarTheme: AppBarThemeData(
          backgroundColor: Color(0xFF6AA9D8),
        )
      );
}