import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/universal_opener_controller.dart';
import 'package:humhub/util/router.dart';
import 'package:loggy/loggy.dart';

abstract class NotificationChannel {
  final String id;
  final String name;
  final String description;

  NotificationChannel(this.id, this.name, this.description);

  Future<void> onTap(String? payload);

  @protected
  Future<void> navigate(String route, {Object? arguments}) async {
    logInfo('NotificationChannel navigate: $route');
    if (navigatorKey.currentState?.mounted ?? false) {
      await navigatorKey.currentState?.pushNamed(
        route,
        arguments: arguments,
      );
    } else {
      queueRoute(
        route,
        arguments: arguments,
      );
    }
  }
}

class RedirectNotificationChannel extends NotificationChannel {
  RedirectNotificationChannel()
      : super(
          'redirect',
          'Redirect app notifications',
          'These notifications are redirect the user to specific url in a payload.',
        );

  /// If the WebView is not opened yet or the app is not running the onTap will wake up the app or redirect to the WebView.
  /// If app is already running in WebView mode then the state of [WebViewApp] will be updated with new url.
  @override
  Future<void> onTap(String? payload) async {
    if (payload != null && navigatorKey.currentState != null) {
      bool isNewRouteSameAsCurrent = false;
      navigatorKey.currentState!.popUntil((route) {
        if (route.settings.name == WebViewApp.path) {
          isNewRouteSameAsCurrent = true;
        }
        return true;
      });
      UniversalOpenerController opener = UniversalOpenerController(url: payload);
      await opener.initHumHub();
      if (isNewRouteSameAsCurrent) {
        navigatorKey.currentState!.pushNamed(WebViewApp.path, arguments: opener);
        return;
      }
      navigatorKey.currentState!.pushNamed(WebViewApp.path, arguments: opener);
    } else {
      if (payload != null) {
        RedirectUrlFromInit.setPayloadForInit(payload);
      }
    }
  }
}

class RedirectUrlFromInit {
  static String? _redirectUrlFromInit;

  static setPayloadForInit(String payload) {
    _redirectUrlFromInit = payload;
  }

  static String? usePayloadForInit() {
    String? payload = _redirectUrlFromInit;
    _redirectUrlFromInit = null;
    return payload;
  }
}
