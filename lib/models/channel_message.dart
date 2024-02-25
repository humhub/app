import 'dart:convert';

part 'channel_message.g.dart';

enum ChannelAction { showOpener, hideOpener, registerFcmDevice, unregisterFcmDevice, updateNotificationCount}

class ChannelMessage {
  final String type;
  final String? url;
  final int? count;
  ChannelAction? get action {
    if (type == "showOpener") return ChannelAction.showOpener;
    if (type == "hideOpener") return ChannelAction.hideOpener;
    if (type == "registerFcmDevice") return ChannelAction.registerFcmDevice;
    if (type == "unregisterFcmDevice") return ChannelAction.unregisterFcmDevice;
    if (type == "updateNotificationCount") return ChannelAction.updateNotificationCount;

    return null;
  }

  ChannelMessage(this.type, this.url, this.count);

  factory ChannelMessage.fromJson(String json) => _$ChannelMessageFromJson(json);
}
