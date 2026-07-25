import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/medicine.dart';
import '../models/order.dart';
import 'admin_tab_controller.dart';

// Brand colors - match the app logo gradient
class _Brand {
  static const Color start = Color(0xFF3B82C4);
  static const Color end = Color(0xFF0F6E56);
}

enum _SalesPeriod { daily, weekly, monthly }

class _ChartPoint {
  final String label;
  final double value;
  const _ChartPoint(this.label, this.value);
}

class _BestSeller {
  final String name;
  final int quantity;
  const _BestSeller(this.name, this.quantity);
}

class _OverviewStats {
  final int totalOrders;
  final double totalRevenue;
  final int totalUsers;
  final int todaysOrders;
  final List<Medicine> lowStockMedicines;

  final List<_ChartPoint> salesDaily;
  final List<_ChartPoint> salesWeekly;
  final List<_ChartPoint> salesMonthly;
  final List<_BestSeller> bestSellers;
  final List<_ChartPoint> userGrowth;

  const _OverviewStats({
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalUsers,
    required this.todaysOrders,
    required this.lowStockMedicines,
    required this.salesDaily,
    required this.salesWeekly,
    required this.salesMonthly,
    required this.bestSellers,
    required this.userGrowth,
  });
}

class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  static const int lowStockThreshold = 10;

  static const List<String> _monthShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  late Future<_OverviewStats> _statsFuture;
  _SalesPeriod _salesPeriod = _SalesPeriod.daily;

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

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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

    final validOrders =
        orders.where((o) => o.status != OrderStatus.cancelled).toList();

    for (final order in orders) {
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

    final salesDaily = <_ChartPoint>[];
    for (int i = 6; i >= 0; i--) {
      final day = _dateOnly(now.subtract(Duration(days: i)));
      final sum = validOrders
          .where((o) => _dateOnly(o.createdAt) == day)
          .fold(0.0, (s, o) => s + o.totalAmount);
      salesDaily.add(_ChartPoint('${day.day}/${day.month}', sum));
    }

    final salesWeekly = <_ChartPoint>[];
    final thisMonday = _dateOnly(now.subtract(Duration(days: now.weekday - 1)));
    for (int i = 7; i >= 0; i--) {
      final weekStart = thisMonday.subtract(Duration(days: i * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final sum = validOrders
          .where(
            (o) =>
                !o.createdAt.isBefore(weekStart) &&
                o.createdAt.isBefore(weekEnd),
          )
          .fold(0.0, (s, o) => s + o.totalAmount);
      salesWeekly.add(_ChartPoint('${weekStart.day}/${weekStart.month}', sum));
    }

    final salesMonthly = <_ChartPoint>[];
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final sum = validOrders
          .where(
            (o) =>
                o.createdAt.year == monthDate.year &&
                o.createdAt.month == monthDate.month,
          )
          .fold(0.0, (s, o) => s + o.totalAmount);
      salesMonthly.add(_ChartPoint(_monthShort[monthDate.month - 1], sum));
    }

    final qtyMap = <String, int>{};
    for (final order in validOrders) {
      for (final item in order.items) {
        qtyMap[item.name] = (qtyMap[item.name] ?? 0) + item.quantity;
      }
    }
    final bestSellersList = qtyMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final bestSellers = bestSellersList
        .take(5)
        .map((e) => _BestSeller(e.key, e.value))
        .toList();

    final userDates = <DateTime>[];
    for (final doc in usersSnapshot.docs) {
      final ts = doc.data()['createdAt'];
      if (ts is Timestamp) userDates.add(ts.toDate());
    }
    final userGrowth = <_ChartPoint>[];
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final count = userDates
          .where(
            (d) => d.year == monthDate.year && d.month == monthDate.month,
          )
          .length;
      userGrowth.add(
        _ChartPoint(_monthShort[monthDate.month - 1], count.toDouble()),
      );
    }

    return _OverviewStats(
      totalOrders: orders.length,
      totalRevenue: totalRevenue,
      totalUsers: usersSnapshot.docs.length,
      todaysOrders: todaysOrders,
      lowStockMedicines: lowStock,
      salesDaily: salesDaily,
      salesWeekly: salesWeekly,
      salesMonthly: salesMonthly,
      bestSellers: bestSellers,
      userGrowth: userGrowth,
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
                    'There is a problem loading the stats.\n${snapshot.error}',
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
                    onTap: () => Get.find<AdminTabController>().goToTab(1),
                  ),
                  _StatCard(
                    icon: Icons.payments_rounded,
                    label: 'Total Revenue',
                    value: '\u09f3${stats.totalRevenue.toStringAsFixed(0)}',
                    isDark: isDark,
                    onTap: () => Get.find<AdminTabController>().goToTab(1),
                  ),
                  _StatCard(
                    icon: Icons.people_alt_rounded,
                    label: 'Total Users',
                    value: '${stats.totalUsers}',
                    isDark: isDark,
                    onTap: () => Get.find<AdminTabController>().goToTab(3),
                  ),
                  _StatCard(
                    icon: Icons.today_rounded,
                    label: "Today's Orders",
                    value: '${stats.todaysOrders}',
                    isDark: isDark,
                    onTap: () => Get.find<AdminTabController>().goToTab(1),
                  ),
                ],
              ),

              const SizedBox(height: 24),

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
                        'All medicines are in stock \ud83d\udc4d',
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

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.show_chart_rounded,
                        size: 20,
                        color: _Brand.start,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sales Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F1117),
                        ),
                      ),
                    ],
                  ),
                  _PeriodToggle(
                    selected: _salesPeriod,
                    isDark: isDark,
                    onChanged: (p) => setState(() => _salesPeriod = p),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SalesChartCard(
                data: _salesPeriod == _SalesPeriod.daily
                    ? stats.salesDaily
                    : _salesPeriod == _SalesPeriod.weekly
                        ? stats.salesWeekly
                        : stats.salesMonthly,
                isDark: isDark,
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 20,
                    color: Colors.deepOrange[400],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Best-Selling Medicines',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F1117),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (stats.bestSellers.isEmpty)
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
                  child: Text(
                    'There is no order data yet.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
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
                  child: Column(
                    children: [
                      for (int i = 0; i < stats.bestSellers.length; i++)
                        _BestSellerTile(
                          rank: i + 1,
                          bestSeller: stats.bestSellers[i],
                          isDark: isDark,
                          maxQuantity: stats.bestSellers.first.quantity,
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    size: 20,
                    color: _Brand.end,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'User Growth (last 6 months)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F1117),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _UserGrowthChartCard(data: stats.userGrowth, isDark: isDark),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final _SalesPeriod selected;
  final bool isDark;
  final ValueChanged<_SalesPeriod> onChanged;

  const _PeriodToggle({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(_SalesPeriod period, String label) {
      final isSelected = selected == period;
      return GestureDetector(
        onTap: () => onChanged(period),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: [_Brand.start, _Brand.end])
                : null,
            color: isSelected
                ? null
                : (isDark ? const Color(0xFF1C1E26) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(_SalesPeriod.daily, 'Daily'),
        const SizedBox(width: 6),
        chip(_SalesPeriod.weekly, 'Weekly'),
        const SizedBox(width: 6),
        chip(_SalesPeriod.monthly, 'Monthly'),
      ],
    );
  }
}

class _SalesChartCard extends StatelessWidget {
  final List<_ChartPoint> data;
  final bool isDark;

  const _SalesChartCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxY = data.isEmpty
        ? 100.0
        : (data.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.25)
            .clamp(10.0, double.infinity);

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
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
      child: data.every((e) => e.value == 0)
          ? Center(
              child: Text(
                'There is no sales data for this time.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            )
          : BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.withValues(alpha: 0.12),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) => Text(
                        '\u09f3${value.toInt()}',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            data[i].label,
                            style: TextStyle(
                              fontSize: 9,
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < data.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data[i].value,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [_Brand.start, _Brand.end],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}

class _UserGrowthChartCard extends StatelessWidget {
  final List<_ChartPoint> data;
  final bool isDark;

  const _UserGrowthChartCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxY = data.isEmpty
        ? 5.0
        : (data.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.3)
            .clamp(4.0, double.infinity);

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
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
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY / 4).clamp(1.0, double.infinity),
            getDrawingHorizontalLine: (v) => FlLine(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.withValues(alpha: 0.12),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (maxY / 4).clamp(1.0, double.infinity),
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      data[i].label,
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int i = 0; i < data.length; i++)
                  FlSpot(i.toDouble(), data[i].value),
              ],
              isCurved: true,
              gradient: const LinearGradient(
                colors: [_Brand.start, _Brand.end],
              ),
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    _Brand.start.withValues(alpha: 0.18),
                    _Brand.end.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BestSellerTile extends StatelessWidget {
  final int rank;
  final _BestSeller bestSeller;
  final bool isDark;
  final int maxQuantity;

  const _BestSellerTile({
    required this.rank,
    required this.bestSeller,
    required this.isDark,
    required this.maxQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final ratio =
        maxQuantity == 0 ? 0.0 : bestSeller.quantity / maxQuantity;

    Color rankColor;
    switch (rank) {
      case 1:
        rankColor = const Color(0xFFD4AF37);
        break;
      case 2:
        rankColor = const Color(0xFFA8A9AD);
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32);
        break;
      default:
        rankColor = _Brand.start;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bestSeller.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F1117),
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(rankColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${bestSeller.quantity} sold',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

// Stat card - soft gradient background (lighter, brand-tinted card look)
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      _Brand.start.withValues(alpha: 0.20),
                      _Brand.end.withValues(alpha: 0.28),
                    ]
                  : [
                      _Brand.start.withValues(alpha: 0.14),
                      _Brand.end.withValues(alpha: 0.22),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 19, color: _Brand.end),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                ],
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
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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