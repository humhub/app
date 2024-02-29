import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:humhub/flavored/flavored_web_view.dart';
import 'package:humhub/util/intent/intent_plugin.dart';
import 'package:humhub/util/notifications/plugin.dart';
import 'package:humhub/util/push/push_plugin.dart';
import 'package:humhub/util/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/hum_hub.dart';

class FlavoredApp extends ConsumerStatefulWidget {
  final HumHub instance;
  const FlavoredApp({super.key, required this.instance});

  @override
  FlavoredAppState createState() => FlavoredAppState();
}

class FlavoredAppState extends ConsumerState<FlavoredApp> {
  @override
  Widget build(BuildContext context) {
    clearSecureStorageOnReinstall();
    return IntentPlugin(
      child: NotificationPlugin(
        child: PushPlugin(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const FlavoredWebView(),
                settings: RouteSettings(arguments: widget.instance),
              );
            },
            navigatorKey: navigatorKey,
            theme: ThemeData(
              fontFamily: 'OpenSans',
            ),
          ),
        ),
      ),
    );
  }
}

clearSecureStorageOnReinstall() async {
  String key = 'hasRunBefore';
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool hasRunBefore = prefs.getBool(key) ?? false;
  if (!hasRunBefore) {
    FlutterSecureStorage storage = const FlutterSecureStorage();
    await storage.deleteAll();
    prefs.setBool(key, true);
  }
}
