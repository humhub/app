import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/file_upload_settings.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/models/remote_config.dart';
import 'package:humhub/util/storage_service.dart';

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
  RemoteConfig? get remoteConfig => _humHubInstance.remoteConfig;
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
      remoteConfig: instance.remoteConfig,
    );
    _humHubInstance.manifest = copy.manifest;
    _humHubInstance.openerState = copy.openerState;
    _humHubInstance.randomHash = copy.randomHash;
    _humHubInstance.appVersion = copy.appVersion;
    _humHubInstance.manifestUrl = copy.manifestUrl;
    _humHubInstance.history = copy.history;
    _humHubInstance.history = copy.history;
    _humHubInstance.fileUploadSettings = copy.fileUploadSettings;
    _humHubInstance.fileUploadSettings = copy.fileUploadSettings;
    _humHubInstance.remoteConfig = copy.remoteConfig;
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
    RemoteConfig? remoteConfig,
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
      remoteConfig: remoteConfig ?? this.remoteConfig,
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
    await SecureStorageService.instance.delete(key: SecureStorageService.keys.humhubInstance);
  }

  Future<HumHub> getInstance() async {
    var jsonStr = await SecureStorageService.instance.read(key: SecureStorageService.keys.humhubInstance);
    HumHub humHub = jsonStr != null ? HumHub.fromJson(json.decode(jsonStr)) : _humHubInstance;
    lastUrl = await SecureStorageService.instance.read(key: SecureStorageService.keys.lastInstanceUrl) ?? "";

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

    await SecureStorageService.instance.write(key: SecureStorageService.keys.humhubInstance, value: jsonString);

    await SecureStorageService.instance.write(key: SecureStorageService.keys.lastInstanceUrl, value: lastUrl);
  }
}

final humHubProvider = ChangeNotifierProvider<HumHubNotifier>((ref) {
  return HumHubNotifier(HumHub());
});
