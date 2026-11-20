/// Configuration for the e2e suite, passed via `--dart-define` by
/// scripts/e2e/run_android.sh (values come from scripts/e2e/up.sh).
class E2eEnv {
  /// HumHub URL as seen from the device, e.g. `http://10.0.2.2:8080`.
  static const String serverUrl = String.fromEnvironment('E2E_SERVER_URL');

  static const String username = String.fromEnvironment('E2E_USERNAME');

  static const String password = String.fromEnvironment('E2E_PASSWORD');

  /// A seeded post containing an external (YouTube) link, see humhub/app#368.
  static const String externalLinkPostUrl = String.fromEnvironment('E2E_EXTERNAL_LINK_POST_URL');

  /// A seeded page used as push notification / deep link target.
  static const String deepLinkTargetUrl = String.fromEnvironment('E2E_DEEP_LINK_TARGET_URL');

  /// Name of the file the upload test shares; run_android.sh checks the
  /// backend for it afterwards.
  static const String uploadFileName = String.fromEnvironment('E2E_UPLOAD_FILE_NAME', defaultValue: 'e2e_upload.txt');

  static void require() {
    final missing = {
      'E2E_SERVER_URL': serverUrl,
      'E2E_USERNAME': username,
      'E2E_PASSWORD': password,
      'E2E_EXTERNAL_LINK_POST_URL': externalLinkPostUrl,
      'E2E_DEEP_LINK_TARGET_URL': deepLinkTargetUrl,
    }.entries.where((e) => e.value.isEmpty).map((e) => e.key);
    if (missing.isNotEmpty) {
      throw StateError('Missing --dart-define values: ${missing.join(', ')}. Run the suite via scripts/e2e/run_android.sh.');
    }
  }
}
