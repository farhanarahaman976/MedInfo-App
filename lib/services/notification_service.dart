import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';

// ─── Background FCM Handler (top-level function) ────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handle
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Notification channel IDs
  static const String _dosageChannelId = 'dosage_reminder';
  static const String _healthTipChannelId = 'health_tips';
  static const String _missedChannelId = 'missed_dose';

  // ── Initialize ──────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // Timezone init
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    // Android init settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS init settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channels (Android)
    await _createChannels();

    // FCM setup
    await _setupFCM();

    // Schedule daily health tip
    await scheduleDailyHealthTip();
  }

  // ── Notification Channels ───────────────────────────────────────────────────

  Future<void> _createChannels() async {
    const dosageChannel = AndroidNotificationChannel(
      _dosageChannelId,
      'Dosage Reminders',
      description: 'Medicine dosage reminder notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const healthTipChannel = AndroidNotificationChannel(
      _healthTipChannelId,
      'Health Tips',
      description: 'Daily health tips',
      importance: Importance.defaultImportance,
    );

    const missedChannel = AndroidNotificationChannel(
      _missedChannelId,
      'Missed Dose Alerts',
      description: 'Alert when a dose is missed',
      importance: Importance.high,
      playSound: true,
    );

    final plugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await plugin?.createNotificationChannel(dosageChannel);
    await plugin?.createNotificationChannel(healthTipChannel);
    await plugin?.createNotificationChannel(missedChannel);
  }

  // ── FCM Setup ───────────────────────────────────────────────────────────────

  Future<void> _setupFCM() async {
    // Permission request
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _showSimpleNotification(
          id: message.hashCode,
          title: notification.title ?? 'MedInfo BD',
          body: notification.body ?? '',
          channelId: _healthTipChannelId,
        );
      }
    });

    // Get FCM token (save to Firestore for targeted notifications)
    final token = await _fcm.getToken();
    debugPrint('FCM Token: $token');
    // TODO: Save token to Firestore for user
  }

  // ── Notification Tap Handler ────────────────────────────────────────────────

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navigate to reminder page based on payload
  }

  // ── Request Permission ──────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }

  // ── Schedule Dosage Reminder ────────────────────────────────────────────────

  /// Schedule a repeating reminder for a medicine dose
  Future<void> scheduleDosageReminder({
    required int id,
    required String medicineName,
    required String dosage,
    required TimeOfDay time,
    required RepeatType repeatType,
    List<int>? weekDays, // 1=Mon ... 7=Sun (for weekly/custom)
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    switch (repeatType) {
      case RepeatType.daily:
        await _scheduleDailyReminder(
          id: id,
          medicineName: medicineName,
          dosage: dosage,
          time: time,
        );
        break;

      case RepeatType.weekly:
        // Schedule for each selected weekday
        final days = weekDays ?? [now.weekday];
        for (int i = 0; i < days.length; i++) {
          await _scheduleWeeklyReminder(
            id: id + i,
            medicineName: medicineName,
            dosage: dosage,
            time: time,
            weekDay: days[i],
          );
        }
        break;

      case RepeatType.custom:
        final days = weekDays ?? [now.weekday];
        for (int i = 0; i < days.length; i++) {
          await _scheduleWeeklyReminder(
            id: id + i,
            medicineName: medicineName,
            dosage: dosage,
            time: time,
            weekDay: days[i],
          );
        }
        break;
    }

    // Schedule missed dose check (30 min after reminder)
    await _scheduleMissedDoseCheck(
      id: id + 100,
      medicineName: medicineName,
      time: time,
      repeatType: repeatType,
    );
  }

  Future<void> _scheduleDailyReminder({
    required int id,
    required String medicineName,
    required String dosage,
    required TimeOfDay time,
  }) async {
    final scheduledDate = _nextInstanceOfTime(time);

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
            AndroidNotificationAction('taken', '✅ Taken'),
            AndroidNotificationAction('snooze', '⏰ Snooze 10 min'),
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
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      payload: jsonEncode({
        'type': 'dosage',
        'medicine': medicineName,
        'dosage': dosage,
      }),
    );
  }

  Future<void> _scheduleWeeklyReminder({
    required int id,
    required String medicineName,
    required String dosage,
    required TimeOfDay time,
    required int weekDay,
  }) async {
    final scheduledDate = _nextInstanceOfWeekday(time, weekDay);

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
            AndroidNotificationAction('taken', '✅ Taken'),
            AndroidNotificationAction('snooze', '⏰ Snooze 10 min'),
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
      }),
    );
  }

  Future<void> _scheduleMissedDoseCheck({
    required int id,
    required String medicineName,
    required TimeOfDay time,
    required RepeatType repeatType,
  }) async {
    // 30 minutes after the dose time
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
            AndroidNotificationAction('taken_now', '✅ Took it now'),
            AndroidNotificationAction('skip', '❌ Skip this dose'),
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
      payload: jsonEncode({'type': 'missed', 'medicine': medicineName}),
    );
  }

  // ── Daily Health Tip ────────────────────────────────────────────────────────

  Future<void> scheduleDailyHealthTip() async {
    // Send at 9:00 AM daily
    const tipTime = TimeOfDay(hour: 9, minute: 0);
    final scheduledDate = _nextInstanceOfTime(tipTime);
    final tip = _getRandomHealthTip();

    await _localNotifications.zonedSchedule(
      9999, // fixed ID for health tip
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
    );
  }

  String _getRandomHealthTip() {
    final tips = [
      '💧 বেশি পানি পান করুন। Hydration is the first step to better health.',
      '😴 ভালো ঘুম = ভালো জীবন — আজ বিশ্রাম নিন। আপনার শরীরও আরামের যোগ্য।',
      '🥗 স্বাস্থ্যকর খাবার খান — ফল ও শাকসবজি দিনচর্যায় রাখুন।',
      '🚶‍♀️ প্রতিদিন ৩০ মিনিট হাঁটুন, এটি আপনার মুড এবং শরীর দুইটাই উজ্জীবিত করবে।',
      '🧼 হাত ধুয়ে নিন — সুস্থ থাকার ছোট কিন্তু শক্তিশালী অভ্যাস।',
      '💊 ওষুধ নিয়মিত নিন এবং ডাক্তারের পরামর্শ মেনে চলুন।',
      '🌞 সকালের সূর্যের আলো নিন, এটি দেহে ভিটামিন ডি এবং উন্নত মনোবল আনে।',
      '🧘‍♂️ স্ট্রেস কমাতে একটু ধ্যান বা শ্বাস-প্রশ্বাস অনুশীলন করুন।',
      '🍎 স্বাস্থ্যকর জীবনের জন্য ভারসাম্যপূর্ণ খাদ্যাচরণ মেনে চলুন।',
      '📅 চিকিৎসার সময়সূচি মনেই রাখুন এবং প্রয়োজনে রিমাইন্ডার সেট করুন।',
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
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == _dosageChannelId ? 'Dosage Reminders' : 'Health Tips',
          importance: Importance.high,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true),
      ),
    );
  }

  // ── Cancel Reminder ─────────────────────────────────────────────────────────

  Future<void> cancelReminder(int id) async {
    await _localNotifications.cancel(id);
    await _localNotifications.cancel(id + 100); // missed dose check
  }

  Future<void> cancelAllReminders() async {
    await _localNotifications.cancelAll();
  }

  // ── Snooze ──────────────────────────────────────────────────────────────────

  Future<void> snoozeReminder({
    required int id,
    required String medicineName,
    required String dosage,
    int minutes = 10,
  }) async {
    final snoozeTime = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(minutes: minutes));

    await _localNotifications.zonedSchedule(
      id + 200,
      '💊 Snoozed Reminder',
      '$medicineName — $dosage (snoozed $minutes min)',
      snoozeTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dosageChannelId,
          'Dosage Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Time Helpers ────────────────────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
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

  // ── Pending Notifications List ───────────────────────────────────────────────

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }
}

// ─── Enums ──────────────────────────────────────────────────────────────────────

enum RepeatType { daily, weekly, custom }

extension RepeatTypeLabel on RepeatType {
  String get label {
    switch (this) {
      case RepeatType.daily:
        return 'Daily';
      case RepeatType.weekly:
        return 'Weekly';
      case RepeatType.custom:
        return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case RepeatType.daily:
        return Icons.repeat_rounded;
      case RepeatType.weekly:
        return Icons.calendar_view_week_rounded;
      case RepeatType.custom:
        return Icons.tune_rounded;
    }
  }
}
