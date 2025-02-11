import 'package:dio/dio.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/crypt.dart';
import 'package:humhub/util/openers/universal_opener_controller.dart';
import 'package:quick_actions/quick_actions.dart';

import '../util/quick_actions/quick_action_provider.dart';

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
    List<ManifestIcon>? iconsList = iconsJson?.map((icon) => ManifestIcon.fromJson(icon as Map<String, dynamic>)).toList();

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
          type: Crypt.generateHash(startUrl, 16),
          localizedTitle: name,
          localizedSubtitle: name,
          //icon: 'ic_launcher',
          base64Icon: "data:image/png;base64,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",
        ),
        action: () async {
          UniversalOpenerController opener = UniversalOpenerController(url: startUrl);
          await opener.initHumHub();
          // TODO: WebView.path or WebViewF.path
          Keys.navigatorKey.currentState!.pushNamed(WebView.path, arguments: opener);
        });
  }
}
