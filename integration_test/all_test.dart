import 'app_launch_test.dart' as app_launch;
import 'deep_link_test.dart' as deep_link;
import 'file_upload_test.dart' as file_upload;
import 'login_test.dart' as login;
import 'push_notification_test.dart' as push_notification;
import 'trusted_navigation_test.dart' as trusted_navigation;

/// All tests in one app build and launch, which saves rebuilding the app for
/// every file on iOS (scripts/e2e/run_ios.sh). Each test still starts from a
/// clean app via AppHarness.boot.
void main() {
  app_launch.main();
  deep_link.main();
  file_upload.main();
  login.main();
  push_notification.main();
  trusted_navigation.main();
}
