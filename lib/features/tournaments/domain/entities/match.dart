import 'package:equatable/equatable.dart';

/// Enum for match status
enum MatchStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
  postponed,
  noShow
}

/// Match entity representing a tournament match between two players
class Match extends Equatable {
  final String id;
  final String tournamentId;

  // Players
  final String player1Id;
  final String player1Name; // Denormalized for display
  final String? player1Avatar;
  final String player2Id;
  final String player2Name;
  final String? player2Avatar;
  final String? winnerId;
  final String? loserId;

  // Basic Details
  final DateTime scheduledDateTime;
  final String venue;
  final String? tableNumber;
  final MatchStatus status;

  // Match Configuration
  final int bestOf; // Best of how many games
  final String gameType; // 8Ball, 9Ball, Snooker

  // Results
  final int player1Score; // Games won
  final int player2Score; // Games won
  final int player1Points; // Tournament points earned
  final int player2Points; // Tournament points earned

  // Timing
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;

  // Administration
  final String createdByCommunityAdminId;
  final String? updatedByCommunityAdminId;
  final String? refereeId;
  final String? notes;

  // Media
  final String? youtubeStreamUrl;
  final bool isLiveStreamed;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const Match({
    required this.id,
    required this.tournamentId,
    required this.player1Id,
    required this.player1Name,
    this.player1Avatar,
    required this.player2Id,
    required this.player2Name,
    this.player2Avatar,
    this.winnerId,
    this.loserId,
    required this.scheduledDateTime,
    required this.venue,
    this.tableNumber,
    required this.status,
    this.bestOf = 5,
    this.gameType = '8Ball',
    this.player1Score = 0,
    this.player2Score = 0,
    this.player1Points = 0,
    this.player2Points = 0,
    this.actualStartTime,
    this.actualEndTime,
    required this.createdByCommunityAdminId,
    this.updatedByCommunityAdminId,
    this.refereeId,
    this.notes,
    this.youtubeStreamUrl,
    this.isLiveStreamed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this match with updated fields
  Match copyWith({
    String? id,
    String? tournamentId,
    String? player1Id,
    String? player1Name,
    String? player1Avatar,
    String? player2Id,
    String? player2Name,
    String? player2Avatar,
    String? winnerId,
    String? loserId,
    DateTime? scheduledDateTime,
    String? venue,
    String? tableNumber,
    MatchStatus? status,
    int? bestOf,
    String? gameType,
    int? player1Score,
    int? player2Score,
    int? player1Points,
    int? player2Points,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    String? createdByCommunityAdminId,
    String? updatedByCommunityAdminId,
    String? refereeId,
    String? notes,
    String? youtubeStreamUrl,
    bool? isLiveStreamed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Match(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      player1Id: player1Id ?? this.player1Id,
      player1Name: player1Name ?? this.player1Name,
      player1Avatar: player1Avatar ?? this.player1Avatar,
      player2Id: player2Id ?? this.player2Id,
      player2Name: player2Name ?? this.player2Name,
      player2Avatar: player2Avatar ?? this.player2Avatar,
      winnerId: winnerId ?? this.winnerId,
      loserId: loserId ?? this.loserId,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      venue: venue ?? this.venue,
      tableNumber: tableNumber ?? this.tableNumber,
      status: status ?? this.status,
      bestOf: bestOf ?? this.bestOf,
      gameType: gameType ?? this.gameType,
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      player1Points: player1Points ?? this.player1Points,
      player2Points: player2Points ?? this.player2Points,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      createdByCommunityAdminId:
          createdByCommunityAdminId ?? this.createdByCommunityAdminId,
      updatedByCommunityAdminId:
          updatedByCommunityAdminId ?? this.updatedByCommunityAdminId,
      refereeId: refereeId ?? this.refereeId,
      notes: notes ?? this.notes,
      youtubeStreamUrl: youtubeStreamUrl ?? this.youtubeStreamUrl,
      isLiveStreamed: isLiveStreamed ?? this.isLiveStreamed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get match status display name
  String get statusDisplayName {
    switch (status) {
      case MatchStatus.scheduled:
        return 'Scheduled';
      case MatchStatus.inProgress:
        return 'In Progress';
      case MatchStatus.completed:
        return 'Completed';
      case MatchStatus.cancelled:
        return 'Cancelled';
      case MatchStatus.postponed:
        return 'Postponed';
      case MatchStatus.noShow:
        return 'No Show';
    }
  }

  /// Check if match is live
  bool get isLive {
    return status == MatchStatus.inProgress && isLiveStreamed;
  }

  /// Check if match is completed
  bool get isCompleted {
    return status == MatchStatus.completed;
  }

  /// Check if match is upcoming
  bool get isUpcoming {
    return status == MatchStatus.scheduled &&
        DateTime.now().isBefore(scheduledDateTime);
  }

  /// Get match duration if completed
  Duration? get duration {
    if (actualStartTime != null && actualEndTime != null) {
      return actualEndTime!.difference(actualStartTime!);
    }
    return null;
  }

  /// Get formatted scheduled time
  String get formattedScheduledTime {
    final time = scheduledDateTime;
    return '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Get winner name
  String? get winnerName {
    if (winnerId == null) return null;
    return winnerId == player1Id ? player1Name : player2Name;
  }

  /// Get loser name
  String? get loserName {
    if (loserId == null) return null;
    return loserId == player1Id ? player1Name : player2Name;
  }

  /// Check if a specific player is in this match
  bool hasPlayer(String playerId) {
    return player1Id == playerId || player2Id == playerId;
  }

  /// Get opponent for a specific player
  String? getOpponentId(String playerId) {
    if (player1Id == playerId) return player2Id;
    if (player2Id == playerId) return player1Id;
    return null;
  }

  /// Get opponent name for a specific player
  String? getOpponentName(String playerId) {
    if (player1Id == playerId) return player2Name;
    if (player2Id == playerId) return player1Name;
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        player1Id,
        player1Name,
        player1Avatar,
        player2Id,
        player2Name,
        player2Avatar,
        winnerId,
        loserId,
        scheduledDateTime,
        venue,
        tableNumber,
        status,
        bestOf,
        gameType,
        player1Score,
        player2Score,
        player1Points,
        player2Points,
        actualStartTime,
        actualEndTime,
        createdByCommunityAdminId,
        updatedByCommunityAdminId,
        refereeId,
        notes,
        youtubeStreamUrl,
        isLiveStreamed,
        createdAt,
        updatedAt,
      ];
}
