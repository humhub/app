import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humhub/models/channel_message.dart';
import 'package:humhub/util/app_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('app_badge_plus');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  group('AppBadge.set', () {
    late List<MethodCall> calls;

    setUp(() {
      calls = [];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
    });

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('shows the count on the app icon', () async {
      await AppBadge.set(3);

      expect(calls, hasLength(1));
      expect(calls.single.method, 'updateBadge');
      expect(calls.single.arguments, {'count': 3});
    });

    test('clear removes the badge', () async {
      await AppBadge.clear();

      expect(calls.single.arguments, {'count': 0});
    });

    test('ignores a missing or negative count', () async {
      await AppBadge.set(null);
      await AppBadge.set(-1);

      expect(calls, isEmpty);
    });

    test('does not throw when the platform fails', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'error');
      });

      await expectLater(AppBadge.set(3), completes);
    });
  });

  group('AppBadge.parseCount', () {
    test('accepts numbers and numeric strings', () {
      expect(AppBadge.parseCount(5), 5);
      expect(AppBadge.parseCount(0), 0);
      expect(AppBadge.parseCount('12'), 12);
      expect(AppBadge.parseCount(' 7 '), 7);
    });

    test('rejects anything else', () {
      expect(AppBadge.parseCount(null), isNull);
      expect(AppBadge.parseCount(''), isNull);
      expect(AppBadge.parseCount('abc'), isNull);
      expect(AppBadge.parseCount(2.5), isNull);
      expect(AppBadge.parseCount(true), isNull);
    });
  });

  group('AppBadge.countFromPushData', () {
    test('reads the count of a push message', () {
      expect(AppBadge.countFromPushData({'url': 'https://example.com', 'notification_count': '4'}), 4);
    });

    test('is null for a message without count', () {
      expect(AppBadge.countFromPushData({'url': 'https://example.com'}), isNull);
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
