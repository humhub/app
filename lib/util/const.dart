import 'package:flutter/material.dart';
class Keys{
  static GlobalKey<ScaffoldMessengerState> scaffoldMessengerStateKey = GlobalKey<ScaffoldMessengerState>();
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

class Assets {
  static String logo = "assets/images/logo.png";
  static String settings = "assets/images/icons/settings.svg";
  static String circleCheck = "assets/images/icons/circle-check.svg";
  static String helpImg = "assets/images/help.png";
  static String openerAnimationForward = "assets/animations/opener_animation.riv";
  static String openerAnimationReverse = "assets/animations/opener_animation_reverse.riv";
  static String localeFlag(String locale) => "assets/images/locale/${locale}_locale_flag.svg";
}

class HumhubTheme {

  static TextStyle? getHeaderStyle(context) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600);
  }

  static TextStyle paragraphStyle =
      const TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.normal, color: Colors.black, fontSize: 15);
}

class Urls{
  static String proEdition = 'https://www.humhub.com/de/professional-edition';
}
