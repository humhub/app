import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/hum_hub.dart';

main() async {
  final app = await HumHub.init();
  runApp(ProviderScope(child: app));
}
