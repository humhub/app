import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/api_provider.dart';

enum RedirectAction { opener, webView }

class HumHub {
  Manifest? manifest;
  bool isHideDialog;
  String? randomHash;

  HumHub({
    this.manifest,
    this.isHideDialog = false,
    this.randomHash,
  });

  Map<String, dynamic> toJson() => {
        'manifest': manifest != null ? manifest!.toJson() : null,
        'isHideDialog': isHideDialog,
        'randomHash': randomHash,
      };

  factory HumHub.fromJson(Map<String, dynamic> json) {
    return HumHub(
      manifest: Manifest.fromJson(json['manifest']),
      isHideDialog: json['isHideDialog'] as bool,
      randomHash: json['randomHash'],
    );
  }

  Future<RedirectAction> action(ref) async {
    if (!isHideDialog) {
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
}
