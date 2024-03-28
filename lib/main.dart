import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:humhub/opener_app.dart';
import 'package:humhub/util/flavor.dart';
import 'package:humhub/util/log.dart';
import 'package:loggy/loggy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'flavored_app.dart';
import 'models/hum_hub.dart';

main() async {
  Loggy.initLoggy(
    logPrinter: const GlobalLog(),
  );

  WidgetsFlutterBinding.ensureInitialized();
  clearSecureStorageOnReinstall();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) async {
      logDebug("Package Name: ${packageInfo.packageName}");
      switch (packageInfo.packageName) {
        case "com.humhub.app":
          runApp(const ProviderScope(child: OpenerApp()));
          break;
        default:
          // Handle if the instance does not exist for selected bundle id.
          HumHub? instance = await Flavor.getInstance(packageInfo.packageName);
          runApp(ProviderScope(child: FlavoredApp(instance: instance!)));
          break;
      }
    });
  });
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

