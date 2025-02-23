import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:humhub/flavored/web_view.f.dart';
import 'package:humhub/util/const.dart';

NavigatorState? get navigator => Keys.navigatorKey.currentState;

class RouterF {
  static String? initRoute = WebViewF.path;
  static dynamic initParams;

  static Map<String, Widget Function(BuildContext)> routes = {
    WebViewF.path: (context) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      return const WebViewF();
    },
  };
}
