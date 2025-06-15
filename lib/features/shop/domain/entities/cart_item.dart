/// Entity class representing an item in the shopping cart
class CartItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final String userId;

  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.userId,
    this.imageUrl,
    this.metadata,
  });

  /// Create a copy of this cart item with some fields replaced
  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    double? price,
    int? quantity,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    String? userId,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
      userId: userId ?? this.userId,
    );
  }

  /// Convert cart item to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'metadata': metadata,
      'userId': userId,
    };
  }

  /// Create a cart item from a map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String,
      productId: map['productId'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      imageUrl: map['imageUrl'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
      userId: map['userId'] as String? ?? '',
    );
  }

  /// Calculate the total price for this item
  double get total => price * quantity;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}