import 'dart:convert';

class FeatureFlag {
  static const String authClientRedirectKey = 'auth_client_redirect';
  static const String enabledValue = 'true';

  static const FeatureFlag authClientRedirect = FeatureFlag(
    key: authClientRedirectKey,
    value: enabledValue,
  );

  final String key;
  final String value;

  const FeatureFlag({
    required this.key,
    required this.value,
  });

  Map<String, String> toJson() => {
        'key': key,
        'value': value,
      };

  static List<FeatureFlag> get featureFlags => const [
        FeatureFlag.authClientRedirect,
      ];

  static String get featureFlagsHeaderValue => jsonEncode(
        featureFlags.map((featureFlag) => featureFlag.toJson()).toList(),
      );

  static bool get supportsAuthClientRedirect => featureFlags.any(
        (featureFlag) =>
            featureFlag.key == authClientRedirectKey &&
            featureFlag.value == enabledValue,
      );
}
