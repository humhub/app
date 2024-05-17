import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/log.dart';
import 'package:humhub/util/storage_service.dart';
import 'package:loggy/loggy.dart';
import 'apps/opener_app.dart';

main() async {
  Loggy.initLoggy(
    logPrinter: const GlobalLog(),
  );
  WidgetsFlutterBinding.ensureInitialized();
  await SecureStorageService.clearSecureStorageOnReinstall();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(const ProviderScope(child: OpenerApp()));
  });
}
