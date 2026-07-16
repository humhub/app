import 'package:flutter/services.dart';
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
    final value = await _instance.read(key: keys.hasVisitedSettings);
    return value == 'true';
  }

  /// Marks that user has visited settings.
  static Future<void> setVisitedSettings() async {
    await write(key: keys.hasVisitedSettings, value: 'true');
  }

  /// Writes to secure storage, recovering from a stale Keychain entry left behind
  /// by a restored backup (where the "first run" flag came back `true` along with it).
  static Future<void> write({required String key, required String? value}) async {
    try {
      await _instance.write(key: key, value: value);
    } on PlatformException catch (e) {
      if (e.code == '-25299') {
        await _instance.delete(key: key);
        await _instance.write(key: key, value: value);
      } else {
        rethrow;
      }
    }
  }
}

class _Keys {
  String humhubInstance = "humHubInstance";
  String lastInstanceUrl = "humHubLastUrl";
  String keyErrorReports = 'send_error_reports';
  String keyDeviceIdentifiers = 'send_device_identifiers';
  String hasVisitedSettings = 'hasVisitedSettings';
}
