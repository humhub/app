import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:humhub/models/global_package_info.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/manifest.dart';

import 'const.dart';

class HumHubNotifier extends ChangeNotifier {
  final HumHub _humHubInstance;

  HumHubNotifier(this._humHubInstance);

  final _storage = const FlutterSecureStorage();

  OpenerState get openerState => _humHubInstance.openerState;
  Manifest? get manifest => _humHubInstance.manifest;
  String? get randomHash => _humHubInstance.randomHash;
  String? get appVersion => _humHubInstance.appVersion;
  String? get pushToken => _humHubInstance.pushToken;
  String? get manifestUrl => _humHubInstance.manifestUrl;
  Map<String, String> get customHeaders => _humHubInstance.customHeaders;
  List<Manifest> get history => _humHubInstance.history;

  void setOpenerState(OpenerState state) {
    _humHubInstance.openerState = state;
    _updateSafeStorage();
    notifyListeners();
  }

  Future<void> setInstance(HumHub instance) async {
    _humHubInstance.manifest = instance.manifest;
    _humHubInstance.openerState = instance.openerState;
    _humHubInstance.randomHash = instance.randomHash;
    _humHubInstance.appVersion = GlobalPackageInfo.info.version;
    _humHubInstance.manifestUrl = instance.manifestUrl;
    _humHubInstance.history = instance.history;
    _updateSafeStorage();
    notifyListeners();
  }

  // Add a copyWith method
  HumHub copyWith({
    OpenerState? openerState,
    Manifest? manifest,
    String? randomHash,
    String? appVersion,
    String? pushToken,
    Map<String, String>? customHeaders,
    List<Manifest>? history,
    String? manifestUrl,
  }) {
    HumHub instance =  HumHub(
      openerState: openerState ?? this.openerState,
      manifest: manifest ?? this.manifest,
      randomHash: randomHash ?? this.randomHash,
      appVersion: appVersion ?? this.appVersion,
      pushToken: pushToken ?? this.pushToken,
      history: history ?? this.history,
      manifestUrl: manifestUrl ?? this.manifestUrl,
    );
    _humHubInstance.manifest = instance.manifest;
    _humHubInstance.openerState = instance.openerState;
    _humHubInstance.randomHash = instance.randomHash;
    _humHubInstance.manifestUrl = instance.manifestUrl;
    _humHubInstance.history = instance.history;
    _updateSafeStorage();
    notifyListeners();
    return instance;
  }

  Future<void> removeHistory(Manifest manifest) async {
    _humHubInstance.removeFromHistory(manifest);
    _updateSafeStorage();
    notifyListeners();
  }

  Future<void> addOrUpdateHistory(Manifest manifest) async {
    _humHubInstance.addOrUpdateHistory(manifest);
    _updateSafeStorage();
    notifyListeners();
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
