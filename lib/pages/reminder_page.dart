import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/medicine_reminder.dart';
import '../repositories/reminder_repository.dart';
import '../services/notification_service.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final ReminderRepository _repository = ReminderRepository();
  late Future<List<MedicineReminder>> _remindersFuture;

  @override
  void initState() {
    super.initState();
    _remindersFuture = _repository.loadReminders();
  }

  void _refreshReminders() {
    setState(() {
      _remindersFuture = _repository.loadReminders();
    });
  }

  void _showAddReminderDialog() {
    String medicineName = '';
    String dosage = '';
    TimeOfDay selectedTime = TimeOfDay.now();
    RepeatType selectedRepeatType = RepeatType.daily;
    List<int> selectedWeekDays = [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medicine Reminder'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Medicine Name
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                  hintText: 'e.g., Aspirin',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => medicineName = value,
              ),
              const SizedBox(height: 12),
              // Dosage
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'e.g., 500mg',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => dosage = value,
              ),
              const SizedBox(height: 12),
              // Time Picker
              Row(
                children: [
                  Expanded(
                    child: Text('Time: ${selectedTime.format(context)}'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        selectedTime = time;
                      }
                    },
                    child: const Text('Pick'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Repeat Type Dropdown
              DropdownButtonFormField<RepeatType>(
                initialValue: selectedRepeatType,
                decoration: const InputDecoration(
                  labelText: 'Repeat',
                  border: OutlineInputBorder(),
                ),
                items: RepeatType.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.toString().split('.').last),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedRepeatType = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (medicineName.isEmpty || dosage.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final reminder = MedicineReminder(
                id: const Uuid().v4(),
                medicineName: medicineName,
                dosage: dosage,
                time: selectedTime,
                repeatType: selectedRepeatType,
                weekDays: selectedWeekDays,
                isActive: true,
                createdAt: DateTime.now(),
              );

              await _repository.addReminder(reminder);
              _refreshReminders();

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder added!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Reminders')),
      body: FutureBuilder<List<MedicineReminder>>(
        future: _remindersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reminders = snapshot.data ?? [];
          if (reminders.isEmpty) {
            return const Center(
              child: Text('No reminders yet. Tap the + button to add one.'),
            );
          }

          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return ListTile(
                title: Text(reminder.medicineName),
                subtitle: Text('${reminder.dosage} • ${reminder.scheduleText}'),
                trailing: Text(
                  reminder.timeFormatted,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
