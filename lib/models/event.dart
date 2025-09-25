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

  PushEventData(
    this.notificationTitle,
    this.notificationBody,
    this.channel,
    this.channelPayload,
    this.redirectUrl,
    this.notificationCount,
  );

  factory PushEventData.fromJson(Map<String, dynamic> json) {
    return PushEventData(json['notification_title'] as String?, json['notification_body'] as String?, json['channel'] as String?,
        json['channel_payload'] as String?, json['url'] as String?, json['notification_count'] as String?);
  }
}

class SimpleNotification {
  final String title;
  final String body;

  SimpleNotification(this.title, this.body);

  factory SimpleNotification.fromJson(Map<String, dynamic> json) {
    return SimpleNotification(
      json['title'] as String,
      json['body'] as String,
    );
  }
}

class PushEventRefreshStore {
  final String? storeId;

  /// This can be null if Store isn't using family. Should otherwise be same
  /// type as family's id
  final dynamic familyId;

  PushEventRefreshStore(this.storeId, this.familyId);

  factory PushEventRefreshStore.fromJson(Map<String, dynamic> json) {
    return PushEventRefreshStore(
      json['store_id'] as String?,
      json['family_id'],
    );
  }
}
