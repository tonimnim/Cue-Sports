import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/tournament.dart';

class TournamentModel extends Tournament {
  const TournamentModel({
    required super.id,
    required super.name,
    required super.type,
    required super.location,
    required super.startDate,
    required super.endDate,
    required super.maxPlayers,
    required super.entryFee,
    super.isFeatured,
    super.registeredUserIds,
    required super.status,
    super.isPublic,
    super.communityIds,
    super.description,
    super.imageUrl,
    super.prizeStructure,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
  });

  factory TournamentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TournamentModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      location: data['location'] ?? '',
      startDate: _parseDateTime(data['startDate'] ?? data['date']),
      endDate: _parseDateTime(data['endDate'] ?? data['date']),
      maxPlayers: data['maxPlayers'] ?? data['players'] ?? 0,
      entryFee: (data['entryFee'] ?? data['price'] ?? 0).toDouble(),
      isFeatured: data['isFeatured'] ?? false,
      registeredUserIds: List<String>.from(data['registeredUserIds'] ?? data['registeredUsers'] ?? []),
      status: _parseTournamentStatus(data['status']),
      isPublic: data['isPublic'] ?? true,
      communityIds: List<String>.from(data['communityIds'] ?? data['communities'] ?? []),
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      prizeStructure: data['prizeStructure'],
      createdAt: _parseDateTime(data['createdAt'] ?? data['updatedAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      createdBy: data['createdBy'] ?? '',
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
        // First try ISO format
        return DateTime.parse(value);
      } catch (e) {
        try {
          // Try to parse formats like "Feb 15, 2025"
          return _parseCustomDateFormat(value);
        } catch (e2) {
          print('Failed to parse date string: $value, using current time');
          return DateTime.now();
        }
      }
    }
    
    return DateTime.now();
  }

  static DateTime _parseCustomDateFormat(String dateStr) {
    // Handle formats like "Feb 15, 2025", "Mar 22, 2025", etc.
    final months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
    };
    
    final parts = dateStr.toLowerCase().replaceAll(',', '').split(' ');
    if (parts.length >= 3) {
      final monthStr = parts[0];
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      
      if (months.containsKey(monthStr) && day != null && year != null) {
        return DateTime(year, months[monthStr]!, day);
      }
    }
    
    throw FormatException('Invalid date format: $dateStr');
  }

  static TournamentStatus _parseTournamentStatus(dynamic status) {
    if (status == null) return TournamentStatus.upcoming;
    
    switch (status.toString().toLowerCase()) {
      case 'upcoming':
        return TournamentStatus.upcoming;
      case 'registration_open':
        return TournamentStatus.registration_open;
      case 'registration_closed':
        return TournamentStatus.registration_closed;
      case 'in_progress':
        return TournamentStatus.in_progress;
      case 'completed':
        return TournamentStatus.completed;
      case 'cancelled':
        return TournamentStatus.cancelled;
      default:
        return TournamentStatus.upcoming;
    }
  }

  factory TournamentModel.fromEntity(Tournament tournament) {
    return TournamentModel(
      id: tournament.id,
      name: tournament.name,
      type: tournament.type,
      location: tournament.location,
      startDate: tournament.startDate,
      endDate: tournament.endDate,
      maxPlayers: tournament.maxPlayers,
      entryFee: tournament.entryFee,
      isFeatured: tournament.isFeatured,
      registeredUserIds: tournament.registeredUserIds,
      status: tournament.status,
      isPublic: tournament.isPublic,
      communityIds: tournament.communityIds,
      description: tournament.description,
      imageUrl: tournament.imageUrl,
      prizeStructure: tournament.prizeStructure,
      createdAt: tournament.createdAt,
      updatedAt: tournament.updatedAt,
      createdBy: tournament.createdBy,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'location': location,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'maxPlayers': maxPlayers,
      'entryFee': entryFee,
      'isFeatured': isFeatured,
      'registeredUserIds': registeredUserIds,
      'status': status.toString().split('.').last,
      'isPublic': isPublic,
      'communityIds': communityIds,
      'description': description,
      'imageUrl': imageUrl,
      'prizeStructure': prizeStructure,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  Tournament toEntity() {
    return Tournament(
      id: id,
      name: name,
      type: type,
      location: location,
      startDate: startDate,
      endDate: endDate,
      maxPlayers: maxPlayers,
      entryFee: entryFee,
      isFeatured: isFeatured,
      registeredUserIds: registeredUserIds,
      status: status,
      isPublic: isPublic,
      communityIds: communityIds,
      description: description,
      imageUrl: imageUrl,
      prizeStructure: prizeStructure,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
    );
  }
} 