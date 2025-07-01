import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:loggy/loggy.dart';

import '../util/crypt.dart';
import 'hum_hub.dart';
import 'manifest.dart';

class EnvConfig {
  final String appName;
  final String bundleId;
  final bool isWhiteLabeled;
  final List<IntentProvider>? intentProviders;
  final HumHubConfig? humhubConfig;

  static EnvConfig? _instance;

  static EnvConfig? get instance => _instance;

  EnvConfig({required this.appName, required this.bundleId, required this.isWhiteLabeled, required this.intentProviders, required this.humhubConfig});

  factory EnvConfig.fromJson(Map<String, dynamic> json) {
    return EnvConfig(
        appName: json['app_name'],
        bundleId: json['bundle_id'],
        isWhiteLabeled: json['is_white_labeled'] as bool,
        intentProviders: (json['intent_providers'] as List).map((item) => IntentProvider.fromJson(item as Map<String, dynamic>)).toList(),
        humhubConfig: HumHubConfig(json: json));
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

class ManifestConfig extends Manifest {
  ManifestConfig(
      {required super.display,
      required super.startUrl,
      required super.shortName,
      required super.name,
      required super.backgroundColor,
      required super.themeColor,
      super.icons});

  factory ManifestConfig.fromJson(Map<String, dynamic> json) {
    return ManifestConfig(
      display: json['display'],
      startUrl: json['start_url'],
      shortName: json['short_name'],
      name: json['name'],
      backgroundColor: json['background_color'],
      themeColor: json['theme_color'],
    );
  }
}

class HumHubConfig extends HumHub {
  HumHubConfig({
    required Map<String, dynamic> json,
    super.openerState,
    String? randomHash,
    super.appVersion,
    super.pushToken,
  }) : super(randomHash: Crypt.generateRandomString(32), manifest: ManifestConfig.fromJson(json['manifest']), manifestUrl: json['manifest_url']);

  @override
  Map<String, String> get customHeaders => {
        'x-humhub-app-token': randomHash!,
        'x-humhub-app': appVersion ?? '1.0.0',
        'x-humhub-app-bundle-id': EnvConfig.instance!.bundleId,
        'x-humhub-app-is-ios': isIos ? '1' : '0',
        'x-humhub-app-is-android': isAndroid ? '1' : '0',
        'x-humhub-app-ostate': openerState.headerValue
      };
}
