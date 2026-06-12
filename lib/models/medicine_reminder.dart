import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class MedicineReminder {
  final String id;
  final String medicineName;
  final String dosage;
  final TimeOfDay time;
  final RepeatType repeatType;
  final List<int> weekDays; // 1=Mon, 2=Tue ... 7=Sun
  final bool isActive;
  final DateTime createdAt;
  final String? notes;

  const MedicineReminder({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.time,
    required this.repeatType,
    this.weekDays = const [],
    this.isActive = true,
    required this.createdAt,
    this.notes,
  });

  // Unique notification ID from string id
  int get notificationId => id.hashCode.abs() % 100000;

  MedicineReminder copyWith({
    String? medicineName,
    String? dosage,
    TimeOfDay? time,
    RepeatType? repeatType,
    List<int>? weekDays,
    bool? isActive,
    String? notes,
  }) {
    return MedicineReminder(
      id: id,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      repeatType: repeatType ?? this.repeatType,
      weekDays: weekDays ?? this.weekDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicineName': medicineName,
        'dosage': dosage,
        'timeHour': time.hour,
        'timeMinute': time.minute,
        'repeatType': repeatType.index,
        'weekDays': weekDays,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
      };

  factory MedicineReminder.fromJson(Map<String, dynamic> json) {
    return MedicineReminder(
      id: json['id'] as String,
      medicineName: json['medicineName'] as String,
      dosage: json['dosage'] as String,
      time: TimeOfDay(
        hour: json['timeHour'] as int,
        minute: json['timeMinute'] as int,
      ),
      repeatType: RepeatType.values[json['repeatType'] as int],
      weekDays: List<int>.from(json['weekDays'] ?? []),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  String get timeFormatted {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String get weekDaysFormatted {
    if (weekDays.isEmpty) return '';
    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekDays.map((d) => dayNames[d]).join(', ');
  }

  String get scheduleText {
    switch (repeatType) {
      case RepeatType.daily:
        return 'Every day at $timeFormatted';
      case RepeatType.weekly:
        return 'Weekly on $weekDaysFormatted at $timeFormatted';
      case RepeatType.custom:
        return 'Custom: $weekDaysFormatted at $timeFormatted';
    }
  }
}