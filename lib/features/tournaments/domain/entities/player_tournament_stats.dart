import 'package:equatable/equatable.dart';

/// Player tournament statistics entity
class PlayerTournamentStats extends Equatable {
  final String id; // userId_tournamentId
  final String userId;
  final String tournamentId;
  final String communityId;

  // Basic Stats
  final int totalPoints;
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int communityRanking;

  // Status
  final bool isActive;
  final bool hasAdvanced;

  // Performance metrics
  final double winPercentage;
  final int currentWinStreak;
  final int longestWinStreak;

  // Next match info (denormalized for quick access)
  final String? nextMatchId;
  final DateTime? nextMatchDate;
  final String? nextOpponentId;
  final String? nextOpponentName;

  final DateTime lastUpdated;

  const PlayerTournamentStats({
    required this.id,
    required this.userId,
    required this.tournamentId,
    required this.communityId,
    required this.totalPoints,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.matchesLost,
    required this.communityRanking,
    required this.isActive,
    this.hasAdvanced = false,
    this.winPercentage = 0.0,
    this.currentWinStreak = 0,
    this.longestWinStreak = 0,
    this.nextMatchId,
    this.nextMatchDate,
    this.nextOpponentId,
    this.nextOpponentName,
    required this.lastUpdated,
  });

  /// Create a copy of this stats with updated fields
  PlayerTournamentStats copyWith({
    String? id,
    String? userId,
    String? tournamentId,
    String? communityId,
    int? totalPoints,
    int? matchesPlayed,
    int? matchesWon,
    int? matchesLost,
    int? communityRanking,
    bool? isActive,
    bool? hasAdvanced,
    double? winPercentage,
    int? currentWinStreak,
    int? longestWinStreak,
    String? nextMatchId,
    DateTime? nextMatchDate,
    String? nextOpponentId,
    String? nextOpponentName,
    DateTime? lastUpdated,
  }) {
    return PlayerTournamentStats(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tournamentId: tournamentId ?? this.tournamentId,
      communityId: communityId ?? this.communityId,
      totalPoints: totalPoints ?? this.totalPoints,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      matchesWon: matchesWon ?? this.matchesWon,
      matchesLost: matchesLost ?? this.matchesLost,
      communityRanking: communityRanking ?? this.communityRanking,
      isActive: isActive ?? this.isActive,
      hasAdvanced: hasAdvanced ?? this.hasAdvanced,
      winPercentage: winPercentage ?? this.winPercentage,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      longestWinStreak: longestWinStreak ?? this.longestWinStreak,
      nextMatchId: nextMatchId ?? this.nextMatchId,
      nextMatchDate: nextMatchDate ?? this.nextMatchDate,
      nextOpponentId: nextOpponentId ?? this.nextOpponentId,
      nextOpponentName: nextOpponentName ?? this.nextOpponentName,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Calculate win percentage
  double get calculatedWinPercentage {
    if (matchesPlayed == 0) return 0.0;
    return (matchesWon / matchesPlayed) * 100;
  }

  /// Get performance level based on win percentage
  String get performanceLevel {
    final percentage = calculatedWinPercentage;
    if (percentage >= 80) return 'Excellent';
    if (percentage >= 60) return 'Good';
    if (percentage >= 40) return 'Average';
    return 'Needs Improvement';
  }

  /// Check if player has upcoming match
  bool get hasUpcomingMatch {
    return nextMatchId != null &&
        nextMatchDate != null &&
        DateTime.now().isBefore(nextMatchDate!);
  }

  /// Get formatted next match date
  String? get formattedNextMatchDate {
    if (nextMatchDate == null) return null;
    final date = nextMatchDate!;
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        tournamentId,
        communityId,
        totalPoints,
        matchesPlayed,
        matchesWon,
        matchesLost,
        communityRanking,
        isActive,
        hasAdvanced,
        winPercentage,
        currentWinStreak,
        longestWinStreak,
        nextMatchId,
        nextMatchDate,
        nextOpponentId,
        nextOpponentName,
        lastUpdated,
      ];
}
