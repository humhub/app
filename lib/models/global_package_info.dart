import 'package:package_info_plus/package_info_plus.dart';

class GlobalPackageInfo {
  static late PackageInfo info;

  static Future<void> init() async {
    info = await PackageInfo.fromPlatform();
  }
}
