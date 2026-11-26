import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humhub/models/channel_message.dart';
import 'package:humhub/util/push/push_unread_count.dart';
import 'package:humhub/util/unread_counts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('app_badge_plus');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  const community = 'https://community.example.com/';
  const sandbox = 'https://sandbox.example.com/';

  late List<int> badges;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UnreadCounts.load();
    badges = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'updateBadge') badges.add((call.arguments as Map)['count'] as int);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('UnreadCounts.set', () {
    test('shows the sum over all instances on the app icon', () async {
      await UnreadCounts.set(community, 3);
      await UnreadCounts.set(sandbox, 2);

      expect(UnreadCounts.counts.value, {community: 3, sandbox: 2});
      expect(badges, [3, 5]);
    });

    test('replaces the count of an instance', () async {
      await UnreadCounts.set(community, 3);
      await UnreadCounts.set(community, 0);

      expect(UnreadCounts.counts.value, {community: 0});
      expect(badges.last, 0);
    });

    test('ignores a missing or negative count', () async {
      await UnreadCounts.set(community, null);
      await UnreadCounts.set(community, -1);

      expect(UnreadCounts.counts.value, isEmpty);
      expect(badges, isEmpty);
    });

    test('persists the counts', () async {
      await UnreadCounts.set(community, 4);
      UnreadCounts.counts.value = const {};

      await UnreadCounts.load();

      expect(UnreadCounts.counts.value, {community: 4});
    });

    test('does not fail when the platform cannot set the badge', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'error');
      });

      await expectLater(UnreadCounts.set(community, 3), completes);
      expect(UnreadCounts.counts.value, {community: 3});
    });
  });

  group('UnreadCounts.setByUrl', () {
    test('applies a count without URL if only one instance is known', () async {
      await UnreadCounts.sync([community]);

      await UnreadCounts.setByUrl(null, 4);

      expect(UnreadCounts.counts.value, {community: 4});
      expect(badges, [4]);
    });

    test('attributes the count to the instance of the URL', () async {
      await UnreadCounts.sync([community, sandbox]);

      await UnreadCounts.setByUrl('https://sandbox.example.com/notification/entry?id=1', 2);

      expect(UnreadCounts.counts.value, {community: 0, sandbox: 2});
      expect(badges, [2]);
    });

    test('ignores a count it cannot attribute with several instances', () async {
      await UnreadCounts.sync([community, sandbox]);

      await UnreadCounts.setByUrl(null, 4);
      await UnreadCounts.setByUrl('https://other.example.com/', 4);

      expect(UnreadCounts.counts.value, {community: 0, sandbox: 0});
      expect(badges, isEmpty);
    });
  });

  group('UnreadCounts.setByBaseUrl', () {
    test('sets the count of the instance with the base URL', () async {
      await UnreadCounts.sync([community, sandbox]);

      await UnreadCounts.setByBaseUrl('https://sandbox.example.com', 2);

      expect(UnreadCounts.counts.value, {community: 0, sandbox: 2});
      expect(badges, [2]);
    });

    test('ignores an unknown base URL even with a single instance', () async {
      await UnreadCounts.sync([community]);

      await UnreadCounts.setByBaseUrl('https://other.example.com', 4);

      expect(UnreadCounts.counts.value, {community: 0});
      expect(badges, isEmpty);
    });

    test('does not attribute an instance in a sub folder to the one at the root', () async {
      const root = 'https://www.cuzy.app';
      await UnreadCounts.sync([root]);

      await UnreadCounts.setByBaseUrl('https://www.cuzy.app/hhtest', 4);

      expect(UnreadCounts.counts.value, {root: 0});
      expect(badges, isEmpty);
    });
  });

  group('UnreadCounts.instanceWithBaseUrl', () {
    const root = 'https://hub.example.com';
    const subFolder = 'https://hub.example.com/humhub/';

    test('matches the same URL, ignoring a trailing slash', () {
      expect(UnreadCounts.instanceWithBaseUrl('https://hub.example.com', [root, subFolder]), root);
      expect(UnreadCounts.instanceWithBaseUrl('https://hub.example.com/', [root, subFolder]), root);
      expect(UnreadCounts.instanceWithBaseUrl('https://hub.example.com/humhub', [root, subFolder]), subFolder);
    });

    test('ignores the case of scheme and host and a default port', () {
      expect(UnreadCounts.instanceWithBaseUrl('HTTPS://Hub.Example.com', [root]), root);
      expect(UnreadCounts.instanceWithBaseUrl('https://hub.example.com:443', [root]), root);
    });

    test('does not match other paths, schemes, hosts or ports', () {
      expect(UnreadCounts.instanceWithBaseUrl('https://hub.example.com/humhub/s/space', [root, subFolder]), isNull);
      expect(UnreadCounts.instanceWithBaseUrl('https://hub.example.com/other', [root]), isNull);
      expect(UnreadCounts.instanceWithBaseUrl('http://hub.example.com', [root]), isNull);
      expect(UnreadCounts.instanceWithBaseUrl('https://www.hub.example.com', [root]), isNull);
      expect(UnreadCounts.instanceWithBaseUrl('https://hub.example.com:8443', [root]), isNull);
    });

    test('is null for invalid URLs', () {
      expect(UnreadCounts.instanceWithBaseUrl('not a url', [root]), isNull);
      expect(UnreadCounts.instanceWithBaseUrl('', [root]), isNull);
    });
  });

  group('UnreadCounts.sync', () {
    test('adds new instances without touching the app icon', () async {
      await UnreadCounts.sync([community, sandbox]);

      expect(UnreadCounts.counts.value, {community: 0, sandbox: 0});
      expect(badges, isEmpty);
    });

    test('keeps the counts of known instances', () async {
      await UnreadCounts.set(community, 3);
      badges.clear();

      await UnreadCounts.sync([community, sandbox]);

      expect(UnreadCounts.counts.value, {community: 3, sandbox: 0});
      expect(badges, isEmpty);
    });

    test('drops removed instances and shows the new sum if they had unread items', () async {
      await UnreadCounts.set(community, 3);
      await UnreadCounts.set(sandbox, 2);
      badges.clear();

      await UnreadCounts.sync([community]);

      expect(UnreadCounts.counts.value, {community: 3});
      expect(badges, [3]);
    });

    test('does not touch the app icon when dropping instances without unread items', () async {
      await UnreadCounts.sync([community, sandbox]);

      await UnreadCounts.sync([community]);

      expect(UnreadCounts.counts.value, {community: 0});
      expect(badges, isEmpty);
    });
  });

  group('UnreadCounts.instanceOf', () {
    const root = 'https://hub.example.com/';
    const subFolder = 'https://hub.example.com/humhub/';

    test('matches the origin', () {
      expect(UnreadCounts.instanceOf('https://hub.example.com/s/space', [root]), root);
      expect(UnreadCounts.instanceOf('https://hub.example.com', [root]), root);
    });

    test('prefers the instance in the longest matching sub folder', () {
      expect(UnreadCounts.instanceOf('https://hub.example.com/humhub/s/space', [root, subFolder]), subFolder);
      expect(UnreadCounts.instanceOf('https://hub.example.com/humhub', [root, subFolder]), subFolder);
      expect(UnreadCounts.instanceOf('https://hub.example.com/humhubx/s', [root, subFolder]), root);
      expect(UnreadCounts.instanceOf('https://hub.example.com/other', [subFolder]), isNull);
    });

    test('does not match other hosts, schemes or ports', () {
      expect(UnreadCounts.instanceOf('https://evil.example.com/', [root]), isNull);
      expect(UnreadCounts.instanceOf('http://hub.example.com/', [root]), isNull);
      expect(UnreadCounts.instanceOf('https://hub.example.com:8443/', [root]), isNull);
    });

    test('is null for missing or invalid URLs', () {
      expect(UnreadCounts.instanceOf(null, [root]), isNull);
      expect(UnreadCounts.instanceOf('not a url', [root]), isNull);
    });
  });

  group('UnreadCounts.parseCount', () {
    test('accepts numbers and numeric strings', () {
      expect(UnreadCounts.parseCount(5), 5);
      expect(UnreadCounts.parseCount(0), 0);
      expect(UnreadCounts.parseCount('12'), 12);
      expect(UnreadCounts.parseCount(' 7 '), 7);
    });

    test('rejects anything else', () {
      expect(UnreadCounts.parseCount(null), isNull);
      expect(UnreadCounts.parseCount(''), isNull);
      expect(UnreadCounts.parseCount('abc'), isNull);
      expect(UnreadCounts.parseCount(2.5), isNull);
      expect(UnreadCounts.parseCount(true), isNull);
    });
  });

  group('applyUnreadCountOfPush', () {
    test('attributes the count via the URL of the message', () async {
      await UnreadCounts.sync([community, sandbox]);

      await applyUnreadCountOfPush(const RemoteMessage(
        data: {'url': 'https://sandbox.example.com/notification/entry?id=1', 'notification_count': '3'},
      ));

      expect(UnreadCounts.counts.value, {community: 0, sandbox: 3});
    });

    test('unwraps go.humhub.com URLs', () async {
      await UnreadCounts.sync([community, sandbox]);

      await applyUnreadCountOfPush(const RemoteMessage(
        data: {
          'url': 'https://go.humhub.com?url=https%3A%2F%2Fcommunity.example.com%2Fnotification%2Fentry%3Fid%3D1',
          'notification_count': '6',
        },
      ));

      expect(UnreadCounts.counts.value, {community: 6, sandbox: 0});
    });

    test('attributes the count via the base URL of the message', () async {
      await UnreadCounts.sync([community, sandbox]);

      await applyUnreadCountOfPush(const RemoteMessage(
        data: {'base_url': 'https://sandbox.example.com', 'notification_count': '4'},
      ));

      expect(UnreadCounts.counts.value, {community: 0, sandbox: 4});
    });

    test('prefers the base URL over the URL', () async {
      await UnreadCounts.sync([community, sandbox]);

      await applyUnreadCountOfPush(const RemoteMessage(
        data: {
          'base_url': 'https://sandbox.example.com',
          'url': 'https://community.example.com/notification/entry?id=1',
          'notification_count': '4',
        },
      ));

      expect(UnreadCounts.counts.value, {community: 0, sandbox: 4});
    });

    test('ignores the count of an unknown base URL instead of using the URL', () async {
      await UnreadCounts.sync([community, sandbox]);

      await applyUnreadCountOfPush(const RemoteMessage(
        data: {
          'base_url': 'http://community.example.com',
          'url': 'https://community.example.com/notification/entry?id=1',
          'notification_count': '4',
        },
      ));

      expect(UnreadCounts.counts.value, {community: 0, sandbox: 0});
      expect(badges, isEmpty);
    });

    test('ignores a sub folder instance that is not known, also with a single instance', () async {
      const root = 'https://www.cuzy.app';
      await UnreadCounts.sync([root]);

      await applyUnreadCountOfPush(const RemoteMessage(
        data: {
          'base_url': 'https://www.cuzy.app/hhtest',
          'url': 'https://www.cuzy.app/hhtest/notification/entry?id=1',
          'notification_count': '4',
        },
      ));
      await applyUnreadCountOfPush(const RemoteMessage(
        data: {'base_url': 'https://www.cuzy.app/hhtest', 'notification_count': '4'},
      ));

      expect(UnreadCounts.counts.value, {root: 0});
      expect(badges, isEmpty);
    });

    test('applies a silent message without base URL with a single instance', () async {
      await UnreadCounts.sync([community]);

      await applyUnreadCountOfPush(const RemoteMessage(data: {'notification_count': '3'}));

      expect(UnreadCounts.counts.value, {community: 3});
    });

    test('ignores a message without count', () async {
      await UnreadCounts.sync([community]);

      await applyUnreadCountOfPush(const RemoteMessage(data: {'url': 'https://community.example.com/'}));

      expect(UnreadCounts.counts.value, {community: 0});
      expect(badges, isEmpty);
    });
  });

  group('updateNotificationCount channel message', () {
    UpdateNotificationCountChannelData parse(String json) =>
        ChannelMessage.fromJson(json).data as UpdateNotificationCountChannelData;

    test('maps to the updateNotificationCount action', () {
      final message = ChannelMessage.fromJson('{"type":"updateNotificationCount","count":3}');

      expect(message.action, ChannelAction.updateNotificationCount);
    });

    test('carries the count', () {
      expect(parse('{"type":"updateNotificationCount","count":3}').count, 3);
      expect(parse('{"type":"updateNotificationCount","count":0}').count, 0);
      expect(parse('{"type":"updateNotificationCount","count":"8"}').count, 8);
    });

    test('has no count instead of failing for an invalid one', () {
      expect(parse('{"type":"updateNotificationCount"}').count, isNull);
      expect(parse('{"type":"updateNotificationCount","count":null}').count, isNull);
      expect(parse('{"type":"updateNotificationCount","count":"x"}').count, isNull);
    });
  });
}
