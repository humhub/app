import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  // Private constructor
  static var keys = _Keys();
  static const FlutterSecureStorage _instance = FlutterSecureStorage();

  // Factory constructor that returns the single instance
  factory SecureStorageService() {
    return SecureStorageService._internal();
  }

  // Private named constructor
  SecureStorageService._internal();

  // Method to access the single instance of FlutterSecureStorage
  static FlutterSecureStorage get instance => _instance;

  static clearSecureStorageOnReinstall() async {
    String key = 'hasRunBefore';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasRunBefore = prefs.getBool(key) ?? false;
    if (!hasRunBefore) {
      await _instance.deleteAll();
      prefs.setBool(key, true);
    }
  }

  static Future<bool> hasVisitedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keys.hasVisitedSettings) ?? false;
  }

  /// Marks that user has visited settings.
  static Future<void> setVisitedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keys.hasVisitedSettings, true);
  }
}

class _Keys {
  String humhubInstance = "humHubInstance";
  String lastInstanceUrl = "humHubLastUrl";
  String keyErrorReports = 'send_error_reports';
  String keyDeviceIdentifiers = 'send_device_identifiers';
  String hasVisitedSettings = 'hasVisitedSettings';
}
