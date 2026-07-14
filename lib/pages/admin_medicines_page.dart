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
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
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

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final medicine = medicines[index];
                    return _MedicineTile(
                      medicine: medicine,
                      isDark: isDark,
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

class _MedicineTile extends StatelessWidget {
  final Medicine medicine;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicineTile({
    required this.medicine,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final stock = medicine.stockQuantity;
    final hasStock = stock != null;
    final isLow = hasStock && stock <= 10;
    final isCritical = hasStock && stock <= 3;

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
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: !hasStock
                        ? Colors.grey.withValues(alpha: 0.15)
                        : (isCritical ? Colors.red : (isLow ? Colors.orange : Colors.green))
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    !hasStock ? 'Stock set kora hoy nai' : 'Stock: $stock',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: !hasStock
                          ? Colors.grey[600]
                          : (isCritical
                              ? Colors.red[700]
                              : (isLow ? Colors.orange[700] : Colors.green[700])),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: _Brand.start,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: Colors.red[400],
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}