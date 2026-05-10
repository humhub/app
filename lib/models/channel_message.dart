import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'file_upload_settings.dart';

/// Enum representing different channel actions
enum ChannelAction {
  showOpener,
  hideOpener,
  registerFcmDevice,
  unregisterFcmDevice,
  updateNotificationCount,
  nativeConsole,
  fileUploadSettings,
  openExternal,
  authClientRedirect,
  none
}

/// Abstract class to encapsulate the logic for channel data
abstract class ChannelData {
  final String type;

  const ChannelData(this.type);

  /// Factory method to create specific [ChannelData] instances based on [type]
  factory ChannelData.fromType(String type, Map<String, dynamic> json) {
    switch (type) {
      case "registerFcmDevice":
        return RegisterFcmPushChannelData.fromJson(type, json);
      case "updateNotificationCount":
        return UpdateNotificationCountChannelData.fromJson(type, json);
      case "fileUploadSettings":
        return FileUploadSettingsChannelData.fromJson(type, json);
      case "authClientRedirect":
        return AuthClientRedirectChannelData.fromJson(type, json);
      default:
        return DefaultChannelData(type);
    }
  }
}

/// Default implementation of [ChannelData] for unsupported types
class DefaultChannelData extends ChannelData {
  const DefaultChannelData(super.type);
}

/// Main ChannelMessage class
class ChannelMessage {
  final String type;
  final String? url;
  final ChannelData? data;

  /// Getter to derive the action based on the type
  ChannelAction get action {
    switch (type) {
      case "showOpener":
        return ChannelAction.showOpener;
      case "hideOpener":
        return ChannelAction.hideOpener;
      case "registerFcmDevice":
        return ChannelAction.registerFcmDevice;
      case "unregisterFcmDevice":
        return ChannelAction.unregisterFcmDevice;
      case "updateNotificationCount":
        return ChannelAction.updateNotificationCount;
      case "openNativeConsole":
        return ChannelAction.nativeConsole;
      case "fileUploadSettings":
        return ChannelAction.fileUploadSettings;
      case "openExternal":
        return ChannelAction.openExternal;
      case "authClientRedirect":
        return ChannelAction.authClientRedirect;
      default:
        return ChannelAction.none;
    }
  }

  /// Constructor for [ChannelMessage]
  const ChannelMessage(this.type, this.url, this.data);

  /// Factory method to parse JSON and create a [ChannelMessage]
  factory ChannelMessage.fromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);

    final String type = json['type'] as String;
    final String? url = json['url'] as String?;

    final ChannelData data = ChannelData.fromType(type, json);

    return ChannelMessage(type, url, data);
  }
}

/// Data class for registering FCM push notifications
class RegisterFcmPushChannelData extends ChannelData {
  final String? url;

  RegisterFcmPushChannelData(super.type, this.url);

  factory RegisterFcmPushChannelData.fromJson(
      String type, Map<String, dynamic> json) {
    return RegisterFcmPushChannelData(type, json['url'] as String?);
  }
}

/// Data class for updating notification count
class UpdateNotificationCountChannelData extends ChannelData {
  final int count;

  UpdateNotificationCountChannelData(super.type, this.count);

  factory UpdateNotificationCountChannelData.fromJson(
      String type, Map<String, dynamic> json) {
    return UpdateNotificationCountChannelData(type, json['count'] as int);
  }
}

/// Data class for file upload settings
class FileUploadSettingsChannelData extends ChannelData {
  final FileUploadSettings settings;

  FileUploadSettingsChannelData(super.type, this.settings);

  factory FileUploadSettingsChannelData.fromJson(
      String type, Map<String, dynamic> json) {
    return FileUploadSettingsChannelData(
      type,
      FileUploadSettings.fromJson(json),
    );
  }
}

class AuthClientRedirectChannelData extends ChannelData {
  final String? url;

  const AuthClientRedirectChannelData(super.type, this.url);

  factory AuthClientRedirectChannelData.fromJson(
      String type, Map<String, dynamic> json) {
    return AuthClientRedirectChannelData(type, json['url'] as String?);
  }

  void handle({
    required bool isSupported,
    required void Function(URLRequest request, String url) onLaunchable,
    void Function(String message)? onIgnored,
  }) {
    if (!isSupported) {
      onIgnored?.call(
          'Ignoring authClientRedirect message because app feature flags do not support it');
      return;
    }

    if (url == null || url!.isEmpty) {
      onIgnored
          ?.call('Ignoring authClientRedirect message because url is empty');
      return;
    }

    final uri = Uri.tryParse(url!);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      onIgnored
          ?.call('Ignoring authClientRedirect message because url is invalid');
      return;
    }

    onLaunchable(URLRequest(url: WebUri(url!)), url!);
  }
}
