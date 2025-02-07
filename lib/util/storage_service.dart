import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StorageKey {
  instance("humhub_instance"),
  lastUrl("humhub_last_url");

  final String value;

  const StorageKey(this.value);

  static StorageKey? fromValue(String value) {
    return StorageKey.values.firstWhere(
          (element) => element.value == value,
    );
  }

  // Method to return all storage keys
  static List<String> getAllKeys() {
    return StorageKey.values.map((e) => e.value).toList();
  }
}


class SecureStorageService {
  static const FlutterSecureStorage _instance = FlutterSecureStorage();

  factory SecureStorageService() {
    return SecureStorageService._internal();
  }

  SecureStorageService._internal();

  static FlutterSecureStorage get instance => _instance;

  static clearSecureStorageOnReinstall() async {
    String key = 'hasRunBefore';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasRunBefore = prefs.getBool(key) ?? false;
    if (!hasRunBefore) {
      FlutterSecureStorage storage = const FlutterSecureStorage();
      await storage.deleteAll();
      prefs.setBool(key, true);
    }
  }
}
