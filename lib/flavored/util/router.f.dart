import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:humhub/flavored/web_view.f.dart';

final GlobalKey<NavigatorState> navigatorKeyF = GlobalKey<NavigatorState>();

NavigatorState? get navigator => navigatorKeyF.currentState;

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
