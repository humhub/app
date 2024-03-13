import 'package:flutter/material.dart';

class StorageKeys {
  static String humhubInstance = "humHubInstance";
  static String lastInstanceUrl = "humHubLastUrl";

}

class Assets {
  static String logo = "assets/images/logo.png";
  static String helpImg = "assets/images/help.png";
  static String openerAnimationForward = "assets/opener_animation.riv";
  static String openerAnimationReverse = "assets/opener_animation_reverse.riv";
}

Color primaryColor = const Color(0xFF21a1b3);

TextStyle? getHeaderStyle(context) {
  return Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600);
}

TextStyle paragraphStyle =
    const TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.normal, color: Colors.black, fontSize: 15);
