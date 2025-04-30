import 'package:flutter/material.dart';
import 'colours.dart';

class FlicksTheme {
  static ThemeData redBackgroundTheme() {
    return ThemeData(
      scaffoldBackgroundColor: FlicksColours.Red,
      appBarTheme: const AppBarTheme(
        backgroundColor: FlicksColours.Grey,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      fontFamily: 'Nunito',
      textTheme: TextTheme(
        bodyLarge: const TextStyle(fontWeight: FontWeight.w800),
        titleLarge: const TextStyle(
          fontFamily: 'RubikMonoOne',
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
        headlineMedium: pageHeader(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FlicksColours.Grey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: Colors.grey[600],
          fontFamily: 'Nunito',
        ),
      ),

      // ✅ Custom ElevatedButton style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black, // Text color
          backgroundColor: FlicksColours.Grey, // You can change this if you want a filled color
          side: const BorderSide(color: FlicksColours.Black, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle( fontSize: 20),
          elevation: 0, // Optional: flat look
        ),
      ),

      colorScheme: ColorScheme.fromSwatch().copyWith(
        background: FlicksColours.Red,
      ),
    );
  }

  static TextStyle pageHeader() {
    return const TextStyle(
      fontFamily: 'RubikMonoOne',
      fontSize: 19,
      fontWeight: FontWeight.w500,
      color: FlicksColours.Black,
    );
  }
}



