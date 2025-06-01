import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../domain/entities.dart';

/// Data model class for Community that handles Firestore data conversion
class CommunityModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final String? logoUrl;
  final DateTime createdAt;
  final bool isActive;
  final int? memberCount;
  final List<String>? adminIds;
  // Additional fields for select community screen functionality
  final double? registrationFee;
  final String? contactEmail;
  final String? contactPhone;

  const CommunityModel({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.logoUrl,
    required this.createdAt,
    this.isActive = true,
    this.memberCount,
    this.adminIds,
    this.registrationFee = 500.0, // Default KSh 500 fee
    this.contactEmail,
    this.contactPhone,
  });

  /// Convert CommunityModel to Community entity for domain layer
  Community toEntity() {
    return Community(
      id: id,
      name: name,
      description: description ?? 'No description available',
      location: location ?? 'Unknown location',
      imageUrl: logoUrl ?? '', // Use logoUrl as imageUrl with default empty string
      createdAt: createdAt,
      isActive: isActive,
    );
  }

  /// Create a copy of this CommunityModel with the given fields updated
  CommunityModel copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    String? logoUrl,
    DateTime? createdAt,
    bool? isActive,
    int? memberCount,
    List<String>? adminIds,
    double? registrationFee,
    String? contactEmail,
    String? contactPhone,
  }) {
    return CommunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      memberCount: memberCount ?? this.memberCount,
      adminIds: adminIds ?? this.adminIds,
      registrationFee: registrationFee ?? this.registrationFee,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }

  /// Convert CommunityModel to JSON Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      // We don't include 'id' in the map for Firestore operations
      // as it's stored as the document ID
      'name': name,
      'description': description,
      'location': location,
      'logoUrl': logoUrl,
      'createdAt': FieldValue.serverTimestamp(), // Use server timestamp for consistency
      'isActive': isActive,
      'memberCount': memberCount ?? 0,
      'adminIds': adminIds ?? [],
      'registrationFee': registrationFee ?? 500.0,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create CommunityModel from Firestore document data
  factory CommunityModel.fromJson(Map<String, dynamic> json, {required String id}) {
    return CommunityModel(
      id: id, // Use the provided id parameter
      name: json['name'] ?? 'Unknown',
      description: json['description'],
      location: json['location'],
      logoUrl: json['logoUrl'],
      createdAt: _parseTimestamp(json['createdAt']),
      isActive: json['isActive'] ?? true,
      memberCount: json['memberCount'],
      adminIds: json['adminIds'] != null 
          ? List<String>.from(json['adminIds'])
          : null,
      registrationFee: json['registrationFee'] is num 
          ? (json['registrationFee'] as num).toDouble()
          : 500.0,
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
    );
  }

  /// Create CommunityModel from Firestore DocumentSnapshot
  factory CommunityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommunityModel.fromJson(data, id: doc.id);
  }

  /// Create a list of CommunityModel from QuerySnapshot
  static List<CommunityModel> fromQuerySnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) => CommunityModel.fromFirestore(doc)).toList();
  }

  /// Helper method to parse different timestamp formats
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else {
      return DateTime.now();
    }
  }

  /// Formatted location for display
  String get formattedLocation => location ?? 'Location not specified';
  
  /// Check if the community has a logo
  bool get hasLogo => logoUrl != null && logoUrl!.isNotEmpty;
  
  /// Get the registration fee as a formatted string
  String get formattedFee => 'KSh ${registrationFee?.toStringAsFixed(0) ?? "500"}';

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        location,
        logoUrl,
        createdAt,
        isActive,
        memberCount,
        adminIds,
        registrationFee,
        contactEmail,
        contactPhone,
      ];
}
