import 'package:equatable/equatable.dart';
import 'cart_item.dart';

/// Enum representing the possible states of an order
enum OrderStatus {
  pending,
  processing,
  completed,
  cancelled,
  refunded
}

/// Entity class representing a shop order
class ShopOrder extends Equatable {
  final String id;
  final String userId;
  final String orderNumber;
  final List<CartItem> items;
  final double total;
  final OrderStatus status;
  final String paymentMethod;
  final String shippingAddress;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShopOrder({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.items,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this order with some fields replaced
  ShopOrder copyWith({
    String? id,
    String? userId,
    String? orderNumber,
    List<CartItem>? items,
    double? total,
    OrderStatus? status,
    String? paymentMethod,
    String? shippingAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShopOrder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert order to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'orderNumber': orderNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod,
      'shippingAddress': shippingAddress,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create an order from a map
  factory ShopOrder.fromMap(Map<String, dynamic> map) {
    return ShopOrder(
      id: map['id'] as String,
      userId: map['userId'] as String,
      orderNumber: map['orderNumber'] as String,
      items: (map['items'] as List<dynamic>)
          .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      total: (map['total'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: map['paymentMethod'] as String,
      shippingAddress: map['shippingAddress'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopOrder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  List<Object?> get props => [
        id,
        userId,
        orderNumber,
        items,
        total,
        status,
        paymentMethod,
        shippingAddress,
        createdAt,
        updatedAt,
      ];
} 