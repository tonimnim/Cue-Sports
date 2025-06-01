import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/cart_item.dart';

class CartItemModel extends CartItem {
  const CartItemModel({
    required String id,
    required String productId,
    required String name,
    required double price,
    required int quantity,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) : super(
          id: id,
          productId: productId,
          name: name,
          price: price,
          quantity: quantity,
          imageUrl: imageUrl,
          metadata: metadata,
        );

  factory CartItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartItemModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
      imageUrl: data['imageUrl'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  factory CartItemModel.fromEntity(CartItem cartItem) {
    return CartItemModel(
      id: cartItem.id,
      productId: cartItem.productId,
      name: cartItem.name,
      price: cartItem.price,
      quantity: cartItem.quantity,
      imageUrl: cartItem.imageUrl,
      metadata: cartItem.metadata,
    );
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      imageUrl: map['imageUrl'],
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'metadata': metadata,
      'updatedAt': Timestamp.now(),
    };
  }

  CartItem toEntity() {
    return CartItem(
      id: id,
      productId: productId,
      name: name,
      price: price,
      quantity: quantity,
      imageUrl: imageUrl,
      metadata: metadata,
    );
  }
} 