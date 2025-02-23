import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Keys{
  static GlobalKey<ScaffoldMessengerState> scaffoldMessengerStateKey = GlobalKey<ScaffoldMessengerState>();
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

class InternalStorage {
  static String keyHumhubInstance = "humHubInstance";
  static String keyLastInstanceUrl = "humHubLastUrl";
  static  FlutterSecureStorage storage = const FlutterSecureStorage();
}

class Assets {
  static String logo = "assets/images/logo.png";
  static String helpImg = "assets/images/help.png";
  static String openerAnimationForward = "assets/animations/opener_animation.riv";
  static String openerAnimationReverse = "assets/animations/opener_animation_reverse.riv";
}

class HumhubTheme {
  static Color primaryColor = const Color(0xFF21a1b3);

  static TextStyle? getHeaderStyle(context) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600);
  }

  static TextStyle paragraphStyle =
      const TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.normal, color: Colors.black, fontSize: 15);
}

class Urls{
  static String proEdition = 'https://www.humhub.com/de/professional-edition';
}
