import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/manifest.dart';

import 'const.dart';

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
    String lastUrl = _humHubInstance.manifest != null ? _humHubInstance.manifest!.baseUrl : await getLastUrl();
    await _storage.write(key: StorageKeys.humhubInstance, value: jsonString);
    await _storage.write(key: StorageKeys.lastInstanceUrl, value: lastUrl);
  }

  clearSafeStorage() async {
    await _storage.delete(key: StorageKeys.humhubInstance);
  }

  Future<HumHub> getInstance() async {
    var jsonStr = await _storage.read(key: StorageKeys.humhubInstance);
    HumHub humHub = jsonStr != null
        ? HumHub.fromJson(json.decode(jsonStr))
        : _humHubInstance;
    return humHub;
  }

  Future<String> getLastUrl() async {
    var lastUrl = await _storage.read(key: StorageKeys.lastInstanceUrl);
    return lastUrl ?? "";
  }
}

final humHubProvider = ChangeNotifierProvider<HumHubNotifier>((ref) {
  return HumHubNotifier(HumHub());
});
