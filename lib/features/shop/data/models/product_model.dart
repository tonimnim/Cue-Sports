import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.category,
    required super.price,
    required super.imageUrl,
    super.isPopular,
    super.isNewArrival,
    super.isFeatured,
    super.totalPurchases,
    super.description,
    super.rating,
    required super.createdAt,
    required super.updatedAt,
    super.isAvailable,
    super.stockQuantity,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      isPopular: data['isPopular'] ?? false,
      isNewArrival: data['isNewArrival'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      totalPurchases: data['totalPurchases'] ?? 0,
      description: data['description'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      isAvailable: data['isAvailable'] ?? true,
      stockQuantity: data['stockQuantity'] ?? 0,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    
    if (value is Timestamp) {
      return value.toDate();
    }
    
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      category: product.category,
      price: product.price,
      imageUrl: product.imageUrl,
      isPopular: product.isPopular,
      isNewArrival: product.isNewArrival,
      isFeatured: product.isFeatured,
      totalPurchases: product.totalPurchases,
      description: product.description,
      rating: product.rating,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      isAvailable: product.isAvailable,
      stockQuantity: product.stockQuantity,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'isPopular': isPopular,
      'isNewArrival': isNewArrival,
      'isFeatured': isFeatured,
      'totalPurchases': totalPurchases,
      'description': description,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isAvailable': isAvailable,
      'stockQuantity': stockQuantity,
    };
  }

  Product toEntity() {
    return Product(
      id: id,
      name: name,
      category: category,
      price: price,
      imageUrl: imageUrl,
      isPopular: isPopular,
      isNewArrival: isNewArrival,
      isFeatured: isFeatured,
      totalPurchases: totalPurchases,
      description: description,
      rating: rating,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isAvailable: isAvailable,
      stockQuantity: stockQuantity,
    );
  }
} 