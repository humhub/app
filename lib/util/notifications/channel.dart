import 'package:flutter/foundation.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/router.dart';
import 'package:loggy/loggy.dart';

/// Used to group notifications by Android channels
///
/// How to use: subclass this abstract class and override onTap method. Then
/// pass instance of this subclass to [NotificationService.scheduleNotification]
/// which will take care of calling [onTap] on correct channel.
abstract class NotificationChannel {
  final String id;
  final String name;
  final String description;

  NotificationChannel(this.id, this.name, this.description);

  static final List<NotificationChannel> _knownChannels = [
    GeneralNotificationChannel(),
  ];

  static bool canAcceptTap(String? channelId) {
    final result = _knownChannels.any((element) => element.id == channelId);

    if (!result) {
      logError("Error on channelId: $channelId");
    }
    return result;
  }

  factory NotificationChannel.fromId(String? id) => _knownChannels.firstWhere(
        (channel) => id == channel.id,
      );

  Future<void> onTap(String? payload);

  @protected
  Future<void> navigate(String route, {Object? arguments}) async {
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

class GeneralNotificationChannel extends NotificationChannel {
  GeneralNotificationChannel()
      : super(
          'general',
          'General app notifications',
          'These notifications don\'t belong to any other category.',
        );

  @override
  Future<void> onTap(String? payload) async {
    if (payload != null) {
      logInfo("Here we do navigate to specific screen for channel");
    }
  }
}

class RedirectNotificationChannel extends NotificationChannel {
  RedirectNotificationChannel()
      : super(
    'general',
    'General app notifications',
    'These notifications don\'t belong to any other category.',
  );

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
      if (!isNewRouteSameAsCurrent) {
        navigatorKey.currentState!.pushNamed(WebViewApp.path, arguments: payload);
      }
      navigatorKey.currentState!.popAndPushNamed(WebViewApp.path, arguments: payload);
    }
  }
}
