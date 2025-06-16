import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/shop_order.dart';
import '../../domain/entities/cart_item.dart';
import 'cart_item_model.dart';

class ShopOrderModel extends ShopOrder {
  const ShopOrderModel({
    required String id,
    required String userId,
    required String orderNumber,
    required List<CartItem> items,
    required double total,
    required OrderStatus status,
    required String paymentMethod,
    required String shippingAddress,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? transactionId,
    String? mpesaReceiptNumber,
  }) : super(
          id: id,
          userId: userId,
          orderNumber: orderNumber,
          items: items,
          total: total,
          status: status,
          paymentMethod: paymentMethod,
          shippingAddress: shippingAddress,
          createdAt: createdAt,
          updatedAt: updatedAt,
          transactionId: transactionId,
          mpesaReceiptNumber: mpesaReceiptNumber,
        );

  factory ShopOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse items from embedded data
    final List<CartItem> items = [];
    if (data['items'] != null) {
      final itemsList = data['items'] as List<dynamic>;
      for (final itemData in itemsList) {
        items.add(CartItemModel.fromMap(itemData as Map<String, dynamic>));
      }
    }
    
    return ShopOrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      orderNumber: data['orderNumber'] ?? '',
      items: items,
      total: (data['total'] ?? 0).toDouble(),
      status: _parseOrderStatus(data['status']),
      paymentMethod: data['paymentMethod'] ?? '',
      shippingAddress: data['shippingAddress'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      transactionId: data['transactionId'],
      mpesaReceiptNumber: data['mpesaReceiptNumber'],
    );
  }

  static OrderStatus _parseOrderStatus(dynamic status) {
    if (status == null) return OrderStatus.pending;
    
    switch (status.toString().toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'processing':
        return OrderStatus.processing;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }

  factory ShopOrderModel.fromEntity(ShopOrder order) {
    return ShopOrderModel(
      id: order.id,
      userId: order.userId,
      orderNumber: order.orderNumber,
      items: order.items,
      total: order.total,
      status: order.status,
      paymentMethod: order.paymentMethod,
      shippingAddress: order.shippingAddress,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      transactionId: order.transactionId,
      mpesaReceiptNumber: order.mpesaReceiptNumber,
    );
  }

  factory ShopOrderModel.fromMap(Map<String, dynamic> map) {
    // Parse items from embedded data
    final List<CartItem> items = [];
    if (map['items'] != null) {
      final itemsList = map['items'] as List<dynamic>;
      for (final itemData in itemsList) {
        items.add(CartItemModel.fromMap(itemData as Map<String, dynamic>));
      }
    }
    
    return ShopOrderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      items: items,
      total: (map['total'] ?? 0).toDouble(),
      status: _parseOrderStatus(map['status']),
      paymentMethod: map['paymentMethod'] ?? '',
      shippingAddress: map['shippingAddress'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      transactionId: map['transactionId'],
      mpesaReceiptNumber: map['mpesaReceiptNumber'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'orderNumber': orderNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod,
      'shippingAddress': shippingAddress,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'transactionId': transactionId,
      'mpesaReceiptNumber': mpesaReceiptNumber,
    };
  }

  ShopOrder toEntity() {
    return ShopOrder(
      id: id,
      userId: userId,
      orderNumber: orderNumber,
      items: items,
      total: total,
      status: status,
      paymentMethod: paymentMethod,
      shippingAddress: shippingAddress,
      createdAt: createdAt,
      updatedAt: updatedAt,
      transactionId: transactionId,
      mpesaReceiptNumber: mpesaReceiptNumber,
    );
  }
}