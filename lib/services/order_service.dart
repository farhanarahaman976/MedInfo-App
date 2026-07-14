import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String ordersCollection = 'orders';

  /// নতুন order Firestore-এ save করে, generated order ID return করে
  Future<String> placeOrder(MedicineOrder order) async {
    final docRef = await _firestore
        .collection(ordersCollection)
        .add(order.toMap());
    return docRef.id;
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
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _firestore.collection(ordersCollection).doc(orderId).update({
      'status': status.name,
    });
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
