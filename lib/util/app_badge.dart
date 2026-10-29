import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:loggy/loggy.dart';

/// The app icon badge, showing the unread count of the HumHub network: unseen notifications
/// plus what other modules add, e.g. unread conversations of the mail module.
///
/// The count is calculated by the `fcm-push` module of the network and reaches the app by
///  - the `notification_count` data field of push messages, visible and silent ones,
///  - the `updateNotificationCount` channel message, sent by the web view on every page load
///    and whenever the count changes on the page.
///
/// While the app is in the background, iOS sets the badge from visible and silent push
/// messages itself (`aps.badge`). On Android, the badge depends on the launcher: those
/// supported by `app_badge_plus` (e.g. Samsung, Huawei, Sony) show the count, most others show
/// a dot while the app has a notification.
///
/// The badge is deliberately not reset when the app starts: iOS also starts the app in the
/// background to deliver a silent push message, which would remove the badge it just set.
class AppBadge {
  AppBadge._();

  /// The data field of push messages carrying the unread count.
  static const String pushDataKey = 'notification_count';

  /// Shows [count] on the app icon, `0` removes the badge.
  ///
  /// A missing or negative count is ignored, so a message without a count never removes a
  /// correct badge.
  static Future<void> set(int? count) async {
    if (count == null || count < 0) return;
    try {
      await AppBadgePlus.updateBadge(count);
      logDebug('AppBadge: Set to $count');
    } catch (e, st) {
      logError('AppBadge: Could not set to $count', e, st);
    }
  }

  static Future<void> clear() => set(0);

  /// The unread count of a push message, `null` if it has none.
  static int? countFromPushData(Map<String, dynamic> data) => parseCount(data[pushDataKey]);

  /// Parses a count given as number or, like all FCM data values, as numeric string.
  static int? parseCount(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
