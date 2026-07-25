import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/medicine_reminder.dart';
import '../repositories/reminder_repository.dart';
import '../services/notification_service.dart';

// ── Brand accent colors (same in light & dark) ──────────────────────────────
const _kPrimaryBlue = Color(0xFF3B82C4);
const _kPrimaryTeal = Color(0xFF0F6E56);
const _kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_kPrimaryBlue, _kPrimaryTeal],
);

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
    // Check notification permission right after the page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestPermission();
    });
  }

  // Show a dialog if notification permission is not granted
  Future<void> _checkAndRequestPermission() async {
    final granted = await NotificationService().requestPermission();
    if (!granted && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: _kGradient,
            ),
            child: const Icon(Icons.notifications_active_rounded, color: Colors.white),
          ),
          title: const Text('Permission Required'),
          content: const Text(
            'Reminders need notification permission to work. '
            'Please enable it from Settings.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: _kGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await NotificationService().requestPermission();
                },
                child: const Text('Allow', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }
  }

  // ── Add / Edit bottom sheet ──────────────────────────────────────────────
  void _showAddReminderSheet() {
    _showReminderSheet(
      title: 'Add Medicine Reminder',
      initialName: '',
      initialDosage: '',
      initialTime: TimeOfDay.now(),
      initialRepeatType: RepeatType.daily,
      initialWeekDays: const [],
      onSave: (name, dos, time, repeat, days) async {
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
        await _repository.addReminder(reminder);
        if (mounted) {
          Navigator.pop(context);
          _showSnack('Reminder added!');
        }
      },
    );
  }

  void _showEditReminderSheet(MedicineReminder reminder) {
    _showReminderSheet(
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
          _showSnack('Reminder updated!');
        }
      },
    );
  }

  void _showReminderSheet({
    required String title,
    required String initialName,
    required String initialDosage,
    required TimeOfDay initialTime,
    required RepeatType initialRepeatType,
    required List<int> initialWeekDays,
    required Future<void> Function(
      String name,
      String dosage,
      TimeOfDay time,
      RepeatType repeat,
      List<int> weekDays,
    ) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReminderSheet(
        title: title,
        initialName: initialName,
        initialDosage: initialDosage,
        initialTime: initialTime,
        initialRepeatType: initialRepeatType,
        initialWeekDays: initialWeekDays,
        onSave: onSave,
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : _kPrimaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Delete ───────────────────────────────────────────────────────────────
  Future<void> _deleteReminder(MedicineReminder reminder) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.1),
          ),
          child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
        ),
        title: const Text('Delete reminder?'),
        content: Text(
          'Delete the reminder for ${reminder.medicineName}?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repository.deleteReminder(reminder.id);
      if (mounted) _showSnack('Reminder deleted');
    }
  }

  // ── Group reminders by time-of-day period ───────────────────────────────
  static const _periods = ['Morning', 'Afternoon', 'Evening', 'Night'];

  String _periodOf(TimeOfDay t) {
    if (t.hour >= 5 && t.hour < 12) return 'Morning';
    if (t.hour >= 12 && t.hour < 17) return 'Afternoon';
    if (t.hour >= 17 && t.hour < 21) return 'Evening';
    return 'Night';
  }

  IconData _periodIcon(String period) {
    switch (period) {
      case 'Morning':
        return Icons.wb_twilight_rounded;
      case 'Afternoon':
        return Icons.wb_sunny_rounded;
      case 'Evening':
        return Icons.wb_cloudy_rounded;
      default:
        return Icons.nights_stay_rounded;
    }
  }

  Color _repeatColor(RepeatType type) {
    const palette = [
      _kPrimaryBlue,
      _kPrimaryTeal,
      Color(0xFFEF9F27),
    ];
    final index = RepeatType.values.indexOf(type);
    return palette[index % palette.length];
  }

  Map<String, List<MedicineReminder>> _groupByPeriod(List<MedicineReminder> reminders) {
    final sorted = List<MedicineReminder>.from(reminders)
      ..sort((a, b) {
        final aMinutes = a.time.hour * 60 + a.time.minute;
        final bMinutes = b.time.hour * 60 + b.time.minute;
        return aMinutes.compareTo(bMinutes);
      });
    final grouped = <String, List<MedicineReminder>>{};
    for (final period in _periods) {
      final items = sorted.where((r) => _periodOf(r.time) == period).toList();
      if (items.isNotEmpty) grouped[period] = items;
    }
    return grouped;
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: _kPrimaryBlue,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Medicine Reminders',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white),
              ),
              background: Container(decoration: const BoxDecoration(gradient: _kGradient)),
            ),
          ),
        ],
        body: StreamBuilder<List<MedicineReminder>>(
          stream: _repository.remindersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _kPrimaryTeal));
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 12),
                      Text('Could not load reminders', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              );
            }

            final reminders = snapshot.data ?? [];
            if (reminders.isEmpty) {
              return _EmptyState(onAdd: _showAddReminderSheet);
            }

            final activeCount = reminders.where((r) => r.isActive).length;
            final grouped = _groupByPeriod(reminders);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _SummaryHeader(total: reminders.length, active: activeCount),
                ),
                for (final period in grouped.keys) ...[
                  SliverToBoxAdapter(
                    child: _PeriodHeader(
                      label: period,
                      icon: _periodIcon(period),
                      count: grouped[period]!.length,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final reminder = grouped[period]![index];
                          return _ReminderCard(
                            reminder: reminder,
                            accentColor: _repeatColor(reminder.repeatType),
                            onEdit: () => _showEditReminderSheet(reminder),
                            onDelete: () => _deleteReminder(reminder),
                            onToggle: (val) => _repository.toggleReminder(reminder.id, val),
                          );
                        },
                        childCount: grouped[period]!.length,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: _kGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: _kPrimaryTeal.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showAddReminderSheet,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Add Reminder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Summary header — total / active count chips
// ══════════════════════════════════════════════════════════════════════════
class _SummaryHeader extends StatelessWidget {
  final int total;
  final int active;
  const _SummaryHeader({required this.total, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(child: _statChip(theme, Icons.medication_rounded, '$total', 'Total')),
          const SizedBox(width: 12),
          Expanded(child: _statChip(theme, Icons.notifications_active_rounded, '$active', 'Active')),
        ],
      ),
    );
  }

  Widget _statChip(ThemeData theme, IconData icon, String value, String label) {
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: _kGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: onSurface)),
              Text(label, style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.6))),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Period section header (Morning / Afternoon / Evening / Night)
