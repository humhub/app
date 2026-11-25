import 'package:humhub/util/notifications/channel.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_harness.dart';
import 'support/e2e_env.dart';
import 'support/e2e_test.dart';

/// Real FCM delivery can't be triggered from a test; onMessageOpenedApp and
/// local notification taps both end in NotificationChannel.onTap.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  e2eTest('tapping a notification opens its URL in the WebView', (tester) async {
    final harness = await AppHarness.boot(tester);

    await const NotificationChannel().onTap(E2eEnv.deepLinkTargetUrl);
    await AppHarness.waitForWebView(tester);

    // Logged out, HumHub redirects to the login page and keeps the target.
    await harness.waitForUrl(tester, (url) => url.toString().startsWith(E2eEnv.serverUrl));
  });
}
