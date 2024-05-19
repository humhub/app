import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/notifications/service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPlugin extends StatefulWidget {
  final Widget child;

  const NotificationPlugin({Key? key, required this.child}) : super(key: key);

  static NotificationService of(WidgetRef ref) {
    final plugin = ref.read(notificationProvider);
    assert(
      plugin != null,
      'NotificationService is uninitialized. '
      'Place NotificationPlugin widget as high in widget tree as possible.',
    );
    return plugin!;
  }

  static Future<bool> hasAskedPermissionBefore() async {
    String key = 'was_asked_before';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = prefs.getBool(key) ?? false;
    prefs.setBool(key, true);
    return data;
  }

  @override
  NotificationPluginState createState() => NotificationPluginState();
}

class NotificationPluginState extends State<NotificationPlugin> {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final service = ref.watch(notificationProvider);
        if (service == null) {
          NotificationService.init(ref);
        }
        return child!;
      },
      child: widget.child,
    );
  }
}
