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
      imageUrl: map['imageUrl'] ?? '',
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

// Sample data for products
List<Product> sampleProducts = [
  // Apparel products
  Product(
    id: '1',
    name: 'Green T-shirt with logo',
    category: 'Apparel',
    price: 200,
    imageUrl: 'assets/images/logo.png', // Replace with actual product image
    isPopular: true,
    description: 'Victory Crest Tee - Official pool team t-shirt with logo',
  ),
  Product(
    id: '2',
    name: 'Green T-shirt with logo',
    category: 'Apparel',
    price: 200,
    imageUrl: 'assets/images/logo.png', // Replace with actual product image
    isPopular: true,
    description: 'Victory Crest Tee - Official pool team t-shirt with logo',
  ),
  Product(
    id: '3',
    name: 'Polo Shirt',
    category: 'Apparel',
    price: 350,
    imageUrl: 'assets/images/logo.png', // Replace with actual product image
    isNewArrival: true,
    description: 'Comfortable polo shirt for casual play',
    rating: 4.2,
  ),
  Product(
    id: '4',
    name: 'Billiard Gloves',
    category: 'Apparel',
    price: 150,
    imageUrl: 'assets/images/logo.png', // Replace with actual product image
    isNewArrival: true,
    description: 'Professional billiard gloves for better control',
    rating: 3.8,
  ),
  
  // Equipment products
  Product(
    id: '5',
    name: 'Professional Cue',
    category: 'Equipment',
    price: 1200,
    imageUrl: 'assets/images/logo.png', // Replace with actual product image
    isPopular: true,
    description: 'Tournament-grade professional cue',
    rating: 5.0,
  ),
  Product(
    id: '6',
    name: 'Cue Case',
    category: 'Equipment',
    price: 500,
    imageUrl: 'assets/images/logo.png', // Replace with actual product image
    isNewArrival: true,
    description: 'Protective case for your valuable cues',
    rating: 4.3,
  ),
  Product(
    id: '7',
    name: 'Chalk Set',
    category: 'Equipment',
    price: 100,
    imageUrl: 'assets/images/logo.png', // Replace with actual product image
    isPopular: true,
    description: 'Premium chalk set for optimal performance',
    rating: 3.5,
  ),
  
  // Accessories products
  Product(
    id: '8',
    name: 'Billiard Keychain',
    category: 'Accessories',
    price: 50,
    imageUrl: 'assets/images/logo.png', // Replace with actual product image
    isNewArrival: true,
    description: 'Stylish keychain for billiard enthusiasts',
    rating: 4.0,
  ),
  Product(
    id: '9',
    name: 'Pool Ball Set Mug',
    category: 'Accessories',
    price: 120,
    imageUrl: 'assets/images/logo.png', // Replace with actual product image
    isPopular: true,
    description: 'Ceramic mug with pool ball design',
    rating: 3.9,
  ),
];
