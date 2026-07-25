import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine.dart';

/// Persists the user's cart in Firestore under users/{uid}/cart/{medicineId},
/// so the cart survives app restarts and logout/login cycles instead of
/// living only in in-memory GetX state.
class CartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _cartRef(String uid) {
    return _db.collection('users').doc(uid).collection('cart');
  }

  /// Saves (or overwrites) one cart item, including its current quantity.
  Future<void> saveCartItem(String uid, Medicine medicine) async {
    if (medicine.id.isEmpty) return; // safety: need a stable doc id
    await _cartRef(uid).doc(medicine.id).set(medicine.toMap());
  }

  /// Removes one item from the saved cart.
  Future<void> removeCartItem(String uid, String medicineId) async {
    if (medicineId.isEmpty) return;
    await _cartRef(uid).doc(medicineId).delete();
  }

  /// Deletes every saved cart item for this user (e.g. after an order is placed).
  Future<void> clearCart(String uid) async {
    final snapshot = await _cartRef(uid).get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// One-time fetch of the saved cart, used right after login to restore it.
  Future<List<Medicine>> loadCart(String uid) async {
    final snapshot = await _cartRef(uid).get();
    return snapshot.docs
        .map((doc) => Medicine.fromMap(doc.data(), doc.id))
        .toList();
  }
}