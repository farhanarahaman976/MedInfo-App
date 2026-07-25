import 'package:flutter/material.dart';
import '../models/health_tip.dart';
import '../services/health_tip_service.dart';

class AdminHealthTipsPage extends StatefulWidget {
  const AdminHealthTipsPage({super.key});

  @override
  State<AdminHealthTipsPage> createState() => _AdminHealthTipsPageState();
}

class _AdminHealthTipsPageState extends State<AdminHealthTipsPage> {
  final HealthTipService _service = HealthTipService();

  static const Color _brandStart = Color(0xFF3B82C4);
  static const Color _brandEnd = Color(0xFF0F6E56);

  void _openTipForm({HealthTip? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final titleBanglaController =
        TextEditingController(text: existing?.titleBangla ?? '');
    final bodyController = TextEditingController(text: existing?.body ?? '');
    final bodyBanglaController =
        TextEditingController(text: existing?.bodyBangla ?? '');
    final orderController =
        TextEditingController(text: (existing?.order ?? 0).toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'Add Health Tip' : 'Edit Health Tip',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title (English)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleBanglaController,
                  decoration: const InputDecoration(
                    labelText: 'Title (Bangla)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Body (English)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyBanglaController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Body (Bangla)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Display order (lower shows first)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandEnd,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final tip = HealthTip(
                        title: titleController.text.trim(),
                        titleBangla: titleBanglaController.text.trim(),
                        body: bodyController.text.trim(),
                        bodyBangla: bodyBanglaController.text.trim(),
                        order: int.tryParse(orderController.text.trim()) ?? 0,
                      );

                      if (tip.title.isEmpty && tip.titleBangla.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Title is required.')),
                        );
                        return;
                      }

                      if (existing == null) {
                        await _service.addTip(tip);
                      } else {
                        await _service.updateTip(existing.id, tip);
                      }

                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    child: Text(existing == null ? 'Add Tip' : 'Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(HealthTip tip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Health Tip'),
        content: Text('Delete "${tip.title.isNotEmpty ? tip.title : tip.titleBangla}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.deleteTip(tip.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTipForm(),
        backgroundColor: _brandStart,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Tip', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<HealthTip>>(
        stream: _service.getAllTips(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tips = snapshot.data!;
          if (tips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tips_and_updates_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No health tips yet. Tap "Add Tip" to create one.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1E26) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _brandStart.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${tip.order}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _brandStart),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip.title.isNotEmpty ? tip.title : tip.titleBangla,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F1117),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tip.body.isNotEmpty ? tip.body : tip.bodyBangla,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: _brandStart,
                      onPressed: () => _openTipForm(existing: tip),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red.shade400,
                      onPressed: () => _confirmDelete(tip),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}