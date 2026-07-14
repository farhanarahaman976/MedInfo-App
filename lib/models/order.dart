import 'package:cloud_firestore/cloud_firestore.dart';
import 'medicine.dart';

// ─── OrderItem ───────────────────────────────────────────────────────────────

class OrderItem {
  final String name;
  final String category;
  final double unitPrice;
  final int quantity;

  const OrderItem({
    required this.name,
    required this.category,
    required this.unitPrice,
    this.quantity = 1,
  });

  double get subtotal => unitPrice * quantity;

  factory OrderItem.fromMedicine(Medicine medicine, {int quantity = 1}) {
    return OrderItem(
      name: medicine.name,
      category: medicine.category,
      unitPrice: medicine.displayPrice,
      quantity: quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'unitPrice': unitPrice,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

// ─── OrderStatus ─────────────────────────────────────────────────────────────

enum OrderStatus { pending, confirmed, shipped, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String? value) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

// ─── MedicineOrder ───────────────────────────────────────────────────────────

class MedicineOrder {
  final String id;
  final String userId;
  final String userName;
  final List<OrderItem> items;
  final double totalAmount;
  final String deliveryAddress;
  final String phone;
  final String paymentMethod;
  final OrderStatus status;
  final DateTime createdAt;

  const MedicineOrder({
    this.id = '',
    required this.userId,
    required this.userName,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.phone,
    required this.paymentMethod,
    this.status = OrderStatus.pending,
    required this.createdAt,
  });

  int get totalItemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  /// Firestore-এ পাঠানোর জন্য (createdAt স্বয়ংক্রিয়ভাবে server timestamp হয়)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress,
      'phone': phone,
      'paymentMethod': paymentMethod,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory MedicineOrder.fromMap(String id, Map<String, dynamic> map) {
    return MedicineOrder(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: map['deliveryAddress'] ?? '',
      phone: map['phone'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'Cash on Delivery',
      status: OrderStatusX.fromString(map['status'] as String?),
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}