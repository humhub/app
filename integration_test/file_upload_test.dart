import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:humhub/util/intent/intent_state.dart';
import 'package:integration_test/integration_test.dart';
import 'package:listen_sharing_intent/listen_sharing_intent.dart';
import 'package:path_provider/path_provider.dart';

import 'support/app_harness.dart';
import 'support/e2e_env.dart';

/// Sharing a file into the app uploads it through the logged-in WebView.
/// scripts/e2e/run_android.sh checks afterwards that it reached the backend.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a shared file is uploaded to the instance', (tester) async {
    final harness = await AppHarness.boot(tester);
    await harness.connectAndLogin(tester);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${E2eEnv.uploadFileName}');
    await file.writeAsString('HumHub e2e upload');

    // Same entry point as the OS share sheet (IntentPlugin).
    final intent = harness.container.read(intentProvider.notifier);
    intent.setSharedFiles([SharedMediaFile(path: file.path, type: SharedMediaType.file, mimeType: 'text/plain')]);

    // Pending files are cleared once the upload request completes.
    await AppHarness.waitUntil(
      tester,
      () => intent.currentState.isSharedFilesNullOrEmpty,
      timeout: const Duration(seconds: 60),
    );
  });
}
