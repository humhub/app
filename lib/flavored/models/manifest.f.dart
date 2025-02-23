import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:humhub/models/manifest.dart';

class ManifestF extends Manifest {
  ManifestF(
      {required super.display,
      required super.startUrl,
      required super.shortName,
      required super.name,
      required super.backgroundColor,
      required super.themeColor,
      super.icons});

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
