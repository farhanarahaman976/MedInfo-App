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

  /// Medicine delete করা (Admin)
  Future<void> deleteMedicine(String id) async {
    await _firestore.collection(medicinesCollection).doc(id).delete();
  }
}