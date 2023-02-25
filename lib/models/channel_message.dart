part 'channel_message.g.dart';

enum ChannelAction { showOpener, hideOpener, registerFcmDevice, updateNotificationCount, none }

class ChannelMessage {
  final String type;
  final String? url;
  final int? count;
  ChannelAction get action {
    if (type == "showOpener") return ChannelAction.showOpener;
    if (type == "hideOpener") return ChannelAction.hideOpener;
    if (type == "registerFcmDevice") return ChannelAction.registerFcmDevice;
    if (type == "updateNotificationCount") return ChannelAction.updateNotificationCount;

    return ChannelAction.none;
  }

  ChannelMessage(this.type, this.url, this.count);

  factory ChannelMessage.fromJson(Map<String, dynamic> json) => _$ChannelMessageFromJson(json);
}
