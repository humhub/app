import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/util/providers.dart';
import 'package:humhub/util/router.dart';
import 'package:loggy/loggy.dart';

void main() {
  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    logError('Flutter framework error: ${details.exception}', details.exception, details.stack);
    Zone.current.handleUncaughtError(details.exception, details.stack ?? StackTrace.current);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    logError('PlatformDispatcher caught: $error', error, stack);
    return true;
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    final ref = ProviderContainer();
    final app = await HumHub.initApp();
    HumHub instance = await ref.read(humHubProvider).getInstance();
    await MyRouter.initInitialRoute(instance);
    runApp(UncontrolledProviderScope(
      container: ref,
      child: app,
    ));
  }, (error, stack) {
    logError('Global error: $error', stack);
  });
}
