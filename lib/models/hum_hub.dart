import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/api_provider.dart';

enum RedirectAction { opener, webView, flavored }

class HumHub {
  Manifest? manifest;
  bool isHideOpener;
  String? randomHash;
  String? appVersion;
  String? pushToken;

  HumHub({
    this.manifest,
    this.isHideOpener = false,
    this.randomHash,
    this.appVersion,
    this.pushToken
  });

  Map<String, dynamic> toJson() => {
        'manifest': manifest?.toJson(),
        'isHideDialog': isHideOpener,
        'randomHash': randomHash,
        'appVersion': appVersion,
        'pushToken': pushToken,
      };

  factory HumHub.fromJson(Map<String, dynamic> json) {
    return HumHub(
      manifest:
          json['manifest'] != null ? Manifest.fromJson(json['manifest']) : null,
      isHideOpener: json['isHideDialog'] as bool,
      randomHash: json['randomHash'],
      appVersion: json['appVersion'],
      pushToken: json['pushToken'],
    );
  }

  Future<RedirectAction> action(ref) async {
    if (!isHideOpener) {
      return RedirectAction.opener;
    } else {
      if (manifest != null) {
        AsyncValue<Manifest> asyncData = await APIProvider.of(ref).request(
          Manifest.get(manifest!.baseUrl),
        );
        if (asyncData.hasError) {
          return RedirectAction.opener;
        } else {
          return RedirectAction.webView;
        }
      }
      return RedirectAction.webView;
    }
  }

  static String generateHash(int length) {
    final random = Random.secure();
    const characters = '0123456789abcdef';
    return List.generate(
        length, (_) => characters[random.nextInt(characters.length)]).join();
  }

  Map<String, String> get customHeaders =>{
    'x-humhub-app-token': randomHash!,
    'x-humhub-app': appVersion ?? '1.0.0',
    'x-humhub-app-ostate': isHideOpener ? '1' : '0'
  };
}
