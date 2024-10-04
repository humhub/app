import 'package:humhub/flavored/web_view.f.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/notifications/channel.dart';
import 'package:humhub/util/notifications/init_from_push.dart';

class NotificationChannelF extends NotificationChannel {
  const NotificationChannelF(
      {super.id = 'redirect',
      super.name = 'Redirect flavored app notifications',
      super.description = 'These notifications redirect the user to specific url in a payload.'});

  /// If the WebView is not opened yet or the app is not running the onTap will wake up the app or redirect to the WebView.
  /// If app is already running in WebView mode then the state of [WebViewApp] will be updated with new url.
  ///
  @override
  Future<void> onTap(String? payload) async {
    if (payload != null && navigatorKey.currentState != null) {
      bool isNewRouteSameAsCurrent = false;
      navigatorKey.currentState!.popUntil((route) {
        if (route.settings.name == WebViewF.path) {
          isNewRouteSameAsCurrent = true;
        }
        return true;
      });
      if (isNewRouteSameAsCurrent) {
        navigatorKey.currentState!.pushNamed(WebViewF.path, arguments: payload);
        return;
      }
      navigatorKey.currentState!.pushNamed(WebViewF.path, arguments: payload);
    } else {
      if (payload != null) {
        InitFromPush.setPayload(payload);
      }
    }
  }
}