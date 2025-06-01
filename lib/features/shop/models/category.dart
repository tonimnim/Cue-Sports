class ProductCategory {
  final String id;
  final String name;

  ProductCategory({
    required this.id,
    required this.name,
  });

  // Convert ProductCategory to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Create a ProductCategory from a Firestore document
  factory ProductCategory.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductCategory(
      id: documentId,
      name: map['name'] ?? '',
    );
  }

  @override
  String toString() => 'ProductCategory(id: $id, name: $name)';
}
