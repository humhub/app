import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:loggy/loggy.dart';

class EnvConfig {
  final List<IntentProvider>? intentProviders;

  static EnvConfig? _instance;

  static EnvConfig? get instance => _instance;

  EnvConfig({required this.intentProviders});

  factory EnvConfig.fromJson(Map<String, dynamic> json) {
    return EnvConfig(
      intentProviders: json['intent_providers'].map((item) => IntentProvider.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  static Future<EnvConfig> init() async {
    try {
      String jsonString = await rootBundle.loadString('assets/env.json');
      Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      _instance = EnvConfig.fromJson(jsonMap);
    } catch (e, s) {
      logError('Error loading env.json', e, s);
      exit(1);
    }
    return instance!;
  }
}

class IntentProvider {
  final String type;
  final String shouldHandleRegex;

  IntentProvider({
    required this.type,
    required this.shouldHandleRegex,
  });

  factory IntentProvider.fromJson(Map<String, dynamic> json) {
    return IntentProvider(
      type: json['type'],
      shouldHandleRegex: json['should_handle_regex'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'should_handle_regex': shouldHandleRegex,
    };
  }
}
