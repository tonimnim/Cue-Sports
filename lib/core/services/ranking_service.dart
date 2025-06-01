import 'package:pool_billiard_app/features/auth/domain/entities/user_ranking.dart';
import 'package:pool_billiard_app/core/services/logger_service.dart';

/// Service for managing user rankings
/// This provides mock data for now and will be replaced with real tournament data later
class RankingService {
  final LoggerService logger;

  RankingService({required this.logger});

  /// Get user ranking data
  /// For now, this returns mock data based on user ID
  /// In the future, this will fetch real ranking data from tournaments
  Future<UserRanking?> getUserRanking(String userId, {String? communityId}) async {
    try {
      logger.i('Getting ranking for user: $userId');
      
      // Mock data - replace with real data from tournament results
      // This simulates different rankings for different users
      final mockRankings = _generateMockRanking(userId, communityId);
      
      logger.i('Retrieved ranking for user $userId: Community rank ${mockRankings.communityRank}, National rank ${mockRankings.nationalRank}');
      
      return mockRankings;
    } catch (e) {
      logger.e('Error getting user ranking', e);
      return null;
    }
  }

  /// Generate mock ranking data
  /// This will be replaced with real data from tournament results
  UserRanking _generateMockRanking(String userId, String? communityId) {
    // Generate consistent but varied mock data based on user ID hash
    final userHash = userId.hashCode.abs();
    
    // Generate rankings between 1-100 for community and 1-1000 for national
    final communityRank = (userHash % 100) + 1;
    final nationalRank = (userHash % 1000) + 1;
    
    // Generate mock stats
    final totalMatches = (userHash % 50) + 10; // 10-60 matches
    final wins = (totalMatches * (0.4 + (userHash % 40) / 100)).round(); // 40-80% win rate
    final losses = totalMatches - wins;
    final points = wins * 10.0 + (userHash % 100); // Points based on wins
    
    return UserRanking(
      userId: userId,
      communityId: communityId,
      communityRank: communityRank,
      nationalRank: nationalRank,
      points: points,
      wins: wins,
      losses: losses,
      totalMatches: totalMatches,
      winPercentage: UserRanking.calculateWinPercentage(wins, totalMatches),
      lastUpdated: DateTime.now().subtract(Duration(days: userHash % 7)), // Updated within last week
    );
  }

  /// Get top players in a community
  /// Mock implementation for now
  Future<List<UserRanking>> getCommunityTopPlayers(String communityId, {int limit = 10}) async {
    try {
      logger.i('Getting top $limit players for community: $communityId');
      
      // Generate mock top players
      final topPlayers = <UserRanking>[];
      for (int i = 1; i <= limit; i++) {
        final mockUserId = 'user_${communityId}_$i';
        final ranking = UserRanking(
          userId: mockUserId,
          communityId: communityId,
          communityRank: i,
          nationalRank: i * 10, // Approximate national rank
          points: (100 - i) * 10.0 + 50, // Decreasing points
          wins: 50 - i,
          losses: 10 + i,
          totalMatches: 60,
          winPercentage: UserRanking.calculateWinPercentage(50 - i, 60),
          lastUpdated: DateTime.now(),
        );
        topPlayers.add(ranking);
      }
      
      return topPlayers;
    } catch (e) {
      logger.e('Error getting community top players', e);
      return [];
    }
  }

  /// Get national top players
  /// Mock implementation for now
  Future<List<UserRanking>> getNationalTopPlayers({int limit = 10}) async {
    try {
      logger.i('Getting top $limit national players');
      
      // Generate mock national top players
      final topPlayers = <UserRanking>[];
      for (int i = 1; i <= limit; i++) {
        final mockUserId = 'national_player_$i';
        final ranking = UserRanking(
          userId: mockUserId,
          communityId: 'community_${i % 5 + 1}', // Distribute across communities
          communityRank: 1, // Top in their community
          nationalRank: i,
          points: (1000 - i) * 5.0, // High points for top players
          wins: 100 - i,
          losses: 5 + i,
          totalMatches: 105,
          winPercentage: UserRanking.calculateWinPercentage(100 - i, 105),
          lastUpdated: DateTime.now(),
        );
        topPlayers.add(ranking);
      }
      
      return topPlayers;
    } catch (e) {
      logger.e('Error getting national top players', e);
      return [];
    }
  }
} 