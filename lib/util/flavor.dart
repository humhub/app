import 'package:humhub/util/opener_controllers/flavored_opener_controller.dart';
import 'package:humhub/models/hum_hub.dart';

class Flavor {
  final String manifestUrl;
  final String name;
  final String bundleId;

  Flavor({required this.manifestUrl, required this.name, required this.bundleId});

  static final List<Flavor> _supportedFlavors = [
    Flavor(
        manifestUrl: 'https://sometestproject12345.humhub.com/manifest.json',
        name: "DEMO",
        bundleId: 'com.humhub.somedemoproject12345.app'),
    Flavor(
        manifestUrl: 'https://community.humhub.com/manifest.json',
        name: "Humhub Community",
        bundleId: 'com.humhub.community.app'),
  ];

  static Flavor get(String bundleId) => _supportedFlavors.firstWhere((flavor) => flavor.bundleId == bundleId);

  static Future<HumHub?> getInstance(String bundleId) async {
    Flavor flavor = get(bundleId);
    FlavoredOpenerController opener = FlavoredOpenerController(url: flavor.manifestUrl);
    HumHub? instance = await opener.initHumHub();
    return instance;
  }
}
