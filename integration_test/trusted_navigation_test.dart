import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_harness.dart';
import 'support/e2e_env.dart';
import 'support/e2e_test.dart';

/// humhub/app#368: posts with external (YouTube) links must not pull the
/// main WebView away from the HumHub instance.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  e2eTest('a post with an external link keeps the WebView on the instance', (tester) async {
    final harness = await AppHarness.boot(tester);
    await harness.connectAndLogin(tester);

    await harness.webViewController.loadUrl(urlRequest: URLRequest(url: WebUri(E2eEnv.externalLinkPostUrl)));
    await harness.waitForUrl(tester, (url) => url.toString() == E2eEnv.externalLinkPostUrl);

    // Give embeds/previews time to load and misbehave.
    final deadline = DateTime.now().add(const Duration(seconds: 8));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 250));
      final url = await harness.currentUrl();
      expect(url.toString(), startsWith(E2eEnv.serverUrl), reason: 'WebView navigated away to $url');
    }
  });
}
