import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/flavored/util/notifications/channel.f.dart';
import 'package:humhub/models/env_config.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/init_from_url.dart';
import 'package:humhub/util/openers/universal_opener_controller.dart';
import 'package:loggy/loggy.dart';

class NotificationChannel {
  final String id;
  final String name;
  final String description;

  const NotificationChannel(
      {this.id = 'redirect',
      this.name = 'Redirect app notifications',
      this.description = 'These notifications are redirect the user to specific url in a payload.'});

  /// If the WebView is not opened yet or the app is not running the onTap will wake up the app or redirect to the WebView.
  /// If app is already running in WebView mode then the state of [WebView] will be updated with new url.
  ///
  Future<void> onTap(String? payload) async {
    if (payload != null && Keys.navigatorKey.currentState != null) {
      logDebug('NotificationChannel: Received payload: $payload');
      bool isNewRouteSameAsCurrent = false;
      Keys.navigatorKey.currentState!.popUntil((route) {
        if (route.settings.name == WebView.path) {
          isNewRouteSameAsCurrent = true;
        }
        return true;
      });
      UniversalOpenerController opener = UniversalOpenerController(url: payload);
      await opener.initHumHub();
      if (isNewRouteSameAsCurrent) {
        Keys.navigatorKey.currentState!.pushNamed(WebView.path, arguments: opener);
        return;
      }
      Keys.navigatorKey.currentState!.pushNamed(WebView.path, arguments: opener);
    } else {
      if (payload != null) {
        InitFromUrl.setPayload(payload);
      }
    }
  }

  static NotificationChannel getChannel() {
    if (EnvConfig.instance!.isWhiteLabeled) {
      logInfo('NotificationChannel: Using flavored channel');
      return const NotificationChannelF();
    }
    return const NotificationChannel();
  }
}

final notificationChannelProvider = Provider<NotificationChannel>((ref) {
  return NotificationChannel.getChannel();
});
