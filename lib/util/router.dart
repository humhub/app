import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/pages/console.dart';
import 'package:humhub/pages/help/help.dart';
import 'package:humhub/pages/opener/opener.dart';
import 'package:humhub/pages/settings/settings.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/const.dart';

NavigatorState? get navigator => Keys.navigatorKey.currentState;

List<Map> _pendingRoutes = [];

/// Queue any route, this route is pushed on stack after app has initialized.
/// This usually means after user is logged in and assets are downloaded
void queueRoute(
  String routeName, {
  Object? arguments,
}) {
  _pendingRoutes.add({
    'route': routeName,
    'arguments': arguments,
  });
}

class AppRouter {
  static String? initRoute;
  static dynamic initParams;

  static Map<String, Widget Function(BuildContext)> routes = {
    OpenerPage.path: (context) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      return const OpenerPage();
    },
    WebView.path: (context) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      return const WebView();
    },
    '/help': (context) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      return const Help();
    },
    ConsolePage.routeName: (context) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      return const ConsolePage();
    },
    SettingsPage.path: (context) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      return const SettingsPage();
    },
  };

  static Future<String> initInitialRoute(HumHub humhub) async {
    RedirectAction action = await humhub.action;
    switch (action) {
      case RedirectAction.opener:
        initRoute = OpenerPage.path;
        return OpenerPage.path;
      case RedirectAction.webView:
        initRoute = WebView.path;
        initParams = humhub.manifest;
        return WebView.path;
    }
  }
}
