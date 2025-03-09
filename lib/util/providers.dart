import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/file_upload_settings.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/manifest.dart';

import 'const.dart';

class HumHubNotifier extends ChangeNotifier {
  final HumHub _humHubInstance;
  late String lastUrl;

  HumHubNotifier(this._humHubInstance);

  OpenerState get openerState => _humHubInstance.openerState;
  Manifest? get manifest => _humHubInstance.manifest;
  String? get randomHash => _humHubInstance.randomHash;
  String? get appVersion => _humHubInstance.appVersion;
  String? get pushToken => _humHubInstance.pushToken;
  String? get manifestUrl => _humHubInstance.manifestUrl;
  Map<String, String> get customHeaders => _humHubInstance.customHeaders;
  List<Manifest> get history => _humHubInstance.history;
  FileUploadSettings? get fileUploadSettings => _humHubInstance.fileUploadSettings;

  void setOpenerState(OpenerState state) {
    _humHubInstance.openerState = state;
    _updateSafeStorage();
    notifyListeners();
  }

  Future<void> setInstance(HumHub instance) async {
    HumHub copy = copyWith(
      openerState: instance.openerState,
      manifest: instance.manifest,
      randomHash: instance.randomHash,
      appVersion: instance.appVersion,
      pushToken: instance.pushToken,
      customHeaders: instance.customHeaders,
      history: instance.history,
      manifestUrl: instance.manifestUrl,
      fileUploadSettings: instance.fileUploadSettings,
    );
    _humHubInstance.manifest = copy.manifest;
    _humHubInstance.openerState = copy.openerState;
    _humHubInstance.randomHash = copy.randomHash;
    _humHubInstance.appVersion = copy.appVersion;
    _humHubInstance.manifestUrl = copy.manifestUrl;
    _humHubInstance.history = copy.history;
    _humHubInstance.history = copy.history;
    _humHubInstance.fileUploadSettings = copy.fileUploadSettings;
    _updateSafeStorage();
    notifyListeners();
  }

  void setFileUploadSettings(FileUploadSettings settings) {
    _humHubInstance.fileUploadSettings = settings;
    _updateSafeStorage();
    notifyListeners();
  }

  HumHub copyWith({
    OpenerState? openerState,
    Manifest? manifest,
    String? randomHash,
    String? appVersion,
    String? pushToken,
    Map<String, String>? customHeaders,
    List<Manifest>? history,
    String? manifestUrl,
    FileUploadSettings? fileUploadSettings,
  }) {
    HumHub instance = HumHub(
      openerState: openerState ?? this.openerState,
      manifest: manifest ?? this.manifest,
      randomHash: randomHash ?? this.randomHash,
      appVersion: appVersion ?? this.appVersion,
      pushToken: pushToken ?? this.pushToken,
      history: history ?? this.history,
      manifestUrl: manifestUrl ?? this.manifestUrl,
      fileUploadSettings: fileUploadSettings ?? this.fileUploadSettings,
    );
    _humHubInstance.manifest = instance.manifest;
    _humHubInstance.openerState = instance.openerState;
    _humHubInstance.randomHash = instance.randomHash;
    _humHubInstance.manifestUrl = instance.manifestUrl;
    _humHubInstance.history = instance.history;
    _humHubInstance.fileUploadSettings = instance.fileUploadSettings;
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

  Future<void> clearSafeStorage() async {
    await InternalStorage.storage.delete(key: InternalStorage.keyHumhubInstance);
  }

  Future<HumHub> getInstance() async {
    var jsonStr = await InternalStorage.storage.read(key: InternalStorage.keyHumhubInstance);
    HumHub humHub = jsonStr != null ? HumHub.fromJson(json.decode(jsonStr)) : _humHubInstance;
    lastUrl = await InternalStorage.storage.read(key: InternalStorage.keyLastInstanceUrl) ?? "";

    /// Download icons for shortcuts if not yet saved in internal storage
    for (var value in humHub.history) {
      if (value.shortcutIcon == null) {
        await value.getBase64Icon();
      }
    }

    setInstance(humHub);

    return humHub;
  }

  Future<void> _updateSafeStorage() async {
    final jsonString = json.encode(_humHubInstance.toJson());

    String lastUrl = (_humHubInstance.manifestUrl != null ? _humHubInstance.manifestUrl! : this.lastUrl);

    await InternalStorage.storage.write(key: InternalStorage.keyHumhubInstance, value: jsonString);

    await InternalStorage.storage.write(key: InternalStorage.keyLastInstanceUrl, value: lastUrl);
  }
}

final humHubProvider = ChangeNotifierProvider<HumHubNotifier>((ref) {
  return HumHubNotifier(HumHub());
});
