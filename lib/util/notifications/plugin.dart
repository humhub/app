import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/notifications/service.dart';

class NotificationPlugin extends StatefulWidget {
  final Widget child;

  const NotificationPlugin({super.key, required this.child});

  static NotificationService of(WidgetRef ref) {
    final plugin = ref.read(notificationProvider);
    assert(
      plugin != null,
      'NotificationService is uninitialized. '
      'Place NotificationPlugin widget as high in widget tree as possible.',
    );
    return plugin!;
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
