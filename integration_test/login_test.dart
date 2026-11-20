import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_harness.dart';
import 'support/e2e_env.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opener connects to the instance and the user can log in', (tester) async {
    final harness = await AppHarness.boot(tester);

    await harness.connect(tester);
    await harness.waitForUrl(tester, (url) => url.path.contains('/user/auth/login'));

    await harness.login(tester);

    final url = await harness.currentUrl();
    expect(url.toString(), startsWith(E2eEnv.serverUrl));
    expect(url!.path, isNot(contains('/user/auth/login')));
  });
}
