// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChannelMessage _$ChannelMessageFromJson(String json) {
  if (json == "humhub.mobile.hideOpener") {
    return ChannelMessage(
      "hideOpener",
      null,
      null,
    );
  } else if (json == "humhub.mobile.showOpener") {
    return ChannelMessage(
      "showOpener",
      null,
      null,
    );
  } else {
    var jsonMap = jsonDecode(json) as Map<String, dynamic>;
    return ChannelMessage(
      jsonMap['type'] as String,
      jsonMap['url'] as String?,
      jsonMap['count'] as int?,
    );
  }
}
