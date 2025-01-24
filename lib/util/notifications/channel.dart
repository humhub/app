import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/flavored/util/notifications/channel.f.dart';
import 'package:humhub/models/global_package_info.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/init_from_url.dart';
import 'package:humhub/util/openers/universal_opener_controller.dart';

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

  static Future<NotificationChannel> getChannel() async {
    switch (GlobalPackageInfo.info.packageName) {
      case 'com.humhub.app':
        return const NotificationChannel();
      default:
        return const NotificationChannelF();
    }
  }
}

// Providers for NotificationChannel and NotificationChannelF
final notificationChannelProvider = FutureProvider<NotificationChannel>((ref) {
  return NotificationChannel.getChannel();
});
