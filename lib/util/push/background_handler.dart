import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:humhub/util/push/push_unread_count.dart';

/// Handles push messages while the app is in the background or terminated.
///
/// The OS shows visible messages itself, so only the unread count is applied here. On
/// Android, this is the only way the count of a message reaches the app icon badge. On iOS,
/// it is called for silent messages only, whose badge the OS has already set, and not at all
/// once the user has closed the app.
///
/// On Android it runs in its own isolate, without the app's state and initialization, so it
/// must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await applyUnreadCountOfPush(message);
}
