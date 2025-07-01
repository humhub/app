import 'package:firebase_messaging/firebase_messaging.dart';

class PushEvent extends RemoteMessage {
  final PushEventData parsedData;

  PushEvent(RemoteMessage message)
      : parsedData = PushEventData.fromJson(message.data),
        super(
          senderId: message.senderId,
          category: message.category,
          collapseKey: message.collapseKey,
          contentAvailable: message.contentAvailable,
          data: message.data,
          from: message.from,
          messageId: message.messageId,
          messageType: message.messageType,
          mutableContent: message.mutableContent,
          notification: message.notification,
          sentTime: message.sentTime,
          threadId: message.threadId,
          ttl: message.ttl,
        );
}

class PushEventData {
  final String? notificationTitle;
  final String? notificationBody;
  final String? channel;
  final String? channelPayload;
  final String? redirectUrl;
  final String? notificationCount;

  PushEventData({
    this.notificationTitle,
    this.notificationBody,
    this.channel,
    this.channelPayload,
    this.redirectUrl,
    this.notificationCount,
  });

  factory PushEventData.fromJson(Map<String, dynamic> json) {
    return PushEventData(
        notificationTitle: json['notification_title'] as String?,
        notificationBody: json['notification_body'] as String?,
        channel: json['channel'] as String?,
        channelPayload: json['channel_payload'] as String?,
        redirectUrl: json['url'] as String?,
        notificationCount: json['notification_count'] as String?);
  }
}