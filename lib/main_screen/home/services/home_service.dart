import '../../../features/tournaments/data/models/tournament_model.dart';
import '../../../features/tournaments/data/models/match_model.dart';
import '../../../features/auth/domain/entities/community.dart';
import '../data/home_data_source.dart';

/// Service for managing home page data and business logic
class HomeService {
  final HomeDataSource dataSource;

  HomeService({required this.dataSource});

  /// Get all data needed for the home page
  Future<HomePageData> getHomePageData({
    required bool isPlayer,
    String? userId,
  }) async {
    try {
      print('🏠 Loading home page data (isPlayer: $isPlayer)...');

      // Fetch data in parallel for better performance
      final futures = await Future.wait([
        dataSource.getActiveTournaments(limit: 3),
        dataSource.getLiveMatches(limit: 3),
        dataSource.getTopCommunities(limit: 3),
        if (isPlayer && userId != null) 
          dataSource.getUserRecentMatches(userId, limit: 3)
        else 
          Future.value(<MatchModel>[]),
      ]);

      final homeData = HomePageData(
        activeTournaments: futures[0] as List<TournamentModel>,
        liveMatches: futures[1] as List<MatchModel>,
        topCommunities: futures[2] as List<Community>,
        recentMatches: futures[3] as List<MatchModel>,
        isLoading: false,
        error: null,
      );

      print('✅ Home page data loaded successfully');
      print('   - Active tournaments: ${homeData.activeTournaments.length}');
      print('   - Live matches: ${homeData.liveMatches.length}');
      print('   - Top communities: ${homeData.topCommunities.length}');
      print('   - Recent matches: ${homeData.recentMatches.length}');

      return homeData;
    } catch (e) {
      print('❌ Failed to load home page data: $e');
      return HomePageData.error(e.toString());
    }
  }

  /// Get community name by ID (cached for performance)
  Future<String?> getCommunityName(String communityId) async {
    return await dataSource.getCommunityName(communityId);
  }

  /// Open YouTube live stream
  Future<void> openLiveStream(String? youtubeUrl) async {
    if (youtubeUrl == null || youtubeUrl.isEmpty) {
      throw Exception('No YouTube stream URL available');
    }

    try {
      print('🎥 Opening YouTube stream: $youtubeUrl');
      // The URL opening will be handled by the UI layer
      // This method validates the URL and logs the action
      
      if (!youtubeUrl.contains('youtube.com') && !youtubeUrl.contains('youtu.be')) {
        throw Exception('Invalid YouTube URL');
      }
    } catch (e) {
      print('❌ Failed to validate YouTube URL: $e');
      rethrow;
    }
  }
}

/// Data class for home page content
class HomePageData {
  final List<TournamentModel> activeTournaments;
  final List<MatchModel> liveMatches;
  final List<Community> topCommunities;
  final List<MatchModel> recentMatches;
  final bool isLoading;
  final String? error;

  HomePageData({
    required this.activeTournaments,
    required this.liveMatches,
    required this.topCommunities,
    required this.recentMatches,
    required this.isLoading,
    this.error,
  });

  /// Loading state constructor
  HomePageData.loading()
      : activeTournaments = [],
        liveMatches = [],
        topCommunities = [],
        recentMatches = [],
        isLoading = true,
        error = null;

  /// Error state constructor
  HomePageData.error(String errorMessage)
      : activeTournaments = [],
        liveMatches = [],
        topCommunities = [],
        recentMatches = [],
        isLoading = false,
        error = errorMessage;

  /// Copy with method for state updates
  HomePageData copyWith({
    List<TournamentModel>? activeTournaments,
    List<MatchModel>? liveMatches,
    List<Community>? topCommunities,
    List<MatchModel>? recentMatches,
    bool? isLoading,
    String? error,
  }) {
    return HomePageData(
      activeTournaments: activeTournaments ?? this.activeTournaments,
      liveMatches: liveMatches ?? this.liveMatches,
      topCommunities: topCommunities ?? this.topCommunities,
      recentMatches: recentMatches ?? this.recentMatches,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get hasData => 
      activeTournaments.isNotEmpty || 
      liveMatches.isNotEmpty || 
      topCommunities.isNotEmpty || 
      recentMatches.isNotEmpty;

  bool get hasError => error != null;
}