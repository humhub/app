import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:humhub/models/event.dart';
import 'package:humhub/util/notifications/channel.dart';
import 'package:humhub/util/unread_counts.dart';

/// The data field of push messages with the base URL of the instance that sent them. It
/// equals the `start_url` of the instance's manifest (fcm-push 2.3.4+).
const String pushBaseUrlKey = 'base_url';

/// Applies the unread count of a push message, visible or silent, to the instance that
/// sent it.
///
/// If the message carries a `base_url`, it decides: the count is applied to the instance with
/// exactly that base URL or ignored. Messages of older servers without it are attributed via
/// their `url`. Their silent messages have no `url`, so their count only counts if the app is
/// connected to a single instance.
Future<void> applyUnreadCountOfPush(RemoteMessage message) async {
  final data = PushEvent(message).parsedData;
  final count = UnreadCounts.parseCount(data.notificationCount);
  if (count == null) return;
  final baseUrl = message.data[pushBaseUrlKey];
  if (baseUrl is String && baseUrl.trim().isNotEmpty) {
    await UnreadCounts.setByBaseUrl(baseUrl, count);
    return;
  }
  final url = data.redirectUrl;
  await UnreadCounts.setByUrl(url == null ? null : await NotificationChannel.normalizePushPayload(url), count);
}
