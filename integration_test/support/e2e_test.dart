import 'package:flutter_test/flutter_test.dart';

/// Marker scripts/e2e/run_android.sh and run_ios.sh watch for in the device log
/// to take a screenshot.
const _screenshotMarker = 'E2E_SCREENSHOT:';

/// [testWidgets] that requests a screenshot of the device when [body] fails.
///
/// The screenshot is taken on the host (`adb screencap`, `simctl io screenshot`),
/// so it includes the WebView. The failing state is kept on screen for a moment
/// before rethrowing.
void e2eTest(String description, WidgetTesterCallback body) {
  testWidgets(description, (tester) async {
    try {
      await body(tester);
    } catch (_) {
      // ignore: avoid_print
      print('$_screenshotMarker${_slug(description)}');
      final until = DateTime.now().add(const Duration(seconds: 3));
      while (DateTime.now().isBefore(until)) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      rethrow;
    }
  });
}

String _slug(String description) =>
    description.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
