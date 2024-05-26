import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/notifications/channel.dart';
import 'package:humhub/util/notifications/init_from_push.dart';
import 'package:humhub/util/openers/universal_opener_controller.dart';
import 'package:humhub/util/router.dart';

class NotificationChannelF extends NotificationChannel {
  NotificationChannelF(
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
        InitFromPush.setPayload(payload);
      }
    }
  }
}
