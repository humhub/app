import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/manifest.dart';

class HumHubNotifier extends ChangeNotifier {
  final HumHub _humHubInstance;

  HumHubNotifier(this._humHubInstance);

  final _storage = const FlutterSecureStorage();

  bool get isHideDialog => _humHubInstance.isHideDialog;
  Manifest? get manifest => _humHubInstance.manifest;

  void setIsHideDialog(bool isHide) {
    _humHubInstance.isHideDialog = isHide;
    _updateSafeStorage();
    notifyListeners();
  }

  void setManifest(Manifest manifest) {
    _humHubInstance.manifest = manifest;
    _updateSafeStorage();
    notifyListeners();
  }

  void setInstance(HumHub instance) {
    _humHubInstance.manifest = instance.manifest;
    _humHubInstance.isHideDialog = instance.isHideDialog;
    _updateSafeStorage();
    notifyListeners();
  }

  _updateSafeStorage() async {
    final jsonString = json.encode(_humHubInstance.toJson());
    await _storage.write(key: "hum_hub", value: jsonString);
  }

  clearSafeStorage() async {
    await _storage.delete(key: "hum_hub");
  }

  Future<HumHub> getInstance() async {
    var jsonStr = await _storage.read(key: "hum_hub");
    HumHub humHub = jsonStr != null
        ? HumHub.fromJson(json.decode(jsonStr))
        : _humHubInstance;
    return humHub;
  }
}

final humHubProvider = ChangeNotifierProvider<HumHubNotifier>((ref) {
  return HumHubNotifier(HumHub());
});
