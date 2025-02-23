import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/util/providers.dart';
import 'package:humhub/util/router.dart';
import 'package:loggy/loggy.dart';

void main() async {
  // Create a container to handle providers outside widget tree
  final ref = ProviderContainer();

  try {
    // Initialize HumHub instance early
    final app = await HumHub.init();
    HumHub instance = await ref.read(humHubProvider).getInstance();
    await MyRouter.initInitialRoute(instance);

    // Use UncontrolledProviderScope to share the container
    runApp(UncontrolledProviderScope(
      container: ref,
      child: app,
    ));
  } catch (e) {
    logError('Failed to initialize: $e');
  }
}
