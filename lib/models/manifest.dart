import 'package:dio/dio.dart';

// Class representing an individual icon
class Icon {
  final String src;
  final String type;
  final String sizes;

  Icon({required this.src, required this.type, required this.sizes});

  factory Icon.fromJson(Map<String, dynamic> json) {
    return Icon(
      src: json['src'] as String,
      type: json['type'] as String,
      sizes: json['sizes'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'src': src,
    'type': type,
    'sizes': sizes,
  };
}

// Modified Manifest class to support icons
class Manifest {
  final String display;
  final String startUrl;
  final String shortName;
  final String name;
  final String backgroundColor;
  final String themeColor;
  final List<Icon> icons;  // Added list of icons

  Manifest({
    required this.display,
    required this.startUrl,
    required this.shortName,
    required this.name,
    required this.backgroundColor,
    required this.themeColor,
    required this.icons,  // Require icons as well
  });

  String get baseUrl {
    Uri url = Uri.parse(startUrl);
    return url.origin;
  }

  // Modified fromJson method to handle the icons array
  factory Manifest.fromJson(Map<String, dynamic> json) {
    var iconsList = (json['icons'] as List<dynamic>?)
        ?.map((icon) => Icon.fromJson(icon as Map<String, dynamic>))
        .toList();

    return Manifest(
      display: json['display'] as String,
      startUrl: json['start_url'] as String,
      shortName: json['short_name'] as String,
      name: json['name'] as String,
      backgroundColor: json['background_color'] as String,
      themeColor: json['theme_color'] as String,
      icons: iconsList ?? [],  // If no icons, return an empty list
    );
  }

  // Modified toJson method to handle the icons array
  Map<String, dynamic> toJson() => {
    'display': display,
    'start_url': startUrl,
    'short_name': shortName,
    'name': name,
    'background_color': backgroundColor,
    'theme_color': themeColor,
    'icons': icons.map((icon) => icon.toJson()).toList(),  // Convert icons to JSON
  };

  static Future<Manifest> Function(Dio dio) get(String url) => (dio) async {
    Response<dynamic> res = await dio.get(url);
    return Manifest.fromJson(res.data);
  };

  static String getUriWithoutExtension(String url) {
    int lastSlashIndex = url.lastIndexOf('/');
    // If there is no slash or only one character after the last slash, return the original URL
    if (lastSlashIndex < 0 || lastSlashIndex == url.length - 1) {
      return url;
    }
    // Remove everything after the last slash, including the slash itself
    return url.substring(0, lastSlashIndex);
  }

  static String defineUrl(String url, {bool isUriPretty = true}) {
    return !isUriPretty ? '$url/index.php?r=web%2Fpwa-manifest%2Findex' : '$url/manifest.json';
  }
}
