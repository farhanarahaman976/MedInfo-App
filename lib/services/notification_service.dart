import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../services/order_service.dart';
import '../pages/order_details_page.dart';
import '../pages/reminder_page.dart';

// ─── Background FCM Handler ──────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

@pragma('vm:entry-point')
void localNotificationTapBackground(NotificationResponse response) {
  debugPrint('Background notification tap: ${response.payload}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static const String _dosageChannelId   = 'dosage_reminder';
  static const String _healthTipChannelId = 'health_tips';
  static const String _missedChannelId   = 'missed_dose';
  static const String _orderChannelId    = 'order_updates';

  // ── Initialize ──────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: localNotificationTapBackground,
    );

    await _createChannels();
    await _setupFCM();
    await scheduleDailyHealthTip();
  }

  Future<void> init() async => initialize();

  // ── Channels ────────────────────────────────────────────────────────────────

  Future<void> _createChannels() async {
    final plugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await plugin?.createNotificationChannel(const AndroidNotificationChannel(
      _dosageChannelId, 'Dosage Reminders',
      description: 'Medicine dosage reminder notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    ));
    await plugin?.createNotificationChannel(const AndroidNotificationChannel(
      _healthTipChannelId, 'Health Tips',
      description: 'Daily health tips',
      importance: Importance.defaultImportance,
    ));
    await plugin?.createNotificationChannel(const AndroidNotificationChannel(
      _missedChannelId, 'Missed Dose Alerts',
      description: 'Alert when a dose is missed',
      importance: Importance.high,
      playSound: true,
    ));
    await plugin?.createNotificationChannel(const AndroidNotificationChannel(
      _orderChannelId, 'Order Updates',
      description: 'Order submission and delivery updates',
      importance: Importance.high,
      playSound: true,
    ));
  }

  // ── FCM ─────────────────────────────────────────────────────────────────────

  Future<void> _setupFCM() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _showSimpleNotification(
          id: message.hashCode,
          title: notification.title ?? 'MedInfo BD',
          body: notification.body ?? '',
          channelId: _healthTipChannelId,
          payload: jsonEncode({'type': 'health_tip', 'body': notification.body}),
        );
      }
    });
    final token = await _fcm.getToken();
    debugPrint('FCM Token: $token');
  }

  // ── Tap Handler ─────────────────────────────────────────────────────────────

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    try {
      final data = jsonDecode(payload);
      if (data is Map && data['type'] != null) {
        final type = data['type'] as String;
        if (type == 'order' || type == 'order_followup') {
          final orderId = data['orderId']?.toString();
          if (orderId != null) {
            OrderService().getOrderById(orderId).then((order) {
              if (order != null) Get.to(() => OrderDetailsPage(order: order));
            });
            return;
          }
        }
        if (type == 'dosage' || type == 'missed' || type == 'snooze') {
          Get.to(() => const ReminderPage());
          return;
        }
      }
    } catch (e) {
      debugPrint('Notification tap error: $e');
    }
  }

  // ── FIX 1: Permission request — exact alarm permission check ────────────────

  /// Returns true if notification permission is granted.
  /// On Android 13+ (API 33) also requests POST_NOTIFICATIONS.
  /// On Android 12+ (API 31) checks SCHEDULE_EXACT_ALARM.
  Future<bool> requestPermission() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // POST_NOTIFICATIONS permission (Android 13+)
    final granted = await androidPlugin?.requestNotificationsPermission();

    // FIX: exact alarm permission check (Android 12+)
    final exactAlarmGranted =
        await androidPlugin?.requestExactAlarmsPermission();

    debugPrint(
        'Notification permission: $granted | Exact alarm: $exactAlarmGranted');

    return granted ?? false;
  }

  // ── Schedule Dosage Reminder ────────────────────────────────────────────────

  Future<void> scheduleDosageReminder({
    required int id,
    required String medicineName,
    required String dosage,
    required TimeOfDay time,
    required RepeatType repeatType,
    List<int>? weekDays,
    String? medicineId,
  }) async {
    // FIX 2: permission check kore tarpor schedule korbe
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final hasExactAlarm = await androidPlugin?.canScheduleExactNotifications();
    if (hasExactAlarm == false) {
      debugPrint('Exact alarm permission not granted — requesting...');
      await androidPlugin?.requestExactAlarmsPermission();
      // Re-check after request
      final recheckExact =
          await androidPlugin?.canScheduleExactNotifications();
      if (recheckExact == false) {
        debugPrint('Exact alarm still denied — skipping schedule');
        return;
      }
    }

    final now = tz.TZDateTime.now(tz.local);

    switch (repeatType) {
      case RepeatType.daily:
        await _scheduleDailyReminder(
          id: id,
          medicineName: medicineName,
          dosage: dosage,
          time: time,
          medicineId: medicineId,
        );
        break;

      case RepeatType.weekly:
      case RepeatType.custom:
        final days = (weekDays != null && weekDays.isNotEmpty)
            ? weekDays
            : [now.weekday];
        for (int i = 0; i < days.length; i++) {
          await _scheduleWeeklyReminder(
            id: id + i,
            medicineName: medicineName,
            dosage: dosage,
            time: time,
            weekDay: days[i],
            medicineId: medicineId,
          );
        }
        break;
    }

    // Missed dose check (30 min after)
    await _scheduleMissedDoseCheck(
      id: id + 100,
      medicineName: medicineName,
      time: time,
      repeatType: repeatType,
      medicineId: medicineId,
    );

    debugPrint(
        'Reminder scheduled: $medicineName at ${time.hour}:${time.minute} [$repeatType]');
  }

  Future<void> _scheduleDailyReminder({
    required int id,
    required String medicineName,
    required String dosage,
    required TimeOfDay time,
    String? medicineId,
  }) async {
    final scheduledDate = _nextInstanceOfTime(time);
    debugPrint('Daily reminder at: $scheduledDate');

    await _localNotifications.zonedSchedule(
      id,
      '💊 Time to take your medicine!',
      '$medicineName — $dosage',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dosageChannelId,
          'Dosage Reminders',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            'It\'s time to take $medicineName ($dosage). Don\'t miss your dose!',
          ),
          actions: [
            const AndroidNotificationAction('taken', '✅ Taken'),
            const AndroidNotificationAction('snooze', '⏰ Snooze 10 min'),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({
        'type': 'dosage',
        'medicine': medicineName,
        'dosage': dosage,
        'medicineId': medicineId ?? medicineName,
      }),
    );
  }

  Future<void> _scheduleWeeklyReminder({
    required int id,
    required String medicineName,
    required String dosage,
    required TimeOfDay time,
    required int weekDay,
    String? medicineId,
  }) async {
    final scheduledDate = _nextInstanceOfWeekday(time, weekDay);
    debugPrint('Weekly reminder at: $scheduledDate (weekday: $weekDay)');

    await _localNotifications.zonedSchedule(
      id,
      '💊 Time to take your medicine!',
      '$medicineName — $dosage',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dosageChannelId,
          'Dosage Reminders',
          importance: Importance.max,
          priority: Priority.high,
          actions: [
            const AndroidNotificationAction('taken', '✅ Taken'),
            const AndroidNotificationAction('snooze', '⏰ Snooze 10 min'),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: jsonEncode({
        'type': 'dosage',
        'medicine': medicineName,
        'dosage': dosage,
        'medicineId': medicineId ?? medicineName,
      }),
    );
  }

  Future<void> _scheduleMissedDoseCheck({
    required int id,
    required String medicineName,
    required TimeOfDay time,
    required RepeatType repeatType,
    String? medicineId,
  }) async {
    final missedTime = TimeOfDay(
      hour: (time.minute + 30 >= 60) ? (time.hour + 1) % 24 : time.hour,
      minute: (time.minute + 30) % 60,
    );
    final scheduledDate = _nextInstanceOfTime(missedTime);

    await _localNotifications.zonedSchedule(
      id,
      '⚠️ Did you take your medicine?',
      'You may have missed your $medicineName dose!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _missedChannelId,
          'Missed Dose Alerts',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            const AndroidNotificationAction('taken_now', '✅ Took it now'),
            const AndroidNotificationAction('skip', '❌ Skip this dose'),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: repeatType == RepeatType.daily
          ? DateTimeComponents.time
          : DateTimeComponents.dayOfWeekAndTime,
      payload: jsonEncode({
        'type': 'missed',
        'medicine': medicineName,
        'medicineId': medicineId ?? medicineName,
      }),
    );
  }

  // ── Health Tip ──────────────────────────────────────────────────────────────

  Future<void> scheduleDailyHealthTip() async {
    const tipTime = TimeOfDay(hour: 9, minute: 0);
    final scheduledDate = _nextInstanceOfTime(tipTime);
    final tip = _getRandomHealthTip();

    await _localNotifications.zonedSchedule(
      9999,
      '💊 MedInfo Health Tip',
      tip,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _healthTipChannelId,
          'Health Tips',
          importance: Importance.defaultImportance,
          styleInformation: BigTextStyleInformation(tip),
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({'type': 'health_tip', 'tip': tip}),
    );
  }

  String _getRandomHealthTip() {
    final tips = [
      '💧 বেশি পানি পান করুন। Hydration is the first step to better health.',
      '😴 ভালো ঘুম = ভালো জীবন — আজ বিশ্রাম নিন।',
      '🥗 স্বাস্থ্যকর খাবার খান — ফল ও শাকসবজি দিনচর্যায় রাখুন।',
      '🚶‍♀️ প্রতিদিন ৩০ মিনিট হাঁটুন।',
      '🧼 হাত ধুয়ে নিন — সুস্থ থাকার ছোট কিন্তু শক্তিশালী অভ্যাস।',
      '💊 ওষুধ নিয়মিত নিন এবং ডাক্তারের পরামর্শ মেনে চলুন।',
      '🌞 সকালের সূর্যের আলো নিন।',
      '🧘‍♂️ স্ট্রেস কমাতে ধ্যান বা শ্বাস-প্রশ্বাস অনুশীলন করুন।',
      '🍎 ভারসাম্যপূর্ণ খাদ্যাচরণ মেনে চলুন।',
      '📅 চিকিৎসার সময়সূচি মনে রাখুন।',
    ];
    tips.shuffle();
    return tips.first;
  }

  // ── Simple Notification ─────────────────────────────────────────────────────

  Future<void> _showSimpleNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    await _localNotifications.show(
      id, title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == _dosageChannelId ? 'Dosage Reminders' : 'Health Tips',
          importance: Importance.high,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true),
      ),
      payload: payload,
    );
  }

  // ── Order Notification ──────────────────────────────────────────────────────

  Future<void> notifyOrderSubmitted({
    required String orderId,
    required String title,
    required String body,
    DateTime? followUpAt,
    int followUpDelayMinutes = 60,
    String? followUpTitle,
    String? followUpBody,
  }) async {
    final baseId = orderId.hashCode.abs() % 100000;

    await _localNotifications.show(
      baseId, title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _orderChannelId, 'Order Updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true),
      ),
      payload: jsonEncode({'type': 'order', 'orderId': orderId}),
    );

    tz.TZDateTime scheduled;
    if (followUpAt != null) {
      scheduled = tz.TZDateTime.from(followUpAt, tz.local);
      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
        scheduled = tz.TZDateTime.now(tz.local)
            .add(Duration(minutes: followUpDelayMinutes));
      }
    } else {
      scheduled = tz.TZDateTime.now(tz.local)
          .add(Duration(minutes: followUpDelayMinutes));
    }

    await _localNotifications.zonedSchedule(
      baseId + 1,
      followUpTitle ?? 'Order update',
      followUpBody ?? 'Status update for order $orderId',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _orderChannelId, 'Order Updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'type': 'order_followup', 'orderId': orderId}),
    );
  }

  // ── Cancel ──────────────────────────────────────────────────────────────────

  Future<void> cancelReminder(int id) async {
    await _localNotifications.cancel(id);
    await _localNotifications.cancel(id + 100); // missed dose
  }

  Future<void> cancelAllReminders() async {
    await _localNotifications.cancelAll();
  }

  // FIX 3: cancelAllOnLogout — profile_page e call hocche, method ta add kora holo
  Future<void> cancelAllOnLogout() async {
    await cancelAllReminders();
    debugPrint('All reminders cancelled on logout');
  }

  // ── Snooze ──────────────────────────────────────────────────────────────────

  Future<void> snoozeReminder({
    required int id,
    required String medicineName,
    required String dosage,
    int minutes = 10,
    String? medicineId,
  }) async {
    final snoozeTime =
        tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));

    await _localNotifications.zonedSchedule(
      id + 200,
      '💊 Snoozed Reminder',
      '$medicineName — $dosage (snoozed $minutes min)',
      snoozeTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dosageChannelId, 'Dosage Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({
        'type': 'snooze',
        'medicine': medicineName,
        'dosage': dosage,
        'medicineId': medicineId ?? medicineName,
      }),
    );
  }

  // ── Grouped / Medicine-level helpers ────────────────────────────────────────

  Future<Map<String, List<PendingNotificationRequest>>>
      getRemindersGroupedByMedicine() async {
    final pending = await getPendingNotifications();
    final Map<String, List<PendingNotificationRequest>> map = {};
    for (final p in pending) {
      final medId = _extractMedicineIdFromPayload(p.payload);
      if (medId == null) continue;
      map.putIfAbsent(medId, () => []).add(p);
    }
    return map;
  }

  Future<void> deleteRemindersForMedicine(String medicineId) async {
    final pending = await getPendingNotifications();
    for (final p in pending) {
      if (_extractMedicineIdFromPayload(p.payload) == medicineId) {
        await _localNotifications.cancel(p.id);
      }
    }
  }

  Future<void> editReminderForMedicine({
    required String medicineId,
    required int newId,
    required String medicineName,
    required String dosage,
    required TimeOfDay time,
    required RepeatType repeatType,
    List<int>? weekDays,
  }) async {
    await deleteRemindersForMedicine(medicineId);
    await scheduleDosageReminder(
      id: newId,
      medicineName: medicineName,
      dosage: dosage,
      time: time,
      repeatType: repeatType,
      weekDays: weekDays,
      medicineId: medicineId,
    );
  }

  String? _extractMedicineIdFromPayload(String? payload) {
    if (payload == null) return null;
    try {
      final data = jsonDecode(payload);
      if (data is Map) {
        if (data['medicineId'] != null) return data['medicineId'].toString();
        if (data['medicine'] != null) return data['medicine'].toString();
      }
    } catch (_) {}
    return null;
  }

  // ── Time Helpers ────────────────────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now) ||
        scheduled.difference(now).inSeconds < 5) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(TimeOfDay time, int weekDay) {
    var scheduled = _nextInstanceOfTime(time);
    while (scheduled.weekday != weekDay) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }
}

// ─── Enums ───────────────────────────────────────────────────────────────────

enum RepeatType { daily, weekly, custom }

extension RepeatTypeLabel on RepeatType {
  String get label {
    switch (this) {
      case RepeatType.daily:   return 'Daily';
      case RepeatType.weekly:  return 'Weekly';
      case RepeatType.custom:  return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case RepeatType.daily:   return Icons.repeat_rounded;
      case RepeatType.weekly:  return Icons.calendar_view_week_rounded;
      case RepeatType.custom:  return Icons.tune_rounded;
    }
  }
}