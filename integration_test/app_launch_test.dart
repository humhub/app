import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots to the opener', (tester) async {
    await AppHarness.boot(tester);

    expect(find.byKey(openerUrlField), findsOneWidget);
    expect(find.byKey(openerConnectButton), findsOneWidget);
  });
}
