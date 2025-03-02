import 'dart:convert';

/// Enum representing different channel actions
enum ChannelAction {
  showOpener,
  hideOpener,
  registerFcmDevice,
  unregisterFcmDevice,
  updateNotificationCount,
  nativeConsole,
  fileUploadSettings,
  none
}

/// Abstract class to encapsulate the logic for channel data
class ChannelData {
  final String type;
  const ChannelData(this.type);

  /// Factory method to create specific [ChannelData] instances based on [type]
  factory ChannelData.fromType(String type, Map<String, dynamic> json) {
    switch (type) {
      case "registerFcmDevice":
        return RegisterFcmPushChannelData.fromJson(type, json);
      case "updateNotificationCount":
        return UpdateNotificationCountChannelData.fromJson(type, json);
      default:
        return ChannelData(type);
    }
  }
}

class RegisterFcmPushChannelData extends ChannelData {
  final String? url;

  RegisterFcmPushChannelData(super.type, this.url);

  factory RegisterFcmPushChannelData.fromJson(String type, Map<String, dynamic> json) {
    return RegisterFcmPushChannelData(type, json['url'] as String);
  }
}

class UpdateNotificationCountChannelData extends ChannelData {
  final int count;

  UpdateNotificationCountChannelData(super.type, this.count);

  factory UpdateNotificationCountChannelData.fromJson(String type, Map<String, dynamic> json) {
    return UpdateNotificationCountChannelData(type, json['count'] as int);
  }
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
      default:
        return ChannelAction.none;
    }
  }

  /// Constructor for [ChannelMessage]
  ChannelMessage(this.type, this.url, this.data);

  /// Factory method to parse JSON and create a [ChannelMessage]
  factory ChannelMessage.fromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);

    final String type = json['type'] as String;
    final String? url = json['url'] as String?;
    final Map<String, dynamic>? dataJson = json['data'] as Map<String, dynamic>?;

    final ChannelData? data = dataJson != null ? ChannelData.fromType(type, dataJson) : null;

    return ChannelMessage(type, url, data);
  }
}
