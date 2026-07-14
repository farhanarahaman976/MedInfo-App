import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';
import '../services/order_service.dart';

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final OrderService orderService = OrderService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Admin · All Orders',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<MedicineOrder>>(
        stream: orderService.getAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 56,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'কোনো Order নেই',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _AdminOrderCard(
                order: orders[index],
                isDark: isDark,
                orderService: orderService,
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Admin Order Card ────────────────────────────────────────────────────────

class _AdminOrderCard extends StatefulWidget {
  final MedicineOrder order;
  final bool isDark;
  final OrderService orderService;

  const _AdminOrderCard({
    required this.order,
    required this.isDark,
    required this.orderService,
  });

  @override
  State<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<_AdminOrderCard> {
  static const Color _primary = Color(0xFF1A56DB);
  bool _isUpdating = false;

  Color _statusColor(OrderStatus status) {
    switch (status) {
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

  Color _statusBg(OrderStatus status) {
    switch (status) {
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

  Future<void> _updateStatus(OrderStatus newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await widget.orderService.updateOrderStatus(widget.order.id, newStatus);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDark = widget.isDark;
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt);
    final shortId = order.id.length > 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Order #$shortId',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F1117),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusBg(order.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(order.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Customer info
          _infoRow(Icons.person_outline, order.userName, isDark),
          const SizedBox(height: 6),
          _infoRow(Icons.phone_outlined, order.phone, isDark),
          const SizedBox(height: 6),
          _infoRow(Icons.location_on_outlined, order.deliveryAddress, isDark),
          const SizedBox(height: 6),
          _infoRow(Icons.payment_outlined, order.paymentMethod, isDark),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Items
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} x${item.quantity}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                  Text(
                    '৳${item.subtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F1117),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F1117),
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

          const SizedBox(height: 12),

          // Status update dropdown
          if (order.status == OrderStatus.cancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFCEBEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Order Cancelled by user',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFA32D2D),
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<OrderStatus>(
                        value: order.status,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                        ),
                        items: OrderStatus.values
                            .where((s) => s != OrderStatus.cancelled)
                            .map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(
                                  status.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F1117),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                        onChanged: _isUpdating
                            ? null
                            : (value) {
                                if (value != null) _updateStatus(value);
                              },
                      ),
                    ),
                  ),
                ),
                if (_isUpdating) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: _primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
