import 'package:flutter/cupertino.dart';
import 'package:humhub/apps/flavored/web_view.f.dart';

final GlobalKey<NavigatorState> navigatorKeyF = GlobalKey<NavigatorState>();

NavigatorState? get navigator => navigatorKeyF.currentState;

class RouterF {
  static String? initRoute = WebViewF.path;
  static dynamic initParams;

  static var routes = {
    WebViewF.path: (context) => const WebViewF(),
  };
}
