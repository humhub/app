import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppLinkSettingsState {
  final bool supported;
  final bool enabled;
  final bool hostDeclared;

  const AppLinkSettingsState({
    required this.supported,
    required this.enabled,
    required this.hostDeclared,
  });

  bool get shouldShowDisabledDialog => supported && hostDeclared && !enabled;
}

class AppLinkSettings {
  static const MethodChannel _channel = MethodChannel('humhub/app_links');
  static AppLinkSettingsState _state = const AppLinkSettingsState(
    supported: false,
    enabled: true,
    hostDeclared: false,
  );

  static const AppLinkSettingsState _defaultState = AppLinkSettingsState(
    supported: false,
    enabled: true,
    hostDeclared: false,
  );

  static AppLinkSettingsState get state => _state;

  static String get headerValue => _state.enabled ? 'true' : 'false';

  static Future<AppLinkSettingsState> refresh() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return _state;
    }

    try {
      final response =
          await _channel.invokeMapMethod<String, dynamic>('getGoHumhubState');
      if (response == null) return _state;

      _state = AppLinkSettingsState(
        supported: response['supported'] == true,
        enabled: response['enabled'] != false,
        hostDeclared: response['hostDeclared'] == true,
      );
    } on MissingPluginException {
      _state = _defaultState;
    } on PlatformException {
      _state = _defaultState;
    }

    return _state;
  }

  static Future<bool> openOpenByDefaultSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openOpenByDefaultSettings') ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
