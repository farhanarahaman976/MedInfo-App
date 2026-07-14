import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/medicine_reminder.dart';
import 'notification_service.dart';

class ReminderService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // main.dart e call hoy — NotificationService initialize kore
  Future<void> init() async {
    await NotificationService().initialize();
  }

  // Login er pore sob active reminder re-schedule koro
  Future<void> rescheduleAllOnLogin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('reminders')
          .get();

      for (final doc in snapshot.docs) {
        final reminder = MedicineReminder.fromFirestore(doc.data(), doc.id);
        if (!reminder.isActive) continue;

        await NotificationService().scheduleDosageReminder(
          id: reminder.notificationId,
          medicineName: reminder.medicineName,
          dosage: reminder.dosage,
          time: reminder.time,
          repeatType: reminder.repeatType,
          weekDays: reminder.weekDays.isEmpty ? null : reminder.weekDays,
          medicineId: reminder.medicineName,
        );
      }
    } catch (e) {
      // login block kora uchit na
    }
  }

  // Logout e sob reminder cancel koro
  Future<void> cancelAllOnLogout() async {
    await NotificationService().cancelAllOnLogout();
  }
}