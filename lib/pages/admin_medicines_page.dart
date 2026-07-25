import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../services/medicine_service.dart';
import 'medicine_form_page.dart';

class _Brand {
  static const Color start = Color(0xFF3B82C4);
  static const Color end = Color(0xFF0F6E56);
}

class AdminMedicinesPage extends StatefulWidget {
  const AdminMedicinesPage({super.key});

  @override
  State<AdminMedicinesPage> createState() => _AdminMedicinesPageState();
}

class _AdminMedicinesPageState extends State<AdminMedicinesPage> {
  final MedicineService _service = MedicineService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(Medicine medicine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure? you want to delete the medicine?'),
        content: Text(
          '${medicine.name} It will be fully deleted, and you can not undo this part anymore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.deleteMedicine(medicine.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${medicine.name} It has been deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _Brand.start,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Medicine', style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MedicineFormPage(medicine: null),
            ),
          );
        },
      ),
      body: Column(
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
              decoration: InputDecoration(
                hintText: 'Search for medicine...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark ? const Color(0xFF1C1E26) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Medicine list ──
          Expanded(
            child: StreamBuilder<List<Medicine>>(
              stream: _service.getAllMedicines(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                var medicines = snapshot.data ?? [];

                if (_query.isNotEmpty) {
                  medicines = medicines
                      .where(
                        (m) =>
                            m.name.toLowerCase().contains(_query) ||
                            m.category.toLowerCase().contains(_query) ||
                            m.company.toLowerCase().contains(_query),
                      )
                      .toList();
                }

                if (medicines.isEmpty) {
                  return Center(
                    child: Text(
                      'No medicines found.',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }

                return Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  interactive: true,
                  radius: const Radius.circular(8),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 12, 90),
                    itemCount: medicines.length,
                    itemBuilder: (context, index) {
                      final medicine = medicines[index];
                      return _MedicineTile(
                        // FIX: id-key na dile stock edit korar shomoy list rebuild
                        // hoile TextField-er local state onno item-er shathe mix
                        // hoye jete pare
                        key: ValueKey(medicine.id),
                        medicine: medicine,
                        isDark: isDark,
                        service: _service,
                        onEdit: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MedicineFormPage(medicine: medicine),
                            ),
                          );
                        },
                        onDelete: () => _confirmDelete(medicine),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Medicine Tile ────────────────────────────────────────────────────────

class _MedicineTile extends StatefulWidget {
  final Medicine medicine;
  final bool isDark;
  final MedicineService service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicineTile({
    super.key,
    required this.medicine,
    required this.isDark,
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_MedicineTile> createState() => _MedicineTileState();
}

class _MedicineTileState extends State<_MedicineTile> {
  late TextEditingController _stockController;
  bool _isSaving = false;

  int get _currentStock => widget.medicine.stockQuantity ?? 0;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(text: '$_currentStock');
  }

  @override
  void didUpdateWidget(covariant _MedicineTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Firestore theke live update ashle (jemon onno kono admin device theke
    // stock change hole) text field ta shathe shathe sync hobe, jodi user
    // ekhon nijei type na kore thake
    final incomingStock = widget.medicine.stockQuantity ?? 0;
    final displayedStock = int.tryParse(_stockController.text.trim());
    if (displayedStock != incomingStock && !_stockController.selection.isValid) {
      _stockController.text = '$incomingStock';
    }
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _saveStock(int newStock) async {
    final clamped = newStock < 0 ? 0 : newStock;
    setState(() => _isSaving = true);
    try {
      await widget.service.updateStock(widget.medicine.id, clamped);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock update korte parlam na: $e')),
        );
        // Firestore stream theke abar purono value fire ashbe, tai text
        // field ta ekhon-i revert kore dei
        _stockController.text = '$_currentStock';
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _adjust(int delta) {
    final current = int.tryParse(_stockController.text.trim()) ?? _currentStock;
    final updated = current + delta;
    _stockController.text = '${updated < 0 ? 0 : updated}';
    _saveStock(updated);
  }

  void _onSubmittedTyped(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      _stockController.text = '$_currentStock';
      return;
    }
    _saveStock(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final medicine = widget.medicine;

    final stock = int.tryParse(_stockController.text.trim()) ?? _currentStock;
    final isLow = stock <= 10;
    final isCritical = stock <= 3;

    final statusColor = isCritical ? Colors.red : (isLow ? Colors.orange : Colors.green);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1E26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.1),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_Brand.start, _Brand.end],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medication_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F1117),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${medicine.category} • ৳${medicine.displayPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                // ── NOTUN: inline stock stepper — form khulte hobe na ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StepperIconButton(
                        icon: Icons.remove,
                        color: statusColor,
                        onTap: _isSaving ? null : () => _adjust(-1),
                      ),
                      SizedBox(
                        width: 40,
                        child: TextField(
                          controller: _stockController,
                          enabled: !_isSaving,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isCritical
                                ? Colors.red[700]
                                : (isLow ? Colors.orange[700] : Colors.green[700]),
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            border: InputBorder.none,
                          ),
                          onSubmitted: _onSubmittedTyped,
                          onTapOutside: (_) =>
                              _onSubmittedTyped(_stockController.text),
                        ),
                      ),
                      _StepperIconButton(
                        icon: Icons.add,
                        color: statusColor,
                        onTap: _isSaving ? null : () => _adjust(1),
                      ),
                      if (_isSaving) ...[
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: _Brand.start,
            onPressed: widget.onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: Colors.red[400],
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}

class _StepperIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StepperIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}