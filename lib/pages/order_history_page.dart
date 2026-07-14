import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../app_shell.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'order_details_page.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = Get.find<AppController>();
    final OrderService orderService = OrderService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userId = controller.currentUser.value?.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: userId == null || userId.isEmpty
          ? _emptyState(
              icon: Icons.login_rounded,
              title: 'Login করো',
              subtitle: 'Order history দেখার জন্য login করতে হবে।',
            )
          : StreamBuilder<List<MedicineOrder>>(
              stream: orderService.getUserOrders(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _emptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'কিছু সমস্যা হয়েছে',
                    subtitle: '${snapshot.error}',
                  );
                }

                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return _emptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'কোনো Order নেই',
                    subtitle: 'তুমি এখনো কোনো medicine order করো নি।',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _OrderCard(order: order, isDark: isDark);
                  },
                );
              },
            ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Order Card ──────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final MedicineOrder order;
  final bool isDark;

  const _OrderCard({required this.order, required this.isDark});

  static const Color _primary = Color(0xFF1A56DB);

  Color _statusColor() {
    switch (order.status) {
      case OrderStatus.pending:
        return const Color(0xFF854F0B);
      case OrderStatus.confirmed:
        return const Color(0xFF1A56DB);
      case OrderStatus.shipped:
        return const Color(0xFF534AB7);
      case OrderStatus.delivered:
        return const Color(0xFF0F6E56);
      case OrderStatus.cancelled:
        return const Color(0xFFA32D2D);
    }
  }

  Color _statusBg() {
    switch (order.status) {
      case OrderStatus.pending:
        return const Color(0xFFFAEEDA);
      case OrderStatus.confirmed:
        return const Color(0xFFEEF2FF);
      case OrderStatus.shipped:
        return const Color(0xFFEEEDFE);
      case OrderStatus.delivered:
        return const Color(0xFFE1F5EE);
      case OrderStatus.cancelled:
        return const Color(0xFFFCEBEB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt);
    final shortId = order.id.length > 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailsPage(order: order)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1E26) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.12),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #$shortId',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F1117),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              dateStr,
              style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.totalItemCount} item${order.totalItemCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  '৳${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _primary,
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
