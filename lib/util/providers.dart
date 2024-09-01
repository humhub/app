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
  final _storage = const FlutterSecureStorage();

  // Initialize a list to store the last three instances
  List<HumHub> _lastThreeInstances = [];

  HumHubNotifier(this._humHubInstance);

  bool get isHideDialog => _humHubInstance.isHideOpener;
  String? get randomHash => _humHubInstance.randomHash;
  String? get appVersion => _humHubInstance.appVersion;
  String? get pushToken => _humHubInstance.pushToken;
  Manifest? get manifest => _humHubInstance.manifest;
  String? get manifestUrl => _humHubInstance.manifestUrl;
  HumHub get instance => _humHubInstance;
  Map<String, String> get customHeaders => _humHubInstance.customHeaders;

  // Getters for the last three instances
  List<HumHub> get lastThreeInstances => _lastThreeInstances;

  Future<void> setInstance(HumHub instance) async {
    // Update the current instance
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _humHubInstance.manifest = instance.manifest;
    _humHubInstance.isHideOpener = instance.isHideOpener;
    _humHubInstance.randomHash = instance.randomHash;
    _humHubInstance.appVersion = packageInfo.version;
    _humHubInstance.manifestUrl = instance.manifestUrl;

    // Update the list of the last three instances
    _addInstanceToHistory(instance);

    _updateSafeStorage();
    notifyListeners();
  }

  Future<void> setProps(
      {Manifest? manifest, bool? hideOpener, String? randomHash, String? manifestUrl, String? pushToken}) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (manifest != null) _humHubInstance.manifest = manifest;
    if (hideOpener != null) _humHubInstance.isHideOpener = hideOpener;
    if (randomHash != null) _humHubInstance.randomHash = randomHash;
    _humHubInstance.appVersion = packageInfo.version;
    if (manifestUrl != null) _humHubInstance.manifestUrl = manifestUrl;
    if (pushToken != null) _humHubInstance.pushToken = pushToken;

    _addInstanceToHistory(_humHubInstance);

    _updateSafeStorage();
    notifyListeners();
  }

  // Adds a new instance to the history, maintaining a maximum of three instances
  void _addInstanceToHistory(HumHub instance) {
    if (instance.manifest == null) return;
    _lastThreeInstances.insert(0, instance);
    if (_lastThreeInstances.length > 3) {
      _lastThreeInstances.removeLast();
    }
  }

  // Update the secure storage with the list of the last three instances
  _updateSafeStorage() async {
    final jsonString = json.encode(_lastThreeInstances.map((e) => e.toJson()).toList());
    await _storage.write(key: StorageKeys.humhubInstance, value: jsonString);
  }

  // Clear the secure storage
  clearSafeStorage() async {
    await _storage.delete(key: StorageKeys.humhubInstance);
  }

  // Retrieve the last three instances from secure storage
  Future<void> init() async {
    var jsonStr = await _storage.read(key: StorageKeys.humhubInstance);
    if (jsonStr != null) {
      List<dynamic> jsonList = json.decode(jsonStr);
      _lastThreeInstances = jsonList.map((json) => HumHub.fromJson(json)).toList();
      if (_lastThreeInstances.isNotEmpty) {
         setInstance(_lastThreeInstances.first);
      }
    }
    notifyListeners();
  }
}

final humHubProvider = ChangeNotifierProvider<HumHubNotifier>((ref) {
  return HumHubNotifier(HumHub());
});
