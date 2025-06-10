import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/match.dart';

/// Match model for Firebase serialization
class MatchModel extends Match {
  const MatchModel({
    required String id,
    required String tournamentId,
    required String player1Id,
    required String player1Name,
    String? player1Avatar,
    required String player2Id,
    required String player2Name,
    String? player2Avatar,
    String? winnerId,
    String? loserId,
    required DateTime scheduledDateTime,
    required String venue,
    String? tableNumber,
    required MatchStatus status,
    int bestOf = 5,
    String gameType = '8Ball',
    int player1Score = 0,
    int player2Score = 0,
    int player1Points = 0,
    int player2Points = 0,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    required String createdByCommunityAdminId,
    String? updatedByCommunityAdminId,
    String? refereeId,
    String? notes,
    String? youtubeStreamUrl,
    bool isLiveStreamed = false,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          tournamentId: tournamentId,
          player1Id: player1Id,
          player1Name: player1Name,
          player1Avatar: player1Avatar,
          player2Id: player2Id,
          player2Name: player2Name,
          player2Avatar: player2Avatar,
          winnerId: winnerId,
          loserId: loserId,
          scheduledDateTime: scheduledDateTime,
          venue: venue,
          tableNumber: tableNumber,
          status: status,
          bestOf: bestOf,
          gameType: gameType,
          player1Score: player1Score,
          player2Score: player2Score,
          player1Points: player1Points,
          player2Points: player2Points,
          actualStartTime: actualStartTime,
          actualEndTime: actualEndTime,
          createdByCommunityAdminId: createdByCommunityAdminId,
          updatedByCommunityAdminId: updatedByCommunityAdminId,
          refereeId: refereeId,
          notes: notes,
          youtubeStreamUrl: youtubeStreamUrl,
          isLiveStreamed: isLiveStreamed,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Create MatchModel from JSON
  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String,
      player1Id: json['player1Id'] as String,
      player1Name: json['player1Name'] as String,
      player1Avatar: json['player1Avatar'] as String?,
      player2Id: json['player2Id'] as String,
      player2Name: json['player2Name'] as String,
      player2Avatar: json['player2Avatar'] as String?,
      winnerId: json['winnerId'] as String?,
      loserId: json['loserId'] as String?,
      scheduledDateTime: (json['scheduledDateTime'] as Timestamp).toDate(),
      venue: json['venue'] as String,
      tableNumber: json['tableNumber'] as String?,
      status: _parseMatchStatus(json['status'] as String),
      bestOf: json['bestOf'] as int? ?? 5,
      gameType: json['gameType'] as String? ?? '8Ball',
      player1Score: json['player1Score'] as int? ?? 0,
      player2Score: json['player2Score'] as int? ?? 0,
      player1Points: json['player1Points'] as int? ?? 0,
      player2Points: json['player2Points'] as int? ?? 0,
      actualStartTime: json['actualStartTime'] != null
          ? (json['actualStartTime'] as Timestamp).toDate()
          : null,
      actualEndTime: json['actualEndTime'] != null
          ? (json['actualEndTime'] as Timestamp).toDate()
          : null,
      createdByCommunityAdminId: json['createdByCommunityAdminId'] as String,
      updatedByCommunityAdminId: json['updatedByCommunityAdminId'] as String?,
      refereeId: json['refereeId'] as String?,
      notes: json['notes'] as String?,
      youtubeStreamUrl: json['youtubeStreamUrl'] as String?,
      isLiveStreamed: json['isLiveStreamed'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Create MatchModel from Firestore document
  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return MatchModel.fromJson(data);
  }

  /// Convert MatchModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'player1Id': player1Id,
      'player1Name': player1Name,
      'player1Avatar': player1Avatar,
      'player2Id': player2Id,
      'player2Name': player2Name,
      'player2Avatar': player2Avatar,
      'winnerId': winnerId,
      'loserId': loserId,
      'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
      'venue': venue,
      'tableNumber': tableNumber,
      'status': status.name,
      'bestOf': bestOf,
      'gameType': gameType,
      'player1Score': player1Score,
      'player2Score': player2Score,
      'player1Points': player1Points,
      'player2Points': player2Points,
      'actualStartTime':
          actualStartTime != null ? Timestamp.fromDate(actualStartTime!) : null,
      'actualEndTime':
          actualEndTime != null ? Timestamp.fromDate(actualEndTime!) : null,
      'createdByCommunityAdminId': createdByCommunityAdminId,
      'updatedByCommunityAdminId': updatedByCommunityAdminId,
      'refereeId': refereeId,
      'notes': notes,
      'youtubeStreamUrl': youtubeStreamUrl,
      'isLiveStreamed': isLiveStreamed,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Convert to Firestore data (without id)
  Map<String, dynamic> toFirestore() {
    final data = toJson();
    data.remove('id');
    return data;
  }

  /// Parse match status from string
  static MatchStatus _parseMatchStatus(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return MatchStatus.scheduled;
      case 'inprogress':
        return MatchStatus.inProgress;
      case 'completed':
        return MatchStatus.completed;
      case 'cancelled':
        return MatchStatus.cancelled;
      case 'postponed':
        return MatchStatus.postponed;
      case 'noshow':
        return MatchStatus.noShow;
      default:
        throw ArgumentError('Unknown match status: $status');
    }
  }

  /// Create a copy with updated fields
  @override
  MatchModel copyWith({
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
    return MatchModel(
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
}
