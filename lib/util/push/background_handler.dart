import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:humhub/util/app_badge.dart';

/// Handles push messages while the app is in the background or terminated.
///
/// The OS shows visible messages itself, so only the app icon badge is updated here. On
/// Android, this is the only way silent messages, which carry nothing but the unread count,
/// reach the badge. On iOS, it is called for silent messages only, whose badge the OS has
/// already set.
///
/// On Android it runs in its own isolate, without the app's state and initialization, so it
/// must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await AppBadge.set(AppBadge.countFromPushData(message.data));
}
