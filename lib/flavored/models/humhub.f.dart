import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:humhub/flavored/models/manifest.f.dart';
import 'package:humhub/models/feature_flag.dart';
import 'package:humhub/models/global_package_info.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/util/crypt.dart';
import 'package:humhub/util/intent/app_link_settings.dart';

class HumHubF extends HumHub {
  @override
  ManifestF get manifest => ManifestF.fromEnv();
  @override
  String get manifestUrl => dotenv.env['MANIFEST_URL']!;

  HumHubF({
    super.openerState,
    String? randomHash,
    super.appVersion,
    super.pushToken,
  }) : super(randomHash: Crypt.generateRandomString(32));

  @override
  Map<String, String> get customHeaders => {
        'x-humhub-app-token': randomHash!,
        'x-humhub-app': GlobalPackageInfo.info.version,
        'x-humhub-app-feature-flags': FeatureFlag.featureFlagsHeaderValue,
        'x-humhub-app-bundle-id': GlobalPackageInfo.info.packageName,
        'x-humhub-app-is-ios': isIos ? '1' : '0',
        'x-humhub-app-is-android': isAndroid ? '1' : '0',
        'x-humhub-app-ostate': openerState.headerValue,
        'x-humhub-app-intent-enabled': AppLinkSettings.headerValue,
      };
}
