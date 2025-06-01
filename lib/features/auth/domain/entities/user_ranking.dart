import 'package:equatable/equatable.dart';

/// Entity representing a user's ranking information
class UserRanking extends Equatable {
  final String userId;
  final String? communityId;
  final int communityRank;
  final int nationalRank;
  final double points;
  final int wins;
  final int losses;
  final int totalMatches;
  final double winPercentage;
  final DateTime lastUpdated;

  const UserRanking({
    required this.userId,
    this.communityId,
    required this.communityRank,
    required this.nationalRank,
    required this.points,
    required this.wins,
    required this.losses,
    required this.totalMatches,
    required this.winPercentage,
    required this.lastUpdated,
  });

  /// Calculate win percentage from wins and total matches
  static double calculateWinPercentage(int wins, int totalMatches) {
    if (totalMatches == 0) return 0.0;
    return (wins / totalMatches) * 100;
  }

  /// Create a UserRanking from a map (e.g., Firestore document)
  factory UserRanking.fromMap(Map<String, dynamic> map) {
    final wins = map['wins'] ?? 0;
    final losses = map['losses'] ?? 0;
    final totalMatches = wins + losses;
    
    return UserRanking(
      userId: map['userId'] ?? '',
      communityId: map['communityId'],
      communityRank: map['communityRank'] ?? 0,
      nationalRank: map['nationalRank'] ?? 0,
      points: (map['points'] ?? 0.0).toDouble(),
      wins: wins,
      losses: losses,
      totalMatches: totalMatches,
      winPercentage: calculateWinPercentage(wins, totalMatches),
      lastUpdated: map['lastUpdated'] != null 
          ? (map['lastUpdated'] is DateTime 
              ? map['lastUpdated'] 
              : DateTime.parse(map['lastUpdated'].toString()))
          : DateTime.now(),
    );
  }

  /// Convert UserRanking to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'communityId': communityId,
      'communityRank': communityRank,
      'nationalRank': nationalRank,
      'points': points,
      'wins': wins,
      'losses': losses,
      'totalMatches': totalMatches,
      'winPercentage': winPercentage,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create a copy of this ranking with some fields updated
  UserRanking copyWith({
    String? userId,
    String? communityId,
    int? communityRank,
    int? nationalRank,
    double? points,
    int? wins,
    int? losses,
    DateTime? lastUpdated,
  }) {
    final newWins = wins ?? this.wins;
    final newLosses = losses ?? this.losses;
    final newTotalMatches = newWins + newLosses;
    
    return UserRanking(
      userId: userId ?? this.userId,
      communityId: communityId ?? this.communityId,
      communityRank: communityRank ?? this.communityRank,
      nationalRank: nationalRank ?? this.nationalRank,
      points: points ?? this.points,
      wins: newWins,
      losses: newLosses,
      totalMatches: newTotalMatches,
      winPercentage: calculateWinPercentage(newWins, newTotalMatches),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        communityId,
        communityRank,
        nationalRank,
        points,
        wins,
        losses,
        totalMatches,
        winPercentage,
        lastUpdated,
      ];
} 