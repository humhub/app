import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:humhub/models/manifest.dart';

class ManifestF extends Manifest {
  ManifestF(
      {required String display,
      required String startUrl,
      required String shortName,
      required String name,
      required String backgroundColor,
      required String themeColor})
      : super(
            display: display,
            startUrl: startUrl,
            shortName: shortName,
            name: name,
            backgroundColor: backgroundColor,
            themeColor: themeColor);

  factory ManifestF.fromEnv() {
    return ManifestF(
      display: dotenv.env['DISPLAY']!,
      startUrl: dotenv.env['START_URL']!,
      shortName: dotenv.env['SHORT_NAME']!,
      name: dotenv.env['NAME']!,
      backgroundColor: dotenv.env['BACKGROUND_COLOR']!,
      themeColor: dotenv.env['THEME_COLOR']!,
    );
  }
}
