import 'package:package_info_plus/package_info_plus.dart';

class GlobalPackageInfo {
  static PackageInfo? _info;

  static PackageInfo get info =>
      _info ??
      PackageInfo(
        appName: '',
        packageName: '',
        version: '1.0.0',
        buildNumber: '',
        buildSignature: '',
      );

  static Future<void> init() async {
    _info = await PackageInfo.fromPlatform();
    return;
  }
}
