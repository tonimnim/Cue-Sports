class CartItemModel {
  final String id;
  final String productId;
  final String productName;
  final double productPrice;
  final String? imageUrl;
  final int quantity;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productPrice,
    this.imageUrl,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }

  // Create a CartItem from a Firestore document
  factory CartItemModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CartItemModel(
      id: documentId,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productPrice: (map['productPrice'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'],
      quantity: map['quantity'] ?? 1,
    );
  }

  // Create a copy of the CartItem with updated fields
  CartItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    double? productPrice,
    String? imageUrl,
    int? quantity,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  String toString() {
    return 'CartItem(id: $id, productId: $productId, productName: $productName, productPrice: $productPrice, quantity: $quantity)';
  }
}
