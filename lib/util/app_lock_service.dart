import 'package:local_auth/local_auth.dart';
import 'package:loggy/loggy.dart';

/// Thin wrapper around [LocalAuthentication] so the rest of the app never
/// talks to the plugin directly. Relies entirely on the OS unlock prompt
/// (biometrics with a fallback to device PIN/pattern/passcode) — we never
/// build our own PIN handling.
class AppLockService {
  AppLockService._();

  static final LocalAuthentication _auth = LocalAuthentication();

  /// Whether the device has any form of screen lock configured (biometrics
  /// or a PIN/pattern/passcode). If this is false, app lock can't be offered.
  static Future<bool> get isDeviceSupported async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e, stack) {
      logError('AppLockService.isDeviceSupported failed: $e', e, stack);
      return false;
    }
  }

  /// Shows the native OS unlock prompt. Returns true only on a successful
  /// authentication; any error or user cancellation returns false.
  static Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (e, stack) {
      logError('AppLockService.authenticate failed: $e', e, stack);
      return false;
    }
  }
}
