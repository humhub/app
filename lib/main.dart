import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/opener_app.dart';
import 'package:humhub/util/log.dart';
import 'package:humhub/util/notifications/plugin.dart';
import 'package:humhub/util/override_locale.dart';
import 'package:humhub/util/push/push_plugin.dart';
import 'package:humhub/util/router.dart';
import 'package:loggy/loggy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

main() async {
  Loggy.initLoggy(
    logPrinter: const GlobalLog(),
  );

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      logDebug("Package Name: ${packageInfo.packageName}");
      switch (packageInfo.packageName) {
        case "com.humhub.app":
          logDebug("Package Name: ${packageInfo.packageName}");
          runApp(const ProviderScope(child: OpenerApp()));
          break;
        default:
          logDebug("Package Name: ${packageInfo.packageName}");
          runApp(const ProviderScope(child: OpenerApp()));
      }
    });
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    clearSecureStorageOnReinstall();
    return IntentPlugin(
      child: NotificationPlugin(
        child: PushPlugin(
          child: OverrideLocale(
            builder: (overrideLocale) => Builder(
              builder: (context) => FutureBuilder<String>(
                future: MyRouter.getInitialRoute(ref),
                builder: (context, snap) {
                  if (snap.hasData) {
                    return MaterialApp(
                      debugShowCheckedModeBanner: false,
                      initialRoute: snap.data,
                      routes: MyRouter.routes,
                      navigatorKey: navigatorKey,
                      localizationsDelegates: AppLocalizations.localizationsDelegates,
                      supportedLocales: AppLocalizations.supportedLocales,
                      locale: overrideLocale,
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
