import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/notifications/channel.dart';
import 'package:loggy/loggy.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

Future<void> initializeTimeZone() async {
  initializeTimeZones();
  final String currentTimeZone = await FlutterNativeTimezone.getLocalTimezone();
  setLocalLocation(getLocation(currentTimeZone));
}

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin;

  NotificationService._(this.plugin);

  static Future<NotificationService> create() async {
    final plugin = FlutterLocalNotificationsPlugin();

    final service = NotificationService._(plugin);
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: handleNotification,
      onDidReceiveBackgroundNotificationResponse: handleNotification,
    );

    return service;
  }

  static Future<void> init(WidgetRef ref) async {
    NotificationService service = await NotificationService.create();
    var provider = ref.read(notificationProvider);
    if (provider == null) {
      ref.read(notificationProvider.notifier).state = service;
    }
  }

  static void handleNotification(NotificationResponse response) async {
    logDebug('_handleNotification PushPlugin');
    final parsed = response.payload != null ? json.decode(response.payload!) : {};
    if (!NotificationChannel.canAcceptTap(parsed['channel_id'])) return;
    if(parsed["redirectUrl"] != null){
      await RedirectNotificationChannel().onTap(parsed['redirectUrl']);
      return;
    }
    await NotificationChannel.fromId(parsed['channel_id']).onTap(parsed['payload']);
  }

  NotificationDetails _details(
    Color? color,
    NotificationChannel channel,
  ) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          color: color,
        ),
      );

  /// Example:
  /// ```dart
  ///await NotificationPlugin.of(context).showNotification(...);
  /// ```
  Future<void> showNotification(
    NotificationChannel channel,
    String? title,
    String? description, {
    String? payload,
    String? redirectUrl,
    ThemeData? theme,
  }) async {
    final newPayload = {
      'channel_id': channel.id,
      'payload': payload,
      'redirectUrl': redirectUrl
    };

    await plugin.show(
      int.parse(DateTime.now().microsecondsSinceEpoch.toString().replaceRange(0, 7, '')),
      title,
      description,
      _details(theme?.primaryColor, channel),
      payload: json.encode(newPayload),
    );
  }

  /// Example:
  /// ```dart
  ///await NotificationPlugin.of(context).scheduleNotification(...);
  /// ```
  /// Make sure you call [initializeTimeZone] beforehand!
  Future<void> scheduleNotification(
    NotificationChannel channel,
    String? title,
    String? description,
    Duration duration, {
    String? payload,
    ThemeData? theme,
  }) async {
    final newPayload = {
      'channel_id': channel.id,
      'payload': payload,
    };

    await plugin.zonedSchedule(
      0,
      title,
      description,
      TZDateTime.now(local).add(duration),
      _details(theme?.primaryColor, channel),
      payload: jsonEncode(newPayload),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
    );
  }
}

final notificationProvider = StateProvider<NotificationService?>(
  (ref) {
    return null;
  },
);
