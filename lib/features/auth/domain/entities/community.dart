/// Community entity representing a Kenya Pool Billiards Club community
class Community {
  final String id;
  final String name;
  final String description;
  final String location;
  final String imageUrl;
  final int memberCount;
  final List<String> memberIds;
  final DateTime createdAt;
  final bool isActive;
  
  /// Getter for logoUrl (compatibility with UI code that uses logoUrl)
  String get logoUrl => imageUrl;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    this.imageUrl = '',
    this.memberCount = 0,
    this.memberIds = const [],
    required this.createdAt,
    this.isActive = true,
  });

  /// Create a community from a map (e.g., Firestore document)
  factory Community.fromMap(Map<String, dynamic> map) {
    return Community(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      memberCount: map['memberCount'] ?? 0,
      memberIds: map['memberIds'] != null 
          ? List<String>.from(map['memberIds'])
          : [],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is DateTime ? map['createdAt'] : DateTime.parse(map['createdAt'].toString()))
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  /// Convert community to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'memberCount': memberCount,
      'memberIds': memberIds,
      'createdAt': createdAt,
    };
  }

  /// Create a copy of this community with some fields updated
  Community copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    String? imageUrl,
    int? memberCount,
    List<String>? memberIds,
    DateTime? createdAt,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      memberCount: memberCount ?? this.memberCount,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
