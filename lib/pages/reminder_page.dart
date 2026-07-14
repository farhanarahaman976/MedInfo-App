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

  @override
  void initState() {
    super.initState();
    // FIX: page open হলে permission check করো
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestPermission();
    });
  }

  // FIX: permission check — না থাকলে dialog দেখাও
  Future<void> _checkAndRequestPermission() async {
    final granted = await NotificationService().requestPermission();
    if (!granted && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Reminder কাজ করতে notification permission দরকার। '
            'Settings থেকে permission enable করুন।',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await NotificationService().requestPermission();
              },
              child: const Text('Allow'),
            ),
          ],
        ),
      );
    }
  }

  // ── Add Dialog ─────────────────────────────────────────────────────────────
  void _showAddReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => _ReminderDialog(
        title: 'Add Medicine Reminder',
        initialName: '',
        initialDosage: '',
        initialTime: TimeOfDay.now(),
        initialRepeatType: RepeatType.daily,
        initialWeekDays: const [],
        onSave: (name, dos, time, repeat, days) async {
          if (name.isEmpty || dos.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please fill all fields')),
            );
            return;
          }
          final reminder = MedicineReminder(
            id: const Uuid().v4(),
            medicineName: name,
            dosage: dos,
            time: time,
            repeatType: repeat,
            weekDays: days,
            isActive: true,
            createdAt: DateTime.now(),
          );
          // FIX: repository/notification e error hole eta ekhon dialog e catch hobe
          await _repository.addReminder(reminder);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Reminder added!')));
          }
        },
      ),
    );
  }

  // ── Edit Dialog ────────────────────────────────────────────────────────────
  void _showEditReminderDialog(MedicineReminder reminder) {
    showDialog(
      context: context,
      builder: (context) => _ReminderDialog(
        title: 'Edit Medicine Reminder',
        initialName: reminder.medicineName,
        initialDosage: reminder.dosage,
        initialTime: reminder.time,
        initialRepeatType: reminder.repeatType,
        initialWeekDays: List.from(reminder.weekDays),
        onSave: (name, dos, time, repeat, days) async {
          final updated = reminder.copyWith(
            medicineName: name,
            dosage: dos,
            time: time,
            repeatType: repeat,
            weekDays: days,
          );
          await _repository.updateReminder(updated);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Reminder updated!')));
          }
        },
      ),
    );
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> _deleteReminder(MedicineReminder reminder) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text('${reminder.medicineName} er reminder delete korbe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repository.deleteReminder(reminder.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reminder deleted')));
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Reminders')),
      body: StreamBuilder<List<MedicineReminder>>(
        stream: _repository.remindersStream(),
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
                leading: Icon(
                  Icons.medication_outlined,
                  color: reminder.isActive ? null : Colors.grey,
                ),
                title: Text(reminder.medicineName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${reminder.dosage} • ${reminder.scheduleText}'),
                    if (!reminder.isActive)
                      const Text(
                        'Disabled',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reminder.timeFormatted,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _showEditReminderDialog(reminder);
                        } else if (value == 'delete') {
                          await _deleteReminder(reminder);
                        } else if (value == 'toggle') {
                          await _repository.toggleReminder(
                            reminder.id,
                            !reminder.isActive,
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(reminder.isActive ? 'Disable' : 'Enable'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
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

// ══════════════════════════════════════════════════════════════════════════════
// Reusable dialog
// ══════════════════════════════════════════════════════════════════════════════

class _ReminderDialog extends StatefulWidget {
  final String title;
  final String initialName;
  final String initialDosage;
  final TimeOfDay initialTime;
  final RepeatType initialRepeatType;
  final List<int> initialWeekDays;
  final Future<void> Function(
    String name,
    String dosage,
    TimeOfDay time,
    RepeatType repeat,
    List<int> weekDays,
  )
  onSave;

  const _ReminderDialog({
    required this.title,
    required this.initialName,
    required this.initialDosage,
    required this.initialTime,
    required this.initialRepeatType,
    required this.initialWeekDays,
    required this.onSave,
  });

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dosageCtrl;
  late TimeOfDay _time;
  late RepeatType _repeatType;
  late List<int> _weekDays;
  bool _saving = false;

  // FIX: weekday names for weekly/custom selection
  static const _dayLabels = [
    '',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _dosageCtrl = TextEditingController(text: widget.initialDosage);
    _time = widget.initialTime;
    _repeatType = widget.initialRepeatType;
    _weekDays = List.from(widget.initialWeekDays);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  // FIX: Save button er pura logic ekhon try-catch-finally e wrap kora,
  // jate error hole spinner atke na thake ebong error message dekha jay.
  Future<void> _handleSave(bool showDayPicker) async {
    if (showDayPicker && _weekDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await widget.onSave(
        _nameCtrl.text.trim(),
        _dosageCtrl.text.trim(),
        _time,
        _repeatType,
        _weekDays,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showDayPicker =
        _repeatType == RepeatType.weekly || _repeatType == RepeatType.custom;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                hintText: 'e.g., Aspirin',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dosageCtrl,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                hintText: 'e.g., 500mg',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Time: ${_time.format(context)}')),
                ElevatedButton(onPressed: _pickTime, child: const Text('Pick')),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RepeatType>(
              initialValue: _repeatType,
              decoration: const InputDecoration(
                labelText: 'Repeat',
                border: OutlineInputBorder(),
              ),
              items: RepeatType.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _repeatType = v);
              },
            ),

            // FIX: weekly/custom হলে weekday picker দেখাও
            if (showDayPicker) ...[
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Days',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) {
                  final day = i + 1; // 1=Mon ... 7=Sun
                  final selected = _weekDays.contains(day);
                  return FilterChip(
                    label: Text(_dayLabels[day]),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _weekDays.add(day);
                        } else {
                          _weekDays.remove(day);
                        }
                      });
                    },
                  );
                }),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : () => _handleSave(showDayPicker),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}