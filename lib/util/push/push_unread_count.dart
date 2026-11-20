import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:humhub/models/event.dart';
import 'package:humhub/util/notifications/channel.dart';
import 'package:humhub/util/unread_counts.dart';

/// Applies the unread count of a push message, visible or silent, to the instance that
/// sent it.
///
/// The instance is the one the `url` of the message belongs to. Silent messages have no
/// `url`, so their count only counts if the app is connected to a single instance.
Future<void> applyUnreadCountOfPush(RemoteMessage message) async {
  final data = PushEvent(message).parsedData;
  final count = UnreadCounts.parseCount(data.notificationCount);
  if (count == null) return;
  final url = data.redirectUrl;
  await UnreadCounts.setByUrl(url == null ? null : await NotificationChannel.normalizePushPayload(url), count);
}
