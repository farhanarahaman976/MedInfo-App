import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import '../models/app_notification.dart';
import 'notification_history_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String ordersCollection = 'orders';
  // FIX: stock decrement korte medicine collection reference lagbe.
  // Admin dashboard e medicine add/edit/delete jei collection e hocche,
  // seta ei naam er shathe match kora dorkar — na hole eta bhul document
  // update korbe.
  static const String medicinesCollection = 'medicines';

  /// নতুন order Firestore-এ save করে, generated order ID return করে।
  /// FIX: age eta shudhu order document create korto, medicine stock
  /// kokhono kome na. Ekhon eta ekta transaction-e (1) order write kore
  /// ar (2) prottek item-er medicine stockQuantity theke ordered quantity
  /// minus kore — ek shathe. Transaction bebohar korar karon: duijon user
  /// ek shathe last stock er medicine order dile o stock double-minus
  /// or negative hobe na.
  Future<String> placeOrder(MedicineOrder order) async {
    final orderDocRef = _firestore.collection(ordersCollection).doc();

    await _firestore.runTransaction((transaction) async {
      // Firestore transaction rule: shob read age korte hoy, tarpor write.
      final uniqueMedicineIds = order.items
          .map((item) => item.medicineId)
          .where((id) => id.isNotEmpty)
          .toSet();

      final medicineRefs = {
        for (final id in uniqueMedicineIds)
          id: _firestore.collection(medicinesCollection).doc(id),
      };

      final medicineSnapshots = <String, DocumentSnapshot>{};
      for (final entry in medicineRefs.entries) {
        medicineSnapshots[entry.key] = await transaction.get(entry.value);
      }

      // Order document ta write koro
      transaction.set(orderDocRef, order.toMap());

      // Ekই medicine multiple order item hisebe thakle quantity jog kore
      // ekbar e minus korbo
      final pendingDecrements = <String, int>{};
      for (final item in order.items) {
        if (item.medicineId.isEmpty) continue;
        pendingDecrements[item.medicineId] =
            (pendingDecrements[item.medicineId] ?? 0) + item.quantity;
      }

      for (final entry in pendingDecrements.entries) {
        final snapshot = medicineSnapshots[entry.key];
        if (snapshot == null || !snapshot.exists) continue;

        final data = snapshot.data() as Map<String, dynamic>?;
        final currentStock = (data?['stockQuantity'] as num?)?.toInt();
        if (currentStock == null) {
          continue; // is medicine er stock track kora hocche na, skip
        }

        final newStock = currentStock - entry.value;
        transaction.update(
          medicineRefs[entry.key]!,
          {'stockQuantity': newStock < 0 ? 0 : newStock},
        );
      }
    });

    return orderDocRef.id;
  }

  /// একটি user-এর সব order, সর্বশেষ আগে (real-time stream)
  Stream<List<MedicineOrder>> getUserOrders(String userId) {
    return _firestore
        .collection(ordersCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MedicineOrder.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Order cancel করা (শুধু pending থাকলে)
  Future<void> cancelOrder(String orderId) async {
    await _firestore.collection(ordersCollection).doc(orderId).update({
      'status': OrderStatus.cancelled.name,
    });

    // Notification history-te cancel entry add (fail hole o cancel-i main kaj)
    final order = await getOrderById(orderId);
    if (order != null) {
      try {
        await NotificationHistoryService().addNotification(
          userId: order.userId,
          title: 'Order cancelled',
          body: 'Your order #${orderId.substring(0, 6)} has been cancelled.',
          type: AppNotificationType.orderStatus,
          referenceId: orderId,
        );
      } catch (e) {
        // ignore: notification optional, cancel already succeeded
      }
    }
  }

  // ── Admin methods ────────────────────────────────────────────────────────

  /// সব user-এর সব order, সর্বশেষ আগে (Admin Dashboard-এর জন্য)
  Stream<List<MedicineOrder>> getAllOrders() {
    return _firestore
        .collection(ordersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MedicineOrder.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Order-এর status change করা (Admin Dashboard থেকে)
  /// FIX: status change hole user-er notification history-te entry add hoy,
  /// jate user "My Orders"-e giye check na kore o bell icon theke জানতে pare।
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _firestore.collection(ordersCollection).doc(orderId).update({
      'status': status.name,
    });

    final order = await getOrderById(orderId);
    if (order == null) return;

    final statusMessages = <OrderStatus, String>{
      OrderStatus.confirmed: 'Your order has been confirmed! 📦',
      OrderStatus.shipped: 'Your order is on the way! 🚚',
      OrderStatus.delivered: 'Your order has been delivered! ✅',
      OrderStatus.cancelled: 'Your order has been cancelled.',
    };

    final body = statusMessages[status];
    if (body == null) return; // pending-er jonno notification lagbe na

    // FIX: notification write fail hole o order status update fail hobe na —
    // e.g. Firestore rules e 'notifications' collection er rule na thakle
    // ekhane silently log kore ager mото kaj cholবে।
    try {
      await NotificationHistoryService().addNotification(
        userId: order.userId,
        title: 'Order ${status.label}',
        body: body,
        type: AppNotificationType.orderStatus,
        referenceId: orderId,
      );
    } catch (e) {
      // ignore: notification history holo optional feature, order status
      // update-i main kaj — eta fail korলেও silently log kore continue
    }
  }

  /// Fetch a single order by its ID
  Future<MedicineOrder?> getOrderById(String orderId) async {
    final doc = await _firestore
        .collection(ordersCollection)
        .doc(orderId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return MedicineOrder.fromMap(doc.id, doc.data()!);
  }
}