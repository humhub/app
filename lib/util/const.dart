import 'package:flutter/material.dart';

class StorageKeys {
  static String humhubInstance = "humHubInstance";
  static String lastInstanceUrl = "humHubLastUrl";
}

class Assets {
  static String helpImg = "assets/images/help.png";
}

Color primaryColor = const Color(0xFF21a1b3);

TextStyle? getHeaderStyle(context) {
  return Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600);
}

TextStyle paragraphStyle =
    const TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.normal, color: Colors.black, fontSize: 15);
