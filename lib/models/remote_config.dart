import 'package:dio/dio.dart';
import 'package:humhub/models/file_upload_settings.dart';
import 'package:humhub/util/extensions.dart';
import 'package:loggy/loggy.dart';

import 'manifest.dart';

class RemoteConfig {
  static const String _authClientRedirectVersion = '1.19.0';
  final String? appName;
  final String? appVersion;
  final FileUploadSettings? fileUploadSettings;
  final List<Uri>? whiteListedDomains;

  RemoteConfig({
    required this.appName,
    required this.appVersion,
    required this.fileUploadSettings,
    required this.whiteListedDomains,
  });

  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    return RemoteConfig(
      appName: json['appName'] as String,
      appVersion: json['appVersion'] as String,
      fileUploadSettings: FileUploadSettings.fromJson(
          json['fileUploadSettings'] as Map<String, dynamic>),
      whiteListedDomains: (json['whiteListedDomains'] as List<dynamic>)
          .map((e) => Uri.tryParse(e as String))
          .where((uri) => uri != null)
          .cast<Uri>()
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'appVersion': appVersion,
      'fileUploadSettings': fileUploadSettings?.toJson(),
      'whiteListedDomains':
          whiteListedDomains?.map((uri) => uri.toString()).toList(),
    };
  }

  static Future<RemoteConfig?> get(
      Manifest manifest, Map<String, dynamic>? headers) async {
    try {
      final response = await Dio().get(
        '${manifest.startUrl}/mobile-app/get-settings',
        options: Options(maxRedirects: 10, headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        return RemoteConfig.fromJson(response.data as Map<String, dynamic>);
      } else {
        logError('Failed to get settings: status code ${response.statusCode}');
        return null;
      }
    } catch (err) {
      logError('Error getting settings: $err');
      return null;
    }
  }

  bool isTrustedDomain(Uri uri) {
    if (whiteListedDomains.isNullOrEmpty) return false;
    final String inputBase = '${uri.scheme}://${uri.authority}';

    return whiteListedDomains!.any((trustedUri) {
      final trustedBase = '${trustedUri.scheme}://${trustedUri.authority}';
      return inputBase == trustedBase;
    });
  }

  bool get supportsAuthClientRedirect =>
      _compareVersions(appVersion, _authClientRedirectVersion) >= 0;

  static int _compareVersions(String? current, String target) {
    final currentParts = _parseVersion(current);
    final targetParts = _parseVersion(target);

    if (currentParts == null || targetParts == null) {
      return -1;
    }

    for (var index = 0; index < 3; index++) {
      final difference = currentParts[index] - targetParts[index];
      if (difference != 0) {
        return difference;
      }
    }

    return 0;
  }

  static List<int>? _parseVersion(String? version) {
    if (version == null || version.isEmpty) {
      return null;
    }

    final normalizedVersion = version.split('+').first.split('-').first.trim();
    final parts = normalizedVersion.split('.');
    if (parts.isEmpty) {
      return null;
    }

    final parsed = <int>[];
    for (var index = 0; index < 3; index++) {
      if (index >= parts.length) {
        parsed.add(0);
        continue;
      }

      final value = int.tryParse(parts[index]);
      if (value == null) {
        return null;
      }
      parsed.add(value);
    }

    return parsed;
  }
}
