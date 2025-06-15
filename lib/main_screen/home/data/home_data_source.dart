import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/tournaments/data/datasources/tournament_remote_datasource.dart';
import '../../../features/tournaments/data/models/tournament_model.dart';
import '../../../features/tournaments/data/models/match_model.dart';
import '../../../features/tournaments/domain/entities/tournament.dart';
import '../../../features/community/data/datasources/community_local_data_source.dart';
import '../../../features/auth/domain/entities/community.dart';

/// Home page data source for fetching production-ready data
abstract class HomeDataSource {
  /// Get active tournaments for home page display
  Future<List<TournamentModel>> getActiveTournaments({int limit = 5});
  
  /// Get live matches with YouTube streaming
  Future<List<MatchModel>> getLiveMatches({int limit = 5});
  
  /// Get top communities by member count
  Future<List<Community>> getTopCommunities({int limit = 5});
  
  /// Get recent matches for a specific user
  Future<List<MatchModel>> getUserRecentMatches(String userId, {int limit = 5});
  
  /// Get community name by ID
  Future<String?> getCommunityName(String communityId);
}

class HomeDataSourceImpl implements HomeDataSource {
  final TournamentRemoteDataSource tournamentDataSource;
  final CommunityLocalDataSource communityDataSource;
  final FirebaseFirestore firestore;

  HomeDataSourceImpl({
    required this.tournamentDataSource,
    required this.communityDataSource,
    required this.firestore,
  });

  @override
  Future<List<TournamentModel>> getActiveTournaments({int limit = 5}) async {
    try {
      print('🏠 Fetching active tournaments for home page...');
      
      // Get tournaments with 'active' status
      final tournaments = await tournamentDataSource.getTournamentsByStatus(TournamentStatus.active);
      
      // Sort by start date (most recent first) and limit
      tournaments.sort((a, b) => b.startDate.compareTo(a.startDate));
      final limitedTournaments = tournaments.take(limit).toList();
      
      print('✅ Found ${limitedTournaments.length} active tournaments for home');
      return limitedTournaments;
    } catch (e) {
      print('❌ Failed to fetch active tournaments: $e');
      return [];
    }
  }

  @override
  Future<List<MatchModel>> getLiveMatches({int limit = 5}) async {
    try {
      print('🏠 Fetching live matches for home page...');
      
      // Get all live matches (already filtered by isLiveStreamed)
      final matches = await tournamentDataSource.getAllLiveMatches();
      
      // Limit results and ensure they have YouTube URLs
      final limitedMatches = matches
          .where((match) => match.youtubeStreamUrl != null && match.youtubeStreamUrl!.isNotEmpty)
          .take(limit)
          .toList();
      
      print('✅ Found ${limitedMatches.length} live matches with YouTube streams');
      return limitedMatches;
    } catch (e) {
      print('❌ Failed to fetch live matches: $e');
      return [];
    }
  }

  @override
  Future<List<Community>> getTopCommunities({int limit = 5}) async {
    try {
      print('🏠 Fetching top communities for home page...');
      
      // Query communities ordered by member count
      final querySnapshot = await firestore
          .collection('communities')
          .orderBy('memberCount', descending: true)
          .limit(limit)
          .get();

      final communities = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Community(
          id: doc.id,
          name: data['name'] ?? 'Unknown Community',
          description: data['description'] ?? '',
          location: data['location'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          memberCount: data['memberCount'] ?? 0,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isActive: data['isActive'] ?? true,
        );
      }).toList();

      print('✅ Found ${communities.length} top communities');
      return communities;
    } catch (e) {
      print('❌ Failed to fetch top communities: $e');
      return [];
    }
  }

  @override
  Future<List<MatchModel>> getUserRecentMatches(String userId, {int limit = 5}) async {
    try {
      print('🏠 Fetching recent matches for user $userId...');
      
      // Query matches where user is either player1 or player2
      final querySnapshot = await firestore
          .collection('matches')
          .where('status', isEqualTo: 'completed')
          .orderBy('actualEndTime', descending: true)
          .limit(limit * 2) // Get more to filter client-side
          .get();

      final userMatches = querySnapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              return MatchModel.fromFirestore(doc);
            } catch (e) {
              print('⚠️ Skipping corrupted match ${doc.id}: $e');
              return null;
            }
          })
          .where((match) => 
              match != null && 
              (match.player1Id == userId || match.player2Id == userId))
          .cast<MatchModel>()
          .take(limit)
          .toList();

      print('✅ Found ${userMatches.length} recent matches for user');
      return userMatches;
    } catch (e) {
      print('❌ Failed to fetch user recent matches: $e');
      return [];
    }
  }

  @override
  Future<String?> getCommunityName(String communityId) async {
    try {
      print('🏠 Fetching community name for $communityId...');
      
      final doc = await firestore.collection('communities').doc(communityId).get();
      
      if (doc.exists) {
        final name = doc.data()?['name'] as String?;
        print('✅ Found community name: $name');
        return name;
      } else {
        print('⚠️ Community $communityId not found');
        return null;
      }
    } catch (e) {
      print('❌ Failed to fetch community name: $e');
      return null;
    }
  }
}