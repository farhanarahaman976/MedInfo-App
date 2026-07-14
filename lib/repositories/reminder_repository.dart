import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medicine_reminder.dart';
import '../services/notification_service.dart';

class ReminderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user er reminders subcollection reference
  CollectionReference<Map<String, dynamic>>? get _ref {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('reminders');
  }

  // ── Stream: real-time list (Controller e use korbe) ────────────────────────

  Stream<List<MedicineReminder>> remindersStream() {
    final ref = _ref;
    if (ref == null) return const Stream.empty();

    return ref
        .orderBy('timeHour')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicineReminder.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // ── Load all reminders (one-time fetch) ────────────────────────────────────

  Future<List<MedicineReminder>> loadReminders() async {
    final ref = _ref;
    if (ref == null) return [];

    final snapshot = await ref.orderBy('timeHour').get();
    return snapshot.docs
        .map((doc) => MedicineReminder.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // ── Add reminder ────────────────────────────────────────────────────────────

  Future<void> addReminder(MedicineReminder reminder) async {
    final ref = _ref;
    if (ref == null) return;

    // Firestore e save (id auto-generate hobe)
    final docRef = await ref.add(reminder.toFirestore());

    // Notification schedule — Firestore generated id use korbe
    if (reminder.isActive) {
      final saved = reminder.copyWith(id: docRef.id);
      await NotificationService().scheduleDosageReminder(
        id: saved.notificationId,
        medicineName: saved.medicineName,
        dosage: saved.dosage,
        time: saved.time,
        repeatType: saved.repeatType,
        weekDays: saved.weekDays.isEmpty ? null : saved.weekDays,
        medicineId: saved.medicineName,
      );
    }
  }

  // ── Update reminder ─────────────────────────────────────────────────────────

  Future<void> updateReminder(MedicineReminder updated) async {
    final ref = _ref;
    if (ref == null) return;

    // Old notification cancel
    await NotificationService().cancelReminder(updated.notificationId);

    // Firestore update
    await ref.doc(updated.id).update(updated.toFirestore());

    // Re-schedule if active
    if (updated.isActive) {
      await NotificationService().scheduleDosageReminder(
        id: updated.notificationId,
        medicineName: updated.medicineName,
        dosage: updated.dosage,
        time: updated.time,
        repeatType: updated.repeatType,
        weekDays: updated.weekDays.isEmpty ? null : updated.weekDays,
        medicineId: updated.medicineName,
      );
    }
  }

  // ── Toggle active ───────────────────────────────────────────────────────────

  Future<void> toggleReminder(String id, bool isActive) async {
    final ref = _ref;
    if (ref == null) return;

    await ref.doc(id).update({'isActive': isActive});

    // Notification handle
    final snapshot = await ref.doc(id).get();
    if (!snapshot.exists) return;

    final reminder = MedicineReminder.fromFirestore(snapshot.data()!, id);

    if (isActive) {
      await NotificationService().scheduleDosageReminder(
        id: reminder.notificationId,
        medicineName: reminder.medicineName,
        dosage: reminder.dosage,
        time: reminder.time,
        repeatType: reminder.repeatType,
        weekDays: reminder.weekDays.isEmpty ? null : reminder.weekDays,
        medicineId: reminder.medicineName,
      );
    } else {
      await NotificationService().cancelReminder(reminder.notificationId);
    }
  }

  // ── Delete reminder ─────────────────────────────────────────────────────────

  Future<void> deleteReminder(String id) async {
    final ref = _ref;
    if (ref == null) return;

    // Notification cancel korar age data fetch koro
    final snapshot = await ref.doc(id).get();
    if (snapshot.exists) {
      final reminder = MedicineReminder.fromFirestore(snapshot.data()!, id);
      await NotificationService().cancelReminder(reminder.notificationId);
    }

    await ref.doc(id).delete();
  }
}