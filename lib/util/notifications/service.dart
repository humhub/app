import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/notifications/channel.dart';

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
    final parsed = response.payload != null ? json.decode(response.payload!) : {};
    if (parsed["redirectUrl"] != null) {
      var channel = await NotificationChannel.getChannel();
      channel.onTap(parsed['redirectUrl']);
      return;
    }
  }

  Future<void> showNotification(
    NotificationChannel channel,
    String? title,
    String? description, {
    String? payload,
    String? redirectUrl,
    ThemeData? theme,
  }) async {
    final newPayload = {'channel_id': channel.id, 'payload': payload, 'redirectUrl': redirectUrl};
    await plugin.show(
      int.parse(DateTime.now().microsecondsSinceEpoch.toString().replaceRange(0, 7, '')),
      title,
      description,
      _details(theme?.primaryColor, channel),
      payload: json.encode(newPayload),
    );
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
          priority: Priority.max,
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          color: color,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: channel.id,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );
}

final notificationProvider = StateProvider<NotificationService?>(
  (ref) {
    return null;
  },
);