// ══════════════════════════════════════════════════════════════════════════
class _PeriodHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  const _PeriodHeader({required this.label, required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _kPrimaryTeal),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: onSurface),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _kPrimaryTeal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count', style: const TextStyle(fontSize: 11, color: _kPrimaryTeal, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Reminder card
// ══════════════════════════════════════════════════════════════════════════
class _ReminderCard extends StatelessWidget {
  final MedicineReminder reminder;
  final Color accentColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _ReminderCard({
    required this.reminder,
    required this.accentColor,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isActive = reminder.isActive;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isActive ? accentColor.withOpacity(0.15) : onSurface.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication_outlined,
                    color: isActive ? accentColor : onSurface.withOpacity(0.4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.medicineName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isActive ? onSurface : onSurface.withOpacity(0.4),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            reminder.dosage,
                            style: TextStyle(fontSize: 12.5, color: onSurface.withOpacity(0.6)),
                          ),
                          Text('•', style: TextStyle(color: onSurface.withOpacity(0.3))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              reminder.scheduleText,
                              style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      reminder.timeFormatted,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isActive ? _kPrimaryTeal : onSurface.withOpacity(0.4),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isActive,
                        activeColor: _kPrimaryTeal,
                        onChanged: onToggle,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: onSurface.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 18, color: _kPrimaryTeal),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400),
                        const SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: Colors.red.shade400)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Empty state
// ══════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kPrimaryTeal.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication_liquid_rounded, size: 48, color: _kPrimaryTeal),
            ),
            const SizedBox(height: 20),
            Text(
              'No reminders yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your first medicine reminder to\nnever miss a dose.',
              textAlign: TextAlign.center,
              style: TextStyle(color: onSurface.withOpacity(0.6), height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(gradient: _kGradient, borderRadius: BorderRadius.circular(12)),
              child: ElevatedButton.icon(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Add Reminder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Add / Edit bottom sheet
// ══════════════════════════════════════════════════════════════════════════
class _ReminderSheet extends StatefulWidget {
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
  ) onSave;

  const _ReminderSheet({
    required this.title,
    required this.initialName,
    required this.initialDosage,
    required this.initialTime,
    required this.initialRepeatType,
    required this.initialWeekDays,
    required this.onSave,
  });

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dosageCtrl;
  late TimeOfDay _time;
  late RepeatType _repeatType;
  late List<int> _weekDays;
  bool _saving = false;

  static const _dayLabels = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: _kPrimaryTeal),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _handleSave(bool showDayPicker) async {
    if (_nameCtrl.text.trim().isEmpty || _dosageCtrl.text.trim().isEmpty) {
      _showError('Please fill all fields');
      return;
    }
    if (showDayPicker && _weekDays.isEmpty) {
      _showError('Please select at least one day');
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
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final fieldFill = theme.colorScheme.surfaceVariant.withOpacity(theme.brightness == Brightness.dark ? 0.5 : 1);
    final showDayPicker = _repeatType == RepeatType.weekly || _repeatType == RepeatType.custom;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                widget.title,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: onSurface),
              ),
              const SizedBox(height: 20),
              _label(context, 'Medicine Name'),
              TextField(
                controller: _nameCtrl,
                style: TextStyle(color: onSurface),
                decoration: _inputDecoration(context, hint: 'e.g., Aspirin', icon: Icons.medication_outlined, fill: fieldFill),
              ),
              const SizedBox(height: 16),
              _label(context, 'Dosage'),
              TextField(
                controller: _dosageCtrl,
                style: TextStyle(color: onSurface),
                decoration: _inputDecoration(context, hint: 'e.g., 500mg', icon: Icons.science_outlined, fill: fieldFill),
              ),
              const SizedBox(height: 16),
              _label(context, 'Time'),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: fieldFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: _kPrimaryTeal),
                      const SizedBox(width: 10),
                      Text(_time.format(context), style: TextStyle(fontWeight: FontWeight.w600, color: onSurface)),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded, color: onSurface.withOpacity(0.4)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _label(context, 'Repeat'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RepeatType.values.map((type) {
                  final selected = _repeatType == type;
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _repeatType = type),
                    selectedColor: _kPrimaryTeal,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: fieldFill,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: selected ? _kPrimaryTeal : theme.dividerColor),
                    ),
                  );
                }).toList(),
              ),
              if (showDayPicker) ...[
                const SizedBox(height: 16),
                _label(context, 'Select Days'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (i) {
                    final day = i + 1;
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
                      selectedColor: _kPrimaryBlue.withOpacity(0.2),
                      checkmarkColor: _kPrimaryBlue,
                      labelStyle: TextStyle(
                        color: selected ? _kPrimaryBlue : onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: fieldFill,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: selected ? _kPrimaryBlue : theme.dividerColor),
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(gradient: _kGradient, borderRadius: BorderRadius.circular(14)),
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _handleSave(showDayPicker),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Reminder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      );

  InputDecoration _inputDecoration(BuildContext context, {required String hint, required IconData icon, required Color fill}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
      prefixIcon: Icon(icon, size: 20, color: onSurface.withOpacity(0.5)),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kPrimaryTeal, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    );
  }
}