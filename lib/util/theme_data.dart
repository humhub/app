import 'package:flutter/material.dart';

class HumhubTheme {
  // Define your primary color scheme
  static Color primaryColor = const Color(0xFF21a1b3);

  static TextStyle? getHeaderStyle(context) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600);
  }

  static TextStyle paragraphStyle =
      const TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.normal, color: Colors.black, fontSize: 15);

  // Define your custom dialog theme
  static final DialogTheme dialogTheme = DialogTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    backgroundColor: Colors.white,
    titleTextStyle: const TextStyle(
      color: Colors.black,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    contentTextStyle: TextStyle(
      color: Colors.grey[800],
      fontSize: 14,
    ),
  );

  // Define your global theme data
  static ThemeData get data {
    return ThemeData(
      fontFamily: 'OpenSans',
      dialogTheme: dialogTheme,
    );
  }
}
