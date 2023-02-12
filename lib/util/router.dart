import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/util/providers.dart';

import '../pages/opener.dart';
import '../pages/web_view.dart';

class Router{
  static String? initRoute;
  static dynamic initParams;

  static var routes = {
    Opener.path: (context) => const Opener(),
    WebViewApp.path: (context) => const WebViewApp(),
  };

  static Future<String> getInitialRoute(WidgetRef ref) async {
    HumHub humhub = await ref.read(humHubProvider).getInstance();
    RedirectAction action = await humhub.action(ref);
    switch (action) {
      case RedirectAction.opener:
        initRoute = Opener.path;
        return Opener.path;
      case RedirectAction.webView:
        initRoute = WebViewApp.path;
        initParams = humhub.manifest;
        return WebViewApp.path;
    }
  }
}