import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/event.dart';
import 'package:humhub/util/loading_provider.dart';
import 'package:humhub/util/notifications/channel.dart';
import 'package:humhub/util/notifications/plugin.dart';
import 'package:humhub/util/notifications/service.dart';
import 'package:humhub/util/push/provider.dart';
import 'package:humhub/util/push/register_token_plugin.dart';
import 'package:loggy/loggy.dart';

class PushPlugin extends ConsumerStatefulWidget {
  final Widget child;

  const PushPlugin({
    Key? key,
    required this.child,
  }) : super(
          key: key,
        );

  @override
  PushPluginState createState() => PushPluginState();
}

class PushPluginState extends ConsumerState<PushPlugin> {
  Future<void> _init() async {
    logInfo("Init PushPlugin");
    await Firebase.initializeApp();
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) logInfo('PushPlugin with token: $token');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logInfo("Firebase messaging onMessage");
      _handleNotification(
        message,
        NotificationPlugin.of(ref),
      );
      _handleData(message, context, ref);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logInfo("Firebase messaging onMessageOpenedApp");
      final data = PushEvent(message).parsedData;
      ref.read(notificationChannelProvider).value!.onTap(data.redirectUrl);
    });

    //When the app is terminated, i.e., app is neither in foreground or background.
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      logInfo("MD10-01");
      logInfo(message);
      if (message != null) {
        logInfo("MD10-02");
        LoadingProvider.of(ref).showLoading(hideBackground: true);
        logInfo("MD10-03");
        final data = PushEvent(message).parsedData;
        logInfo("MD10-04");
        if (data.redirectUrl != null) {
          logInfo("MD10-05");
          ref.read(notificationChannelProvider).value!.onTap(data.redirectUrl);
        }
        logInfo("MD10-06");
      }
    });

    ref.read(firebaseInitialized.notifier).state = const AsyncValue.data(true);

    ref.read(pushTokenProvider);
  }

  @override
  void initState() {
    ref.read(notificationChannelProvider);
    _init();
    super.initState();
  }

  Future<void> _handleNotification(RemoteMessage message, NotificationService notificationService) async {
    // Here we handle the notification that we get form an push notification.
    final data = PushEvent(message).parsedData;
    if (message.notification == null) return;
    final title = message.notification?.title;
    final body = message.notification?.body;
    if (title == null || body == null) return;
    await notificationService.showNotification(
      ref.read(notificationChannelProvider).value!,
      title,
      body,
      payload: data.channelPayload,
      redirectUrl: data.redirectUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RegisterToken(
      child: widget.child,
    );
  }
}

Future<void> _handleData(RemoteMessage message, BuildContext context, WidgetRef ref) async {
  // Here we handle the data that we get form an push notification.
  PushEventData data = PushEvent(message).parsedData;
  try {
    // Set icon badge count if notificationCount exist in push.
    FlutterAppBadger.updateBadgeCount(int.parse(data.notificationCount!));
  } catch (e) {
    logError(e);
  }
}
