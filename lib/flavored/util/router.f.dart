import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:humhub/pages/bootstrap_route.dart';
import 'package:humhub/pages/auth_web_view.dart';
import 'package:humhub/flavored/web_view.f.dart';
import 'package:humhub/util/const.dart';

NavigatorState? get navigator => Keys.navigatorKey.currentState;

class RouterF {
  static String? initRoute = WebViewF.path;
  static dynamic initParams;

  static Map<String, Widget Function(BuildContext)> routes = {
    '/': (context) {
      return BootstrapRoute(
        targetRoute: initRoute ?? WebViewF.path,
        arguments: initParams,
      );
    },
    WebViewF.path: (context) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      return const WebViewF();
    },
    AuthWebView.path: (context) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      return const AuthWebView();
    },
  };
}
