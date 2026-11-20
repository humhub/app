import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/app_opener.dart';
import 'package:humhub/flavored/models/manifest.f.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/util/intent/app_link_settings.dart';
import 'package:humhub/util/providers.dart';
import 'package:humhub/util/push/background_handler.dart';
import 'package:humhub/util/router.dart';
import 'package:humhub/util/unread_counts.dart';
import 'package:loggy/loggy.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    logError('Flutter framework error: ${details.exception}', details.exception,
        details.stack);
    Zone.current.handleUncaughtError(
        details.exception, details.stack ?? StackTrace.current);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    logError('PlatformDispatcher error: $error', error, stack);
    return true;
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final ref = ProviderContainer();
    final app = await HumHub.initApp();
    HumHub instance = await ref.read(humHubProvider).getInstance();
    // The instances whose unread counts add up to the app icon badge. The badge is not reset here anymore:
    // the count of an instance is cleared when it is opened, see WebView.
    await UnreadCounts.sync(
      app is OpenerApp ? instance.history.map((manifest) => manifest.startUrl) : [ManifestF.fromEnv().startUrl],
    );
    await AppLinkSettings.refresh();
    await AppRouter.initInitialRoute(instance);
    runApp(UncontrolledProviderScope(
      container: ref,
      child: app,
    ));
  }, (error, stack) {
    logError('Global error: $error', error, stack);
  });
}
