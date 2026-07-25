import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine.dart';

class MedicineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String medicinesCollection = 'medicines';

  /// সব medicine real-time stream — app এবং Admin দুই জায়গাতেই ব্যবহার হবে
  Stream<List<Medicine>> getAllMedicines() {
    return _firestore.collection(medicinesCollection).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Medicine.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  /// নতুন medicine add করা (Admin)
  Future<void> addMedicine(Medicine medicine) async {
    await _firestore.collection(medicinesCollection).add(medicine.toMap());
  }

  /// Existing medicine update করা (Admin)
  Future<void> updateMedicine(Medicine medicine) async {
    if (medicine.id.isEmpty) {
      throw Exception('Medicine ID missing — update করা যাবে না');
    }
    await _firestore
        .collection(medicinesCollection)
        .doc(medicine.id)
        .update(medicine.toMap());
  }

  /// NOTUN: shudhu stockQuantity field ta update kore — Admin medicine list e
  /// inline +/- stepper theke direct call hoy, tai puro medicine document
  /// rewrite korar dorkar nai, ekta field-i update hoy.
  Future<void> updateStock(String id, int newStock) async {
    if (id.isEmpty) {
      throw Exception('Medicine ID missing — stock update করা যাবে না');
    }
    await _firestore.collection(medicinesCollection).doc(id).update({
      'stockQuantity': newStock < 0 ? 0 : newStock,
    });
  }

  /// Medicine delete করা (Admin)
  Future<void> deleteMedicine(String id) async {
    await _firestore.collection(medicinesCollection).doc(id).delete();
  }
}