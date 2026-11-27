import 'package:flutter_test/flutter_test.dart';

/// Markers scripts/e2e/run_android.sh and run_ios.sh watch for in the device log
/// to take a screenshot, and run_ios.sh to record each test separately when
/// they all run in one app (integration_test/all_test.dart).
const _screenshotMarker = 'E2E_SCREENSHOT:';
const _testStartMarker = 'E2E_TEST_START:';
const _testEndMarker = 'E2E_TEST_END:';

/// Integration tests on a device have no timeout by default, so a hanging test
/// (e.g. on a system alert) would block the whole CI job. Applied to [body], so
/// a timeout also gets a screenshot; the test's own timeout is the fallback.
const _bodyTimeout = Duration(minutes: 5);
const _testTimeout = Timeout(Duration(minutes: 6));

/// [testWidgets] that requests a screenshot of the device when [body] fails.
///
/// The screenshot is taken on the host (`adb screencap`, `simctl io screenshot`),
/// so it includes the WebView. The failing state is kept on screen for a moment
/// before rethrowing.
void e2eTest(String description, WidgetTesterCallback body) {
  testWidgets(description, (tester) async {
    // ignore: avoid_print
    print('$_testStartMarker${_slug(description)}');
    try {
      await body(tester).timeout(_bodyTimeout);
    } catch (_) {
      // ignore: avoid_print
      print('$_screenshotMarker${_slug(description)}');
      final until = DateTime.now().add(const Duration(seconds: 3));
      while (DateTime.now().isBefore(until)) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      rethrow;
    } finally {
      // ignore: avoid_print
      print('$_testEndMarker${_slug(description)}');
    }
  }, timeout: _testTimeout);
}

String _slug(String description) =>
    description.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
