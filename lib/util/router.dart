import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/pages/help/help.dart';
import 'package:humhub/util/providers.dart';
import 'package:loggy/loggy.dart';
import '../pages/opener.dart';
import '../pages/web_view.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

NavigatorState? get navigator => navigatorKey.currentState;

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

class MyRouter {
  static String? initRoute;
  static dynamic initParams;

  static var routes = {
    Opener.path: (context) => const Opener(),
    WebViewApp.path: (context) => const WebViewApp(),
    Help.path: (context) => const Help(),
  };

  static Future<String> getInitialRoute(WidgetRef ref) async {
    HumHub humhub = await ref.read(humHubProvider).getInstance();
    RemoteMessage? remoteMessage = await FirebaseMessaging.instance.getInitialMessage();
    return FirebaseMessaging.instance.getInitialMessage().then((value) async {
      logDebug('GA13245 rm12 after .then getInitialRoute getInitialMessage: $remoteMessage');
      RedirectAction action = await humhub.action(ref);
      if (remoteMessage == null) {
        logDebug('GA13245 in IF');
        initParams = humhub.manifest;
      } else {
        logDebug('GA13245 in ELSE');
        initParams = ManifestWithRemoteMsg(humhub.manifest!, remoteMessage);
      }
      switch (action) {
        case RedirectAction.opener:
          initRoute = Opener.path;
          return Opener.path;
        case RedirectAction.webView:
          initRoute = WebViewApp.path;

          return WebViewApp.path;
      }
    });
  }
}

class ManifestWithRemoteMsg {
  final Manifest _manifest;
  final RemoteMessage _remoteMessage;

  RemoteMessage get remoteMessage => _remoteMessage;
  Manifest get manifest => _manifest;

  ManifestWithRemoteMsg(this._manifest, this._remoteMessage);
}
