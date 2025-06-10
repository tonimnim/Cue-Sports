class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final bool isPopular;
  final bool isNewArrival;
  final bool isFeatured; // Added featured flag
  final int totalPurchases; // Added total purchases field
  final String description;
  final double rating;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.isPopular = false,
    this.isNewArrival = false,
    this.isFeatured = false, // Default value for featured flag
    this.totalPurchases = 0, // Default value for total purchases
    this.description = '',
    this.rating = 0.0,
  });
  
  // Create a Product from a Firestore document map
  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? 'assets/images/product_placeholder.png',
      category: map['category'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      isPopular: map['isPopular'] ?? false,
      isNewArrival: map['isNewArrival'] ?? false,
      isFeatured: map['isFeatured'] ?? false,
      totalPurchases: map['totalPurchases'] ?? 0,
    );
  }
  
  // Convert Product to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'rating': rating,
      'isPopular': isPopular,
      'isNewArrival': isNewArrival,
      'isFeatured': isFeatured,
      'totalPurchases': totalPurchases,
    };
  }
}

// Products are now loaded from the database
// No hardcoded samples needed
