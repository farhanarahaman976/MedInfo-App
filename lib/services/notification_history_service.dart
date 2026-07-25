import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';

class NotificationHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collection = 'notifications';

  /// Notification history-te notun entry add kore
  Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
    required AppNotificationType type,
    String? referenceId,
  }) async {
    final notification = AppNotification(
      userId: userId,
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
      createdAt: DateTime.now(),
    );
    await _firestore.collection(collection).add(notification.toMap());
  }

  /// User-এর সব notification, সর্বশেষ আগে (real-time stream)
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Unread notification count — bell icon badge er jonno
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection(collection)
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Shob notification ek shathe read mark kore (batch write)
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection(collection).doc(notificationId).delete();
  }
}