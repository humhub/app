import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Manifest {
  final String display;
  final String startUrl;
  final String shortName;
  final String name;
  final String backgroundColor;
  final String themeColor;

  Manifest(this.display, this.startUrl, this.shortName, this.name,
      this.backgroundColor, this.themeColor);

  static empty() {
    return Manifest(
      '',
      '',
      '',
      '',
      '',
      '',
    );
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

  static Future<Manifest> Function(Dio dio) get(String url) => (dio) async {
        final res = await dio.get('$url/manifest.json');
        return Manifest.fromJson(res.data);
      };
}

final manifestStateProvider = StateProvider<Manifest>((ref) {
  return Manifest.empty();
});
