import 'package:flutter_test/flutter_test.dart';
import 'package:humhub/util/notifications/channel.dart';

void main() {
  group('NotificationChannel.normalizePushPayload', () {
    test('keeps direct URLs unchanged', () async {
      const payload = 'https://community.humhub.com/mail/mail/index?id=2596&hid=8d1f04';

      final normalized = await NotificationChannel.normalizePushPayload(payload);

      expect(normalized, payload);
    });

    test('extracts HumHub proxy URLs', () async {
      const payload =
          'https://go.humhub.com?url=https%3A%2F%2Fcommunity.humhub.com%2Fmail%2Fmail%2Findex%3Fid%3D2596%26hid%3D8d1f04';

      final normalized = await NotificationChannel.normalizePushPayload(payload);

      expect(normalized, 'https://community.humhub.com/mail/mail/index?id=2596&hid=8d1f04');
    });

    test('keeps malformed HumHub proxy URLs unchanged', () async {
      const payload = 'https://go.humhub.com?hid=8d1f04';

      final normalized = await NotificationChannel.normalizePushPayload(payload);

      expect(normalized, payload);
    });

    test('keeps invalid payloads unchanged', () async {
      const payload = 'not a valid uri';

      final normalized = await NotificationChannel.normalizePushPayload(payload);

      expect(normalized, payload);
    });
  });
}
