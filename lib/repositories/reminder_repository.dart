import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine_reminder.dart';
import '../services/notification_service.dart';

class ReminderRepository {
  static const String _key = 'medicine_reminders';

  // ── Load all reminders ──────────────────────────────────────────────────────

  Future<List<MedicineReminder>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonStr);
    return jsonList
        .map((e) => MedicineReminder.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) {
        final aMinutes = a.time.hour * 60 + a.time.minute;
        final bMinutes = b.time.hour * 60 + b.time.minute;
        return aMinutes.compareTo(bMinutes);
      });
  }

  // ── Save all reminders ──────────────────────────────────────────────────────

  Future<void> _saveAll(List<MedicineReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr =
        jsonEncode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }

  // ── Add reminder ────────────────────────────────────────────────────────────

  Future<void> addReminder(MedicineReminder reminder) async {
    final reminders = await loadReminders();
    reminders.add(reminder);
    await _saveAll(reminders);

    // Schedule notification
    if (reminder.isActive) {
      await NotificationService().scheduleDosageReminder(
        id: reminder.notificationId,
        medicineName: reminder.medicineName,
        dosage: reminder.dosage,
        time: reminder.time,
        repeatType: reminder.repeatType,
        weekDays: reminder.weekDays.isEmpty ? null : reminder.weekDays,
      );
    }
  }

  // ── Update reminder ─────────────────────────────────────────────────────────

  Future<void> updateReminder(MedicineReminder updated) async {
    final reminders = await loadReminders();
    final index = reminders.indexWhere((r) => r.id == updated.id);
    if (index == -1) return;

    // Cancel old notification
    await NotificationService().cancelReminder(reminders[index].notificationId);

    reminders[index] = updated;
    await _saveAll(reminders);

    // Re-schedule if active
    if (updated.isActive) {
      await NotificationService().scheduleDosageReminder(
        id: updated.notificationId,
        medicineName: updated.medicineName,
        dosage: updated.dosage,
        time: updated.time,
        repeatType: updated.repeatType,
        weekDays: updated.weekDays.isEmpty ? null : updated.weekDays,
      );
    }
  }

  // ── Toggle active ───────────────────────────────────────────────────────────

  Future<void> toggleReminder(String id, bool isActive) async {
    final reminders = await loadReminders();
    final index = reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final reminder = reminders[index];
    final updated = reminder.copyWith(isActive: isActive);
    reminders[index] = updated;
    await _saveAll(reminders);

    if (isActive) {
      await NotificationService().scheduleDosageReminder(
        id: updated.notificationId,
        medicineName: updated.medicineName,
        dosage: updated.dosage,
        time: updated.time,
        repeatType: updated.repeatType,
        weekDays: updated.weekDays.isEmpty ? null : updated.weekDays,
      );
    } else {
      await NotificationService().cancelReminder(updated.notificationId);
    }
  }

  // ── Delete reminder ─────────────────────────────────────────────────────────

  Future<void> deleteReminder(String id) async {
    final reminders = await loadReminders();
    final reminder = reminders.firstWhere((r) => r.id == id);

    await NotificationService().cancelReminder(reminder.notificationId);

    reminders.removeWhere((r) => r.id == id);
    await _saveAll(reminders);
  }
}