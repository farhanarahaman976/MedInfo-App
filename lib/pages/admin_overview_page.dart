import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/order.dart';

// ── Brand colors — app-er logo gradient-er sathe match kore ──
class _Brand {
  static const Color start = Color(0xFF3B82C4);
  static const Color end = Color(0xFF0F6E56);
}

class _OverviewStats {
  final int totalOrders;
  final double totalRevenue;
  final int totalUsers;
  final int todaysOrders;
  final List<Medicine> lowStockMedicines;

  const _OverviewStats({
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalUsers,
    required this.todaysOrders,
    required this.lowStockMedicines,
  });
}

class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  // Ei quantity-er niche hole "low stock" hisebe dhora hobe
  static const int lowStockThreshold = 10;

  late Future<_OverviewStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<void> _refresh() async {
    setState(() {
      _statsFuture = _loadStats();
    });
    await _statsFuture;
  }

  Future<_OverviewStats> _loadStats() async {
    final firestore = FirebaseFirestore.instance;

    final ordersSnapshot = await firestore.collection('orders').get();
    final usersSnapshot = await firestore.collection('users').get();
    final medicinesSnapshot = await firestore.collection('medicines').get();

    final orders = ordersSnapshot.docs
        .map((doc) => MedicineOrder.fromMap(doc.id, doc.data()))
        .toList();

    final medicines = medicinesSnapshot.docs
        .map((doc) => Medicine.fromMap(doc.data(), doc.id))
        .toList();

    double totalRevenue = 0;
    int todaysOrders = 0;
    final now = DateTime.now();

    for (final order in orders) {
      // FIX: cancelled order revenue-e dhora hocche na
      if (order.status != OrderStatus.cancelled) {
        totalRevenue += order.totalAmount;
      }
      if (order.createdAt.year == now.year &&
          order.createdAt.month == now.month &&
          order.createdAt.day == now.day) {
        todaysOrders++;
      }
    }
final lowStock = medicines
        .where(
          (m) => m.stockQuantity != null && m.stockQuantity! <= lowStockThreshold,
        )
        .toList()
      ..sort((a, b) => a.stockQuantity!.compareTo(b.stockQuantity!));

    return _OverviewStats(
      totalOrders: orders.length,
      totalRevenue: totalRevenue,
      totalUsers: usersSnapshot.docs.length,
      todaysOrders: todaysOrders,
      lowStockMedicines: lowStock,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: _Brand.start,
      onRefresh: _refresh,
      child: FutureBuilder<_OverviewStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Stats load korte somossa hocche.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ),
              ],
            );
          }

          final stats = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Stats grid (2x2) ──
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  _StatCard(
                    icon: Icons.receipt_long_rounded,
                    label: 'Total Orders',
                    value: '${stats.totalOrders}',
                    isDark: isDark,
                  ),
                  _StatCard(
                    icon: Icons.payments_rounded,
                    label: 'Total Revenue',
                    value: '৳${stats.totalRevenue.toStringAsFixed(0)}',
                    isDark: isDark,
                  ),
                  _StatCard(
                    icon: Icons.people_alt_rounded,
                    label: 'Total Users',
                    value: '${stats.totalUsers}',
                    isDark: isDark,
                  ),
                  _StatCard(
                    icon: Icons.today_rounded,
                    label: "Today's Orders",
                    value: '${stats.todaysOrders}',
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Low stock alert ──
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Low Stock Alert',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F1117),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (stats.lowStockMedicines.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${stats.lowStockMedicines.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (stats.lowStockMedicines.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1E26) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.grey.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green[600],
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'All medicines are in stock 👍',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...stats.lowStockMedicines.map(
                  (m) => _LowStockTile(medicine: m, isDark: isDark),
                ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1E26) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.1),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_Brand.start, _Brand.end],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: Colors.white),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F1117),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Low Stock Tile ─────────────────────────────────────────────────────────

class _LowStockTile extends StatelessWidget {
  final Medicine medicine;
  final bool isDark;

  const _LowStockTile({required this.medicine, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isCritical = medicine.stockQuantity! <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1E26) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isCritical ? Colors.red : Colors.orange).withValues(
            alpha: 0.25,
          ),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.medication_rounded,
            color: isCritical ? Colors.red[400] : Colors.orange[600],
            size: 20,
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
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F1117),
                  ),
                ),
                Text(
                  medicine.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (isCritical ? Colors.red : Colors.orange).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${medicine.stockQuantity} left',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isCritical ? Colors.red[700] : Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}