import 'package:flutter_test/flutter_test.dart';
import 'package:humhub/models/remote_config.dart';

RemoteConfig _configWith({List<String>? whiteListedUrls, List<String>? authClientUrls}) {
  return RemoteConfig(
    appName: 'Test',
    appVersion: '1.0.0',
    fileUploadSettings: null,
    whiteListedDomains: null,
    whiteListedUrls: whiteListedUrls,
    authClientUrls: authClientUrls,
  );
}

void main() {
  group('RemoteConfig.isTrustedUrl', () {
    test('matches a differently-cased URL against a whitelist entry', () {
      final config = _configWith(whiteListedUrls: ['https://idp.example.com/sso/*']);

      expect(config.isTrustedUrl(Uri.parse('https://IDP.example.com/SSO/callback')), isTrue);
    });

    test('matches wildcard entries case-insensitively', () {
      final config = _configWith(authClientUrls: ['https://login.example.com/*']);

      expect(config.isTrustedUrl(Uri.parse('HTTPS://login.example.com/oauth/callback')), isTrue);
    });

    test('returns false when no whitelist entries are configured', () {
      final config = _configWith();

      expect(config.isTrustedUrl(Uri.parse('https://idp.example.com/sso/callback')), isFalse);
    });

    test('does not match an unrelated domain', () {
      final config = _configWith(whiteListedUrls: ['https://idp.example.com/*']);

      expect(config.isTrustedUrl(Uri.parse('https://evil.example.com/idp.example.com/')), isFalse);
    });
  });
}
