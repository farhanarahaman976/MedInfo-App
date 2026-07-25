import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_tip.dart';

class HealthTipService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tipsRef =>
      _db.collection('health_tips');

  /// Live stream of tips, ordered by the admin-set 'order' field.
  Stream<List<HealthTip>> getAllTips() {
    return _tipsRef.orderBy('order').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => HealthTip.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<void> addTip(HealthTip tip) async {
    await _tipsRef.add(tip.toMap());
  }

  Future<void> updateTip(String id, HealthTip tip) async {
    await _tipsRef.doc(id).update(tip.toMap());
  }

  Future<void> deleteTip(String id) async {
    await _tipsRef.doc(id).delete();
  }
}