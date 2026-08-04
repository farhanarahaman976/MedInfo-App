import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType { order, orderStatus, reminder, general }

extension AppNotificationTypeX on AppNotificationType {
  String get name {
    switch (this) {
      case AppNotificationType.order:
        return 'order';
      case AppNotificationType.orderStatus:
        return 'order_status';
      case AppNotificationType.reminder:
        return 'reminder';
      case AppNotificationType.general:
        return 'general';
    }
  }

  static AppNotificationType fromString(String? value) {
    switch (value) {
      case 'order':
        return AppNotificationType.order;
      case 'order_status':
        return AppNotificationType.orderStatus;
      case 'reminder':
        return AppNotificationType.reminder;
      default:
        return AppNotificationType.general;
    }
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final AppNotificationType type;
  final String? referenceId; 
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    this.id = '',
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'referenceId': referenceId,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: AppNotificationTypeX.fromString(map['type'] as String?),
      referenceId: map['referenceId'] as String?,
      isRead: (map['isRead'] as bool?) ?? false,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}