import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:humhub/flavored/models/manifest.f.dart';
import 'package:humhub/models/hum_hub.dart';

class HumHubF extends HumHub{
  @override
  ManifestF get manifest => ManifestF.fromEnv();
  @override
  String get manifestUrl => dotenv.env['MANIFEST_URL']!;

  HumHubF({
    bool isHideOpener = false,
    String? randomHash,
    String? appVersion,
    String? pushToken,
  }) : super(
      isHideOpener: isHideOpener,
      randomHash: HumHub.generateHash(32),
      appVersion: appVersion,
      pushToken: pushToken);
}