import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final bool isPopular;
  final bool isNewArrival;
  final bool isFeatured;
  final int totalPurchases;
  final String description;
  final double rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAvailable;
  final int stockQuantity;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.isPopular = false,
    this.isNewArrival = false,
    this.isFeatured = false,
    this.totalPurchases = 0,
    this.description = '',
    this.rating = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.isAvailable = true,
    this.stockQuantity = 0,
  });

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? imageUrl,
    bool? isPopular,
    bool? isNewArrival,
    bool? isFeatured,
    int? totalPurchases,
    String? description,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAvailable,
    int? stockQuantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isPopular: isPopular ?? this.isPopular,
      isNewArrival: isNewArrival ?? this.isNewArrival,
      isFeatured: isFeatured ?? this.isFeatured,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      stockQuantity: stockQuantity ?? this.stockQuantity,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        price,
        imageUrl,
        isPopular,
        isNewArrival,
        isFeatured,
        totalPurchases,
        description,
        rating,
        createdAt,
        updatedAt,
        isAvailable,
        stockQuantity,
      ];
} 