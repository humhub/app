import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:humhub/util/intent/intent_plugin.dart';
import 'package:humhub/util/notifications/plugin.dart';
import 'package:humhub/util/push/push_plugin.dart';
import 'package:humhub/util/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpenerApp extends ConsumerStatefulWidget {
  const OpenerApp({super.key});

  @override
  OpenerAppState createState() => OpenerAppState();
}

class OpenerAppState extends ConsumerState<OpenerApp> {
  @override
  Widget build(BuildContext context) {
    clearSecureStorageOnReinstall();
    return IntentPlugin(
      child: NotificationPlugin(
        child: PushPlugin(
          child: FutureBuilder<String>(
            future: MyRouter.getInitialRoute(ref),
            builder: (context, snap) {
              if (snap.hasData) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  initialRoute: snap.data,
                  routes: MyRouter.routes,
                  navigatorKey: navigatorKey,
                  theme: ThemeData(
                    fontFamily: 'OpenSans',
                  ),
                );
              }
              return const SizedBox.shrink();
            },
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
