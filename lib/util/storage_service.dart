import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  // Private constructor
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
      FlutterSecureStorage storage = const FlutterSecureStorage();
      await storage.deleteAll();
      prefs.setBool(key, true);
    }
  }
}
