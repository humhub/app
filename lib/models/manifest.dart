import 'package:dio/dio.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/crypt.dart';
import 'package:humhub/util/openers/universal_opener_controller.dart';
import 'package:loggy/loggy.dart';
import 'package:quick_actions/quick_actions.dart';

import '../util/quick_actions/quick_action_provider.dart';

import 'dart:convert';
import 'dart:typed_data';

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
  String? shortcutIcon;

  Manifest({
    required this.display,
    required this.startUrl,
    required this.shortName,
    required this.name,
    required this.backgroundColor,
    required this.themeColor,
    required this.icons,
    this.shortcutIcon,
  });

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
      icons: (json['icons'] as List<dynamic>?)
          ?.map((icon) => ManifestIcon.fromJson(icon as Map<String, dynamic>))
          .toList(),
      shortcutIcon: json['shortcutIcon'] as String?,
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
        'shortcutIcon': shortcutIcon
      };

  static Future<Manifest> Function(Dio dio) get(String url) => (dio) async {
        Response<dynamic> res = await dio.get(url);
        Manifest manifest = Manifest.fromJson(res.data);
        await manifest.getBase64Icon();
        return manifest;
      };

  /// Asynchronous method to fetch and convert the icon to Base64
  Future<String?> getBase64Icon() async {
    if (icons == null || icons!.isEmpty) throw Exception("No icons found");
    ManifestIcon icon = icons!.first;
    String iconUrl = baseUrl + icon.src;
    if (shortcutIcon != null) {
      return shortcutIcon!;
    }
    try {
      Response<List<int>> response = await Dio().get<List<int>>(
        iconUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Convert image bytes to Base64
        Uint8List bytes = Uint8List.fromList(response.data!);
        shortcutIcon = base64Encode(bytes);
        return shortcutIcon!;
      } else {
        logError('Failed to load image from ${icon.src}');
      }
    } catch (e) {
      logError('Error fetching or converting image: $e');
    }
    return null;
  }

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
    return !isUriPretty
        ? '$url/index.php?r=web%2Fpwa-manifest%2Findex'
        : '$url/manifest.json';
  }

  InternalShortcut get shortcut {
    return InternalShortcut(
        shortcut: ShortcutItem(
          type: Crypt.generateHash(startUrl, 16),
          localizedTitle: name,
          base64Icon: shortcutIcon,
        ),
        action: () async {
          UniversalOpenerController opener =
              UniversalOpenerController(url: startUrl);
          await opener.initHumHub();
          Keys.navigatorKey.currentState!
              .pushNamed(WebView.path, arguments: opener);
        });
  }
}
