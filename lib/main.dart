import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/app_flavored.dart';
import 'package:humhub/util/log.dart';
import 'package:humhub/util/storage_service.dart';
import 'package:loggy/loggy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'app_opener.dart';

main() async {
  Loggy.initLoggy(
    logPrinter: const GlobalLog(),
  );
  WidgetsFlutterBinding.ensureInitialized();
  await SecureStorageService.clearSecureStorageOnReinstall();

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  if (packageInfo.packageName == 'com.humhub.app') {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
      runApp(const ProviderScope(child: OpenerApp()));
    });
  } else {
    await dotenv.load(fileName: ".env");
    runApp(const ProviderScope(child: FlavoredApp()));
  }
}
