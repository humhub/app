import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'manifest.dart';

class HumHub{
  Manifest? manifest;
  bool isHideDialog;


  HumHub({this.manifest, this.isHideDialog = false});

  void setManifest(Manifest manifest) {
    this.manifest = manifest;
  }

  void setHideDialog(bool isHide) {
    isHideDialog = isHide;
  }

  Map<String, dynamic> toJson() => {
    'manifest': manifest!.toJson(),
    'isHideDialog': isHideDialog,
  };
}

class HumHubNotifier extends ChangeNotifier{
  final HumHub _humHubInstance;

  HumHubNotifier(this._humHubInstance);

  final _storage = const FlutterSecureStorage();

  bool get isHideDialog => _humHubInstance.isHideDialog;

  void setIsHideDialog(bool isHide) {
    _humHubInstance.isHideDialog = isHide;
    _updateSafeStorage();
    notifyListeners();
  }

  _updateSafeStorage() async {
    final jsonString = json.encode(_humHubInstance.toJson());
    await _storage.write(key: "hum_hub", value: jsonString);
  }
}

final humHubProvider = ChangeNotifierProvider<HumHubNotifier>((ref) {
  return HumHubNotifier(HumHub());
});
