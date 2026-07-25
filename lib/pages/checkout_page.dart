import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/medicine.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../models/app_notification.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';
import '../services/notification_history_service.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<Medicine> cartItems;
  final User? user;
  final VoidCallback onOrderPlaced;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.user,
    required this.onOrderPlaced,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const Color _primary = Color(0xFF1A56DB);

  // Delivery charge config (simple zone-based: Khulna vs everywhere else)
  static const double _khulnaCharge = 70;
  static const double _otherCharge = 120;

  final _formKey = GlobalKey<FormState>();
  final OrderService _orderService = OrderService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  String _paymentMethod = 'Cash on Delivery';
  bool _isPlacing = false;

  double get _subtotal =>
      widget.cartItems.fold(0, (sum, item) => sum + (item.displayPrice * item.quantity));

  // Detects Khulna from the typed address; defaults to the higher "other" charge
  double get _deliveryCharge {
    final address = _addressController.text.toLowerCase();
    if (address.contains('khulna')) {
      return _khulnaCharge;
    }
    return _otherCharge;
  }

  bool get _isKhulna => _addressController.text.toLowerCase().contains('khulna');

  double get _grandTotal => _subtotal + _deliveryCharge;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _addressController = TextEditingController(
      text: widget.user?.address ?? '',
    );
    // Recalculate delivery charge live as the user types their address
    _addressController.addListener(_onAddressChanged);
  }

  void _onAddressChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final user = widget.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to place an order.')),
      );
      return;
    }

    setState(() => _isPlacing = true);

    try {
      final order = MedicineOrder(
        userId: user.uid,
        userName: _nameController.text.trim(),
        items: widget.cartItems
            .map((m) => OrderItem.fromMedicine(m, quantity: m.quantity))
            .toList(),
        totalAmount: _grandTotal,
        deliveryAddress: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        paymentMethod: _paymentMethod,
        createdAt: DateTime.now(),
      );

      final orderId = await _orderService.placeOrder(order);

      // Notification history-te entry add — bell icon e dekha jabe
      await NotificationHistoryService().addNotification(
        userId: user.uid,
        title: 'Order placed successfully',
        body:
            'Your order of ৳${_grandTotal.toStringAsFixed(0)} has been placed.',
        type: AppNotificationType.order,
        referenceId: orderId,
      );

      // Show order notification and schedule a follow-up update
      await NotificationService().notifyOrderSubmitted(
        orderId: orderId,
        title: 'Order placed',
        body: 'Your order has been placed successfully.',
        followUpDelayMinutes: 60,
        followUpTitle: 'Order update',
        followUpBody: 'Your order is being processed.',
      );

      widget.onOrderPlaced(); // cart clear

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OrderSuccessPage(orderId: orderId, totalAmount: _grandTotal),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order place korte parlam na: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Delivery Details', isDark),
            const SizedBox(height: 10),
            _buildField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              isDark: isDark,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name দিন' : null,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              isDark: isDark,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Phone number দিন' : null,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _addressController,
              label: 'Delivery Address',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              isDark: isDark,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Address দিন' : null,
            ),
            const SizedBox(height: 8),
            // Live delivery zone indicator
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 15,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  _isKhulna
                      ? 'Khulna zone · Delivery charge ৳${_khulnaCharge.toStringAsFixed(0)}'
                      : 'Outside Khulna · Delivery charge ৳${_otherCharge.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _sectionTitle('Payment Method', isDark),
            const SizedBox(height: 10),
            _buildPaymentOption(
              'Cash on Delivery',
              Icons.local_shipping_outlined,
              isDark,
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              'bKash / Mobile Banking',
              Icons.smartphone_outlined,
              isDark,
              comingSoon: true,
            ),

            const SizedBox(height: 24),
            _sectionTitle('Order Summary', isDark),
            const SizedBox(height: 10),
            Container(
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
                children: [
                  ...widget.cartItems.map(
                    (m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${m.name} ×${m.quantity}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F1117),
                              ),
                            ),
                          ),
                          Text(
                            '৳${(m.displayPrice * m.quantity).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F1117),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  // Subtotal row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                        Text(
                          '৳${_subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Delivery charge row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery Charge',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                        Text(
                          '৳${_deliveryCharge.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total (${widget.cartItems.length} item${widget.cartItems.length != 1 ? 's' : ''})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F1117),
                        ),
                      ),
                      Text(
                        '৳${_grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).viewPadding.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1E26) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isPlacing ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isPlacing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    'Place Order · ৳${_grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF0F1117),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final fillColor = isDark ? const Color(0xFF1C1E26) : const Color(0xFFF8F9FC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F1117);
    final labelColor = isDark ? Colors.white60 : Colors.grey[600];
    final iconColor = isDark ? Colors.white70 : Colors.grey[600];
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.grey.withValues(alpha: 0.15);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: textColor),
      cursorColor: _primary,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor),
        prefixIcon: Icon(icon, size: 20, color: iconColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPaymentOption(
    String label,
    IconData icon,
    bool isDark, {
    bool comingSoon = false,
  }) {
    final isSelected = _paymentMethod == label;

    return GestureDetector(
      onTap: comingSoon
          ? () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
            }
          : () => setState(() => _paymentMethod = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1E26) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? _primary
                : isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.12),
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: comingSoon
                  ? Colors.grey
                  : (isSelected
                        ? _primary
                        : isDark
                        ? Colors.white70
                        : const Color(0xFF0F1117)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: comingSoon
                      ? Colors.grey
                      : (isDark ? Colors.white : const Color(0xFF0F1117)),
                ),
              ),
            ),
            if (comingSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Soon',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              )
            else if (isSelected)
              const Icon(Icons.check_circle_rounded, size: 20, color: _primary),
          ],
        ),
      ),
    );
  }
}