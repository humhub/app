import 'package:dio/dio.dart';

class Manifest {
  final String display;
  final String startUrl;
  final String shortName;
  final String name;
  final String backgroundColor;
  final String themeColor;

  Manifest(this.display, this.startUrl, this.shortName, this.name,
      this.backgroundColor, this.themeColor);

  String get baseUrl {
    int index = startUrl.indexOf("humhub.com");
    if (index != -1) {
      return startUrl.substring(0, index + "humhub.com".length);
    }
    throw Exception("Can't define base url");
  }

  factory Manifest.fromJson(Map<String, dynamic> json) {
    return Manifest(
      json['display'] as String,
      json['start_url'] as String,
      json['short_name'] as String,
      json['name'] as String,
      json['background_color'] as String,
      json['theme_color'] as String,
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
        final res = await dio.get('$url/manifest.json');
        return Manifest.fromJson(res.data);
      };
}
