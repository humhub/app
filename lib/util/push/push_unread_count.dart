import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:humhub/models/event.dart';
import 'package:humhub/util/notifications/channel.dart';
import 'package:humhub/util/unread_counts.dart';

/// The data field of push messages with the base URL of the instance that sent them. It
/// equals the `start_url` of the instance's manifest (fcm-push 2.3.3+).
const String pushBaseUrlKey = 'base_url';

/// Applies the unread count of a push message, visible or silent, to the instance that
/// sent it.
///
/// The instance is the one of the `base_url` of the message or, for servers that do not send
/// it, of its `url`. Silent messages of such servers have no `url`, so their count only counts
/// if the app is connected to a single instance.
Future<void> applyUnreadCountOfPush(RemoteMessage message) async {
  final data = PushEvent(message).parsedData;
  final count = UnreadCounts.parseCount(data.notificationCount);
  if (count == null) return;
  final baseUrl = message.data[pushBaseUrlKey];
  final url = data.redirectUrl;
  await UnreadCounts.setByUrls([
    if (baseUrl is String) baseUrl,
    if (url != null) await NotificationChannel.normalizePushPayload(url),
  ], count);
}
