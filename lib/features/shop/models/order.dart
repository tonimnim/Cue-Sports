import 'cart_item.dart';

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
  completed,
}

class Order {
  final String id;
  final String userId;
  final String orderNumber;
  final List<CartItemModel> items;
  final double total;
  final OrderStatus status;
  final String paymentMethod;
  final String? paymentId;
  final String shippingAddress;
  final String? notes;
  final String? receiptNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.items,
    required this.total,
    required this.status,
    required this.paymentMethod,
    this.paymentId,
    required this.shippingAddress,
    this.notes,
    this.receiptNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'orderNumber': orderNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'shippingAddress': shippingAddress,
      'notes': notes,
      'receiptNumber': receiptNumber,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, String documentId) {
    return Order(
      id: documentId,
      userId: map['userId'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      items: [], // Will be populated separately
      total: (map['total'] ?? 0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: map['paymentMethod'] ?? '',
      paymentId: map['paymentId'],
      shippingAddress: map['shippingAddress'] ?? '',
      notes: map['notes'],
      receiptNumber: map['receiptNumber'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as dynamic).toDate() 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as dynamic).toDate() 
          : DateTime.now(),
    );
  }

  Order copyWith({
    String? id,
    String? userId,
    String? orderNumber,
    List<CartItemModel>? items,
    double? total,
    OrderStatus? status,
    String? paymentMethod,
    String? paymentId,
    String? shippingAddress,
    String? notes,
    String? receiptNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      notes: notes ?? this.notes,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
