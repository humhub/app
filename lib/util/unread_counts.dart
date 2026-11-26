import 'dart:convert';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:loggy/loggy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The unread count of every HumHub instance the app is connected to: unseen notifications
/// plus what other modules add, e.g. unread conversations of the mail module. The app icon
/// badge shows their sum.
///
/// An instance is identified by the `startUrl` of its manifest, like in the history. The
/// store does not care where a count comes from. Today these are the `notification_count`
/// of push messages and the `updateNotificationCount` channel message of the web view.
///
/// The counts are persisted, as the background isolate handling push messages on Android has
/// to know them and the instances too.
class UnreadCounts {
  UnreadCounts._();

  static const String _storageKey = 'unread_counts';

  /// The counts by instance, as of the last read or change in this isolate. Changes made by
  /// the background isolate show up after [load].
  static final ValueNotifier<Map<String, int>> counts = ValueNotifier(const {});

  // Changes read, modify and write all counts, so they must not overlap.
  static Future<void> _pending = Future.value();

  /// Sets the count of [instance] and shows the new sum on the app icon.
  ///
  /// A missing or negative count is ignored, so a message without a count never removes a
  /// correct one.
  static Future<void> set(String instance, int? count) async {
    if (count == null || count < 0) return;
    await _change((counts) {
      counts[instance] = count;
      return true;
    });
  }

  /// Sets the count of the instance whose base URL is [baseUrl], see [instanceWithBaseUrl].
  ///
  /// The base URL identifies the instance, so a count is ignored if no known instance has it,
  /// even if the app knows a single instance only: it may come from an instance that was removed
  /// from the app or that lives in a sub folder of a known one.
  static Future<void> setByBaseUrl(String baseUrl, int? count) async {
    if (count == null || count < 0) return;
    await _change((counts) {
      final instance = instanceWithBaseUrl(baseUrl, counts.keys);
      if (instance == null) {
        logDebug('UnreadCounts: No instance with the base URL $baseUrl for a count of $count');
        return null;
      }
      counts[instance] = count;
      return true;
    });
  }

  /// Sets the count of the instance [url] belongs to, see [instanceOf]. For counts without a
  /// base URL, e.g. of push messages from servers that do not send it yet.
  ///
  /// A count that cannot be attributed this way, e.g. the one of a silent push message, is
  /// only applied if exactly one instance is known. Otherwise it is ignored.
  static Future<void> setByUrl(String? url, int? count) async {
    if (count == null || count < 0) return;
    await _change((counts) {
      final instance = instanceOf(url, counts.keys) ?? (counts.length == 1 ? counts.keys.single : null);
      if (instance == null) {
        logDebug('UnreadCounts: No instance for a count of $count');
        return null;
      }
      counts[instance] = count;
      return true;
    });
  }

  /// Makes [instances] the known ones: new ones start without unread items, the counts of
  /// all others are dropped.
  ///
  /// The app icon is only touched if a dropped count changes the sum: the OS may have set
  /// a newer badge from a push message than the counts stored here add up to.
  static Future<void> sync(Iterable<String> instances) async {
    final known = instances.toSet();
    await _change((counts) {
      final dropped = counts.keys.where((instance) => !known.contains(instance)).toList();
      final droppedUnread = dropped.any((instance) => counts[instance]! > 0);
      final added = known.where((instance) => !counts.containsKey(instance)).toList();
      if (dropped.isEmpty && added.isEmpty) return null;
      dropped.forEach(counts.remove);
      for (final instance in added) {
        counts[instance] = 0;
      }
      return droppedUnread;
    });
  }

  /// Reads the stored counts again, see [counts].
  static Future<void> load() => _change((counts) => null);

  /// The instance of [instances] whose base URL is [baseUrl], `null` if there is none.
  ///
  /// The base URL equals the `start_url` of the instance's manifest, so they must be the
  /// same URL: scheme, host, port and path, ignoring a trailing slash.
  static String? instanceWithBaseUrl(String baseUrl, Iterable<String> instances) {
    final target = _normalizedBaseUrl(baseUrl);
    if (target == null) return null;
    for (final instance in instances) {
      if (_normalizedBaseUrl(instance) == target) return instance;
    }
    return null;
  }

  static String? _normalizedBaseUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasAuthority) return null;
    // Uri already lower-cases scheme and host and knows the default port of http and https
    final path = uri.path.endsWith('/') ? uri.path.substring(0, uri.path.length - 1) : uri.path;
    return '${uri.scheme}://${uri.host}:${uri.port}$path';
  }

  /// The instance of [instances] that [url] belongs to, `null` if there is none.
  ///
  /// [url] may point anywhere into the instance, so the instance whose base URL is the
  /// longest prefix of it wins.
  static String? instanceOf(String? url, Iterable<String> instances) {
    final target = url == null ? null : Uri.tryParse(url);
    if (target == null || !target.hasAuthority) return null;
    String? match;
    int matchLength = -1;
    for (final instance in instances) {
      final base = Uri.tryParse(instance);
      if (base == null || base.scheme != target.scheme || base.host != target.host || base.port != target.port) continue;
      // An instance may be installed in a sub folder
      final path = base.path.endsWith('/') ? base.path.substring(0, base.path.length - 1) : base.path;
      if (target.path != path && !target.path.startsWith('$path/')) continue;
      if (path.length > matchLength) {
        match = instance;
        matchLength = path.length;
      }
    }
    return match;
  }

  /// Parses a count given as number or, like all data values of push messages, as numeric
  /// string.
  static int? parseCount(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  /// Applies [change] to the stored counts. It returns `null` if it changed nothing, and
  /// otherwise whether the app icon has to show the new sum.
  static Future<void> _change(bool? Function(Map<String, int> counts) change) {
    return _pending = _pending.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        // The other isolate may have changed them
        await prefs.reload();
        final counts = _decode(prefs.getString(_storageKey));
        final showBadge = change(counts);
        if (showBadge != null) {
          await prefs.setString(_storageKey, json.encode(counts));
        }
        UnreadCounts.counts.value = Map.unmodifiable(counts);
        if (showBadge == true) {
          await _showBadge(counts.values.fold(0, (sum, count) => sum + count));
        }
      } catch (e, st) {
        logError('UnreadCounts: Could not update the counts', e, st);
      }
    });
  }

  static Map<String, int> _decode(String? stored) {
    if (stored == null) return {};
    try {
      return {
        for (final entry in (json.decode(stored) as Map<String, dynamic>).entries)
          if (entry.value is int) entry.key: entry.value as int,
      };
    } catch (e) {
      logWarning('UnreadCounts: Dropping unreadable counts');
      return {};
    }
  }

  /// Shows [count] on the app icon, `0` removes the badge. On Android, this depends on the
  /// launcher: those supported by `app_badge_plus` (e.g. Samsung, Huawei, Sony) show it.
  static Future<void> _showBadge(int count) async {
    try {
      await AppBadgePlus.updateBadge(count);
      logDebug('UnreadCounts: App icon badge set to $count');
    } catch (e, st) {
      logError('UnreadCounts: Could not set the app icon badge to $count', e, st);
    }
  }
}
