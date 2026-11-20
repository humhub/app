import 'package:flutter_test/flutter_test.dart';
import 'package:humhub/util/intent/intent_plugin.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_harness.dart';
import 'support/e2e_env.dart';

/// OS-level App Link delivery can't be triggered from a test; app_links'
/// initial and streamed links both end in IntentPluginState.tryNavigateWithOpener.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a deep link opens its URL in the WebView', (tester) async {
    final harness = await AppHarness.boot(tester);

    final intentPlugin = tester.state<IntentPluginState>(find.byType(IntentPlugin));
    await intentPlugin.tryNavigateWithOpener(E2eEnv.deepLinkTargetUrl);
    await AppHarness.waitForWebView(tester);

    await harness.waitForUrl(tester, (url) => url.toString().startsWith(E2eEnv.serverUrl));
  });
}
