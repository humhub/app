import 'package:dio/dio.dart';

class Manifest {
  final String display;
  final String startUrl;
  final String shortName;
  final String name;
  final String backgroundColor;
  final String themeColor;

  Manifest({required this.display, required this.startUrl, required this.shortName, required this.name, required this.backgroundColor, required this.themeColor});

  String get baseUrl {
    Uri url = Uri.parse(startUrl);
    return url.origin;
  }

  factory Manifest.fromJson(Map<String, dynamic> json) {
    return Manifest(
      display: json['display'] as String,
      startUrl: json['start_url'] as String,
      shortName: json['short_name'] as String,
      name: json['name'] as String,
      backgroundColor: json['background_color'] as String,
      themeColor: json['theme_color'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'display': display,
        'start_url': startUrl,
        'short_name': shortName,
        'name': name,
        'background_color': backgroundColor,
        'theme_color': themeColor,
      };

  static Future<Manifest> Function(Dio dio) get(String url) => (dio) async {
        Response<dynamic> res = await dio.get(url);
        return Manifest.fromJson(res.data);
      };

  static String defineUrl(String url, {bool isUriPretty = true}) {
    return !isUriPretty ? '$url/index.php?r=web%2Fpwa-manifest%2Findex' : '$url/manifest.json';
  }
}
