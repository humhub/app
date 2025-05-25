import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/util/providers.dart';
import 'package:humhub/util/router.dart';
import 'package:loggy/loggy.dart';

void main() {
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
