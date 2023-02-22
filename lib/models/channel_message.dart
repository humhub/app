part 'channel_message.g.dart';

enum ChannelAction { showOpener, hideOpener, registerFcmDevice, none }

class ChannelMessage {
  final String type;
  final String? url;
  ChannelAction get action {
    if (type == "showOpener") return ChannelAction.showOpener;
    if (type == "hideOpener") return ChannelAction.hideOpener;
    if (type == "registerFcmDevice") return ChannelAction.registerFcmDevice;
    return ChannelAction.none;
  }

  ChannelMessage(
    this.type,
    this.url,
  );

  factory ChannelMessage.fromJson(Map<String, dynamic> json) => _$ChannelMessageFromJson(json);
}
