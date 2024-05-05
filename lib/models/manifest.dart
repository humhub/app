import 'package:dio/dio.dart';

class Manifest {
  final String display;
  final String startUrl;
  final String shortName;
  final String name;
  final String backgroundColor;
  final String themeColor;

  Manifest(this.display, this.startUrl, this.shortName, this.name, this.backgroundColor, this.themeColor);

  String get baseUrl {
    Uri url = Uri.parse(startUrl);
    return url.origin;
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
        Response<dynamic> res = await dio.get(url);
        return Manifest.fromJson(res.data);
      };

  static String getUriWithoutExtension(String url) {
    Uri uri = Uri.parse(url);
    List<String> pathSegments = List.from(uri.pathSegments);

    if (pathSegments.isNotEmpty) {
      pathSegments.removeLast();
    }

    Uri modifiedUri = uri.replace(pathSegments: pathSegments);
    return modifiedUri.toString();
  }

  static String defineUrl(String url, {bool isUriPretty = true}) {
    return !isUriPretty ? '$url/index.php?r=web%2Fpwa-manifest%2Findex' : '$url/manifest.json';
  }
}
