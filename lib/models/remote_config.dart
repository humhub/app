import 'package:dio/dio.dart';
import 'package:humhub/models/file_upload_settings.dart';
import 'package:loggy/loggy.dart';

import 'manifest.dart';

class RemoteConfig {
  final String appName;
  final String appVersion;
  final FileUploadSettings fileUploadSettings;
  final List<Uri> whiteListedDomains;

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
      fileUploadSettings: FileUploadSettings.fromJson(json['fileUploadSettings'] as Map<String, dynamic>),
      whiteListedDomains: (json['whiteListedDomains'] as List<dynamic>).map((e) => Uri.tryParse(e as String)).where((uri) => uri != null).cast<Uri>().toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'appVersion': appVersion,
      'fileUploadSettings': fileUploadSettings.toJson(),
      'whiteListedDomains': whiteListedDomains.map((uri) => uri.toString()).toList(),
    };
  }

  static Future<RemoteConfig?> get(Manifest manifest, Map<String, dynamic>? headers) async {
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
    final String inputBase = '${uri.scheme}://${uri.authority}';

    return whiteListedDomains.any((trustedUri) {
      final trustedBase = '${trustedUri.scheme}://${trustedUri.authority}';
      return inputBase == trustedBase;
    });
  }
}
