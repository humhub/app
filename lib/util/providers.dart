import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/manifest.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'const.dart';

class HumHubNotifier extends ChangeNotifier {
  final HumHub _humHubInstance;

  HumHubNotifier(this._humHubInstance);

  final _storage = const FlutterSecureStorage();

  bool get isHideDialog => _humHubInstance.isHideOpener;
  Manifest? get manifest => _humHubInstance.manifest;
  String? get randomHash => _humHubInstance.randomHash;
  String? get appVersion => _humHubInstance.appVersion;
  String? get pushToken => _humHubInstance.pushToken;
  Map<String, String> get customHeaders => _humHubInstance.customHeaders;

  void setIsHideOpener(bool isHide) {
    _humHubInstance.isHideOpener = isHide;
    _updateSafeStorage();
    notifyListeners();
  }

  void setManifest(Manifest manifest) {
    _humHubInstance.manifest = manifest;
    _updateSafeStorage();
    notifyListeners();
  }

  Future<void> setInstance(HumHub instance) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _humHubInstance.manifest = instance.manifest;
    _humHubInstance.isHideOpener = instance.isHideOpener;
    _humHubInstance.randomHash = instance.randomHash;
    _humHubInstance.appVersion = packageInfo.version;
    _humHubInstance.manifestUrl = instance.manifestUrl;
    _updateSafeStorage();
    notifyListeners();
  }

  static Future<void> setInstanceStatic(HumHub instance) async {
    final jsonString = json.encode(instance.toJson());
    var storage = const FlutterSecureStorage();
    var lastUrlFromStore = await storage.read(key: StorageKeys.lastInstanceUrl);
    String? lastUrl = instance.manifestUrl != null ? instance.manifestUrl! : lastUrlFromStore;
    await storage.write(key: StorageKeys.humhubInstance, value: jsonString);
    await storage.write(key: StorageKeys.lastInstanceUrl, value: lastUrl);
  }

  void setHash(String hash) {
    _humHubInstance.randomHash = hash;
    _updateSafeStorage();
    notifyListeners();
  }

  void setToken(String token) {
    _humHubInstance.pushToken = token;
    _updateSafeStorage();
    notifyListeners();
  }

  _updateSafeStorage() async {
    final jsonString = json.encode(_humHubInstance.toJson());
    String lastUrl = _humHubInstance.manifestUrl != null ? _humHubInstance.manifestUrl! : await getLastUrl();
    await _storage.write(key: StorageKeys.humhubInstance, value: jsonString);
    await _storage.write(key: StorageKeys.lastInstanceUrl, value: lastUrl);
  }

  clearSafeStorage() async {
    await _storage.delete(key: StorageKeys.humhubInstance);
  }

  Future<HumHub> getInstance() async {
    var jsonStr = await _storage.read(key: StorageKeys.humhubInstance);
    HumHub humHub = jsonStr != null ? HumHub.fromJson(json.decode(jsonStr)) : _humHubInstance;
    setInstance(humHub);
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
