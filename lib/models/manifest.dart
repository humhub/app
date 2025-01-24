import 'package:dio/dio.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/openers/universal_opener_controller.dart';
import 'package:loggy/loggy.dart';
import 'package:quick_actions/quick_actions.dart';
import '../util/quick_actions/quick_actions_provider.dart';

class ManifestIcon {
  final String src;
  final String type;
  final String sizes;

  ManifestIcon({required this.src, required this.type, required this.sizes});

  factory ManifestIcon.fromJson(Map<String, dynamic> json) {
    return ManifestIcon(
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

class Manifest {
  final String display;
  final String startUrl;
  final String shortName;
  final String name;
  final String backgroundColor;
  final String themeColor;
  final List<ManifestIcon>? icons;

  Manifest({
    required this.display,
    required this.startUrl,
    required this.shortName,
    required this.name,
    required this.backgroundColor,
    required this.themeColor,
    required this.icons,
  });

  String get baseUrl {
    Uri url = Uri.parse(startUrl);
    return url.origin;
  }

  factory Manifest.fromJson(Map<String, dynamic> json) {
    var iconsJson = json['icons'] as List<dynamic>?;
    List<ManifestIcon>? iconsList =
        iconsJson?.map((icon) => ManifestIcon.fromJson(icon as Map<String, dynamic>)).toList();

    return Manifest(
      display: json['display'] as String,
      startUrl: json['start_url'] as String,
      shortName: json['short_name'] as String,
      name: json['name'] as String,
      backgroundColor: json['background_color'] as String,
      themeColor: json['theme_color'] as String,
      icons: iconsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'display': display,
        'start_url': startUrl,
        'short_name': shortName,
        'name': name,
        'background_color': backgroundColor,
        'theme_color': themeColor,
        'icons': icons?.map((icon) => icon.toJson()).toList(),
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

  InternalShortcut get shortcut {
    return InternalShortcut(
        shortcut: ShortcutItem(
          type: startUrl,
          localizedTitle: name,
          localizedSubtitle: name,
          icon: 'ic_launcher',
        ),
        action: () async {
          logInfo('MD222- shotcut on action');
          UniversalOpenerController opener = UniversalOpenerController(url: startUrl);
          await opener.initHumHub();
          Keys.navigatorKey.currentState!.pushNamed(WebView.path, arguments: opener);
        });
  }
}
