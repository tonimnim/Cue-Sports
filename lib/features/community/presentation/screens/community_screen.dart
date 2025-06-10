import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/auth_service.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';
import '../widgets/community_card.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/config/theme.dart';
import '../community_details_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTabIndex = 0;

  // Track ongoing operations to prevent multiple calls
  final Set<String> _pendingOperations = <String>{};

  // Timer for periodic refresh every 30 minutes
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController?.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController?.index ?? 0;
      });
    });
    print('🚀 CommunityScreen: Initializing and loading data...');

    // Load initial data
    _loadInitialData();

    // Set up periodic refresh every 30 minutes for fresh data
    _setupPeriodicRefresh();
  }

  void _loadInitialData() {
    // Load all communities
    context.read<CommunityBloc>().add(const LoadCommunitiesEvent());

    // Load top ranked communities for Popular tab
    context.read<CommunityBloc>().add(const LoadTopRankedCommunitiesEvent());

    // Load user's community
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user.id.isNotEmpty) {
      print('🔍 Loading user community for user: ${authState.user.id}');
      context
          .read<CommunityBloc>()
          .add(LoadUserCommunityEvent(authState.user.id));
    } else {
      print(
          '⚠️ Cannot load user community: User not authenticated or ID is empty');
    }
  }

  void _setupPeriodicRefresh() {
    // Set up timer for automatic refresh every 30 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      print('🔄 Automatic community refresh triggered');
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    _refreshTimer?.cancel(); // Cancel periodic refresh timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          print('❌ CommunityScreen: User not authenticated');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final currentUser = authState.user;
        print(
            '👤 CommunityScreen: Current user: ${currentUser.fullName} (${currentUser.userType})');
        print('🔍 CommunityScreen: User ID: "${currentUser.id}"');
        print('🔍 CommunityScreen: Full User Object: $currentUser');

        // Validate user authentication
        if (currentUser.id.isEmpty) {
          print('⚠️ User ID is empty, checking authentication status...');
          final authUserId = AuthService.instance.getCurrentUserId();
          print('🔍 Auth Service User ID: ${authUserId ?? "null"}');
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: SafeArea(
            child: BlocListener<CommunityBloc, CommunityState>(
              listener: (context, state) {
                // Listen for state changes to provide feedback
                if (state.userCommunity == null) {
                  print(
                      '🎉 BlocListener: User community is now NULL - unfollow succeeded!');
                } else {
                  print(
                      '📍 BlocListener: User community is: ${state.userCommunity?.name}');
                }
              },
              child: Column(
                children: [
                  // Header with location
                  _buildHeader(),

                  // Search bar
                  _buildSearchBar(),

                  // Content based on selected tab with scrollable tabs
                  Expanded(
                    child: BlocBuilder<CommunityBloc, CommunityState>(
                      builder: (context, state) {
                        return _buildContent(state, currentUser);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Text(
        'Communities',
        style: AppTheme.headingStyle.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppTheme.textLight,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          20, 0, 20, 16), // Added bottom margin for spacing
      height: 50, // Fixed height to match target
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: _searchController,
        style: AppTheme.bodyStyle.copyWith(
          color: AppTheme.textLight,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Find Communities Near You...',
          hintStyle: AppTheme.bodyStyle.copyWith(
            color: AppTheme.textLight.withOpacity(0.6),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.textLight.withOpacity(0.6),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppTheme.textLight.withOpacity(0.6),
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    // Reset to show all communities
                    context
                        .read<CommunityBloc>()
                        .add(const ResetFiltersEvent());
                    context
                        .read<CommunityBloc>()
                        .add(const LoadCommunitiesEvent());
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });

          // Trigger search with debouncing - improved handling
          if (value.trim().isNotEmpty && value.trim().length >= 2) {
            print('🔍 Searching communities with query: "${value.trim()}"');
            context
                .read<CommunityBloc>()
                .add(SearchCommunitiesEvent(value.trim()));
          } else if (value.trim().isEmpty) {
            // Reset to show all communities when search is cleared
            print('🔄 Resetting community search');
            context.read<CommunityBloc>().add(const ResetFiltersEvent());
            context.read<CommunityBloc>().add(const LoadCommunitiesEvent());
          }
        },
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            context
                .read<CommunityBloc>()
                .add(SearchCommunitiesEvent(value.trim()));
          }
        },
      ),
    );
  }

  Widget _buildTabButtons() {
    if (_tabController == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          _buildTabButton('All', 0),
          const SizedBox(width: 40),
          _buildTabButton('Popular', 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
        _tabController?.animateTo(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.accentColor,
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Text(
          text,
          style: AppTheme.bodyStyle.copyWith(
            color: isSelected
                ? AppTheme.textDark
                : AppTheme.textLight.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(CommunityState state, currentUser) {
    print('🔍 CommunityScreen: BlocBuilder state: ${state.status}');

    if (state.status == CommunityStatus.loading) {
      print('⏳ CommunityScreen: Loading communities...');
      return _buildLoadingState();
    }

    if (state.status == CommunityStatus.error) {
      print(
          '❌ CommunityScreen: Error loading communities: ${state.errorMessage}');
      return _buildErrorState(state.errorMessage);
    }

    if (state.status == CommunityStatus.loaded) {
      final communities = state.communities ?? [];
      print('✅ CommunityScreen: Loaded ${communities.length} communities');

      return _buildCommunitiesList(communities, currentUser);
    }

    print('❓ CommunityScreen: Unknown state: ${state.status}');
    return _buildEmptyState();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: CircularProgressIndicator(
              color: AppTheme.accentColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Discovering Communities...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Finding the best billiards communities for you',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? "We couldn't load the communities right now",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                print('🔄 CommunityScreen: Retrying after error...');
                context.read<CommunityBloc>().add(const LoadCommunitiesEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.group_off,
                color: AppTheme.accentColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Communities Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'There are no communities available at the moment.\nCheck back later or try refreshing.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.read<CommunityBloc>().add(const LoadCommunitiesEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunitiesList(List<dynamic> communities, currentUser) {
    // Get user's actual community from BLoC state
    final communityState = context.read<CommunityBloc>().state;
    final userCommunity = communityState.userCommunity;

    // Enhanced debug logging for state inspection
    print('🔍 CommunitiesList Debug (UI Build):');
    print('   Total communities: ${communities.length}');
    print('   User community: ${userCommunity?.name ?? 'null'}');
    print('   User community ID: ${userCommunity?.id ?? 'null'}');
    print('   BLoC state status: ${communityState.status}');
    print('   Search query: ${communityState.searchQuery ?? 'null'}');
    print(
        '   Filtered communities: ${communityState.filteredCommunities?.length ?? 0}');

    // Use filtered communities if search is active, otherwise use all communities
    List<dynamic> communitiesToShow;
    if (communityState.searchQuery != null &&
        communityState.searchQuery!.isNotEmpty &&
        communityState.filteredCommunities != null) {
      communitiesToShow = communityState.filteredCommunities!;
      print('   Using filtered communities: ${communitiesToShow.length}');
    } else {
      communitiesToShow = communities;
      print('   Using all communities: ${communitiesToShow.length}');
    }

    if (userCommunity == null) {
      print(
          '   ✅ User has NO community - should show follow buttons on all cards');
    } else {
      print(
          '   ❌ User HAS community - should hide follow buttons on other cards');
      final userType = currentUser?.userType ?? 'player';
      final userId = currentUser?.id ?? '';

      if (userType == 'fan' && userCommunity != null) {
        // Check if user is actually in the followers list
        final followers = userCommunity.followers ?? [];
        final isActuallyFollowing = followers.contains(userId);
        print(
            '   Fan following status: $isActuallyFollowing (userId: $userId)');
        print('   Community followers: $followers');
      }
    }

    // Filter out user's community from the main list to avoid duplication
    List<dynamic> otherCommunities = communitiesToShow;
    if (userCommunity != null) {
      otherCommunities = communitiesToShow.where((community) {
        final communityId = _getSafeProperty(community, 'id', '');
        return communityId != userCommunity.id;
      }).toList();
    }

    print('   Other communities: ${otherCommunities.length}');

    // Display content based on selected tab
    switch (_selectedTabIndex) {
      case 0:
        return _buildAllCommunitiesTab(otherCommunities, currentUser,
            userCommunity: userCommunity);
      case 1:
        return _buildPopularTab(otherCommunities, currentUser,
            userCommunity: userCommunity);
      default:
        return _buildAllCommunitiesTab(otherCommunities, currentUser,
            userCommunity: userCommunity);
    }
  }

  Widget _buildAllCommunitiesTab(List<dynamic> communities, currentUser,
      {dynamic userCommunity}) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab buttons - now scrollable
          _buildTabButtons(),
          const SizedBox(height: 16),

          // My Community section - show only if user has a community
          if (userCommunity != null) ...[
            _buildSectionHeader('My Community', ''),
            const SizedBox(height: 12),
            _buildUserCommunityCard(userCommunity, currentUser),
            const SizedBox(height: 24),
          ],

          // Other Communities section
          if (communities.isNotEmpty) ...[
            _buildSectionHeader(
                userCommunity != null ? 'Other Communities' : 'Communities',
                ''),
            const SizedBox(height: 12),
            _buildCommunitiesGrid(communities, currentUser,
                hasUserCommunity: userCommunity != null),
          ] else if (userCommunity == null) ...[
            // Show empty state if user has no community and no other communities
            _buildEmptyCommunitiesGrid(),
          ],

          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildPopularTab(List<dynamic> communities, currentUser,
      {dynamic userCommunity}) {
    // Use top-ranked communities from BLoC state
    final communityState = context.read<CommunityBloc>().state;
    final popularCommunities = communityState.topCommunities ?? [];

    // Filter out user's community from the popular list to avoid duplication
    List<dynamic> filteredPopularCommunities = popularCommunities;
    if (userCommunity != null) {
      filteredPopularCommunities = popularCommunities.where((community) {
        final communityId = _getSafeProperty(community, 'id', '');
        return communityId != userCommunity.id;
      }).toList();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab buttons - now scrollable
          _buildTabButtons(),
          const SizedBox(height: 16),

          // My Community section - show only if user has a community
          if (userCommunity != null) ...[
            _buildSectionHeader('My Community', ''),
            const SizedBox(height: 12),
            _buildUserCommunityCard(userCommunity, currentUser),
            const SizedBox(height: 24),
          ],

          // Popular section
          _buildSectionHeader(
              'Most Popular Communities', 'Communities with most members'),
          const SizedBox(height: 12),
          if (filteredPopularCommunities.isNotEmpty)
            _buildCommunitiesGrid(filteredPopularCommunities, currentUser,
                hasUserCommunity: userCommunity != null)
          else
            _buildEmptyCommunitiesGrid(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.subheadingStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserCommunityCard(community, currentUser) {
    final userType = currentUser?.userType ?? 'player';
    // Get authenticated user ID using production-ready auth service
    String userId =
        currentUser?.id ?? AuthService.instance.getCurrentUserId() ?? '';
    if (userId.isEmpty) {
      print('⚠️ No valid user ID found - user may not be authenticated');
    }

    // For user's own community, we know they are following/joined it
    // This is the community returned by getUserCommunity() so it's definitely theirs
    // TODO: Follow functionality disabled for version 2
    // bool isFollowedByUser = userType == 'fan';
    bool isJoinedByUser = userType == 'player';

    print('🏠 Building user community card:');
    print('   Community: ${_getSafeProperty(community, 'name', 'Unknown')}');
    print('   UserType: $userType');
    print('   IsFollowed: false (disabled)'); // Follow functionality disabled
    print('   IsJoined: $isJoinedByUser');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: CommunityCard(
        community: community,
        currentUser: currentUser,
        isJoined: isJoinedByUser, // Players join communities
        isFollowed: false, // Follow functionality disabled
        isUserCommunity: true, // This is the user's own community
        userAlreadyHasCommunity:
            true, // User definitely has a community (this one)
        onViewDetails: () {
          _showCommunityDetails(community);
        },
        // TODO: For fans: Show unfollow button since this is their followed community
        // TODO: For players: No buttons since they're already members
        // Follow/unfollow functionality disabled for version 2
        // onFollowPressed: userType == 'fan'
        //     ? () {
        //         _handleUnfollowCommunity(community);
        //       }
        //     : null,
        onFollowPressed: null, // Disabled follow functionality
        // No join callbacks since this is user's own community
      ),
    );
  }

  Widget _buildCommunitiesGrid(List<dynamic> communities, currentUser,
      {required bool hasUserCommunity}) {
    if (communities.isEmpty) {
      return _buildEmptyCommunitiesGrid();
    }

    // Direct access to user properties instead of using _getSafeProperty
    // Get authenticated user ID using production-ready auth service
    String userId =
        currentUser?.id ?? AuthService.instance.getCurrentUserId() ?? '';
    if (userId.isEmpty) {
      print('⚠️ No valid user ID found - user may not be authenticated');
    }
    final userType = currentUser?.userType ?? 'player';

    // Debug logging to understand why userId is empty
    print('🔍 _buildCommunitiesGrid Debug:');
    print('   currentUser type: ${currentUser.runtimeType}');
    print('   currentUser.id direct: "${currentUser?.id}"');
    print('   currentUser.userType direct: "${currentUser?.userType}"');
    print('   userId final: "$userId"');
    print('   userType final: "$userType"');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: communities.map((community) {
          // TODO: Check if user is following this community (for fans) - disabled for version 2
          // bool isFollowedByUser = false;
          // if (userType == 'fan' && community != null) {
          //   final followers = _getSafeProperty(
          //       community, 'followers', <String>[],
          //       isList: true);
          //   isFollowedByUser = followers.contains(userId);
          // }

          return CommunityCard(
            community: community,
            currentUser: currentUser,
            isJoined: false, // Not user's community (handled separately)
            isFollowed: false, // Disabled follow functionality
            isUserCommunity: false, // These are other communities
            userAlreadyHasCommunity:
                hasUserCommunity, // Pass whether user has community
            onViewDetails: () {
              _showCommunityDetails(community);
            },
            // TODO: For fans: Show follow buttons only if they don't have a community
            // TODO: If they have a community, no buttons show (as per requirements)
            // Follow functionality disabled for version 2
            // onFollowPressed: userType == 'fan' && !hasUserCommunity
            //     ? () {
            //         _handleFollowCommunity(community);
            //       }
            //     : null,
            onFollowPressed: null, // Disabled follow functionality
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOtherCommunitiesGrid(List<dynamic> communities, currentUser) {
    return _buildCommunitiesGrid(communities, currentUser,
        hasUserCommunity: true);
  }

  Widget _buildEmptyCommunitiesGrid() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 60,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No communities match your search',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildFollowCommunityMessage() {
  //   return Padding(
  //     padding: const EdgeInsets.all(40),
  //     child: Column(
  //       children: [
  //         Container(
  //           width: 80,
  //           height: 80,
  //           decoration: BoxDecoration(
  //             color: AppTheme.accentColor.withOpacity(0.1),
  //             borderRadius: BorderRadius.circular(40),
  //           ),
  //           child: Icon(
  //             Icons.location_searching,
  //             color: AppTheme.accentColor,
  //             size: 40,
  //           ),
  //         ),
  //         const SizedBox(height: 24),
  //         Text(
  //           'Follow a Community First',
  //           style: TextStyle(
  //             color: Colors.white,
  //             fontSize: 20,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         Text(
  //           'To see communities near you, please follow a community first.\nWe\'ll use your followed community\'s location to find other communities in the same area.',
  //           style: TextStyle(
  //             color: Colors.white.withOpacity(0.7),
  //             fontSize: 16,
  //           ),
  //           textAlign: TextAlign.center,
  //         ),
  //         const SizedBox(height: 24),
  //         ElevatedButton.icon(
  //           onPressed: () {
  //             // Switch to "All" tab to see all communities
  //             setState(() {
  //               _selectedTabIndex = 0;
  //             });
  //             _tabController?.animateTo(0);
  //           },
  //           icon: const Icon(Icons.explore),
  //           label: const Text('Browse All Communities'),
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: AppTheme.accentColor,
  //             foregroundColor: Colors.black,
  //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(16),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Helper methods
  void _showCommunityDetails(dynamic community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityDetailsScreen(
          community: community,
        ),
      ),
    );
  }

  void _handleJoinCommunity(dynamic community) {
    final communityId = _getSafeProperty(community, 'id', '');
    final authState = context.read<AuthBloc>().state;

    print('🔍 _handleJoinCommunity called:');
    print('   Community: ${_getSafeProperty(community, 'name', 'Unknown')}');
    print('   CommunityId: "$communityId"');
    print('   AuthState: ${authState.runtimeType}');

    if (authState is AuthAuthenticated) {
      // Get authenticated user ID using production-ready auth service
      String userId = authState.user.id.isNotEmpty
          ? authState.user.id
          : AuthService.instance.getCurrentUserId() ?? '';
      if (userId.isEmpty) {
        print('⚠️ No valid user ID found - user may not be authenticated');
      }
      print('   UserId: "$userId"');
      print('   User: ${authState.user.fullName} (${authState.user.userType})');

      if (communityId.isNotEmpty && userId.isNotEmpty) {
        print('✅ Dispatching JoinCommunityEvent');
        // Dispatch join community event
        context.read<CommunityBloc>().add(JoinCommunityEvent(
              communityId: communityId,
              userId: userId,
            ));
      } else {
        print(
            '❌ Validation failed: communityId="$communityId", userId="$userId"');
        final communityName = _getSafeProperty(community, 'name', 'Community');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to join $communityName. Missing ID data.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('❌ User not authenticated');
      final communityName = _getSafeProperty(community, 'name', 'Community');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to join $communityName.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // TODO: Follow functionality disabled for version 2
  // void _handleFollowCommunity(dynamic community) {
  //   final communityId = _getSafeProperty(community, 'id', '');
  //   final communityName = _getSafeProperty(community, 'name', 'Community');
  //   final authState = context.read<AuthBloc>().state;

  //   print('🔍 _handleFollowCommunity called:');
  //   print('   Community: $communityName');
  //   print('   CommunityId: "$communityId"');
  //   print('   AuthState: ${authState.runtimeType}');

  //   // Check if operation is already pending
  //   final operationKey = 'follow_$communityId';
  //   if (_pendingOperations.contains(operationKey)) {
  //     print('⚠️ Follow operation already in progress for $communityName');
  //     return;
  //   }

  //   if (authState is AuthAuthenticated) {
  //     // Get authenticated user ID using production-ready auth service
  //     String userId = authState.user.id.isNotEmpty
  //         ? authState.user.id
  //         : AuthService.instance.getCurrentUserId() ?? '';
  //     if (userId.isEmpty) {
  //       print('⚠️ No valid user ID found - user may not be authenticated');
  //     }
  //     print('   UserId: "$userId"');
  //     print('   User: ${authState.user.fullName} (${authState.user.userType})');

  //     // Validate user type (only fans can follow communities)
  //     if (authState.user.userType != 'fan') {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(
  //               'Only fans can follow communities. Players are automatically members of their registered community.'),
  //           backgroundColor: Colors.orange,
  //         ),
  //       );
  //       return;
  //     }

  //     if (communityId.isNotEmpty && userId.isNotEmpty) {
  //       print('✅ Dispatching FollowCommunityEvent');

  //       // Track pending operation
  //       _pendingOperations.add(operationKey);

  //       // Show immediate feedback
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Following $communityName...'),
  //           backgroundColor: AppTheme.accentColor,
  //           duration: const Duration(seconds: 1),
  //         ),
  //       );

  //       // Dispatch follow community event
  //       context.read<CommunityBloc>().add(FollowCommunityEvent(
  //             communityId: communityId,
  //             userId: userId,
  //           ));

  //       // Remove from pending operations after a delay
  //       Future.delayed(const Duration(seconds: 3), () {
  //         _pendingOperations.remove(operationKey);
  //       });
  //     } else {
  //       print(
  //           '❌ Validation failed: communityId="$communityId", userId="$userId"');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Unable to follow $communityName. Missing ID data.'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } else {
  //     print('❌ User not authenticated');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Please log in to follow $communityName.'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  // void _handleUnfollowCommunity(dynamic community) {
  //   final communityId = _getSafeProperty(community, 'id', '');
  //   final communityName = _getSafeProperty(community, 'name', 'Community');
  //   final authState = context.read<AuthBloc>().state;

  //   print('🔍 _handleUnfollowCommunity called:');
  //   print('   Community: $communityName');
  //   print('   CommunityId: "$communityId"');
  //   print('   AuthState: ${authState.runtimeType}');
  //   print(
  //       '   Current user community: ${context.read<CommunityBloc>().state.userCommunity?.name ?? 'null'}');

  //   // Check if operation is already pending
  //   final operationKey = 'unfollow_$communityId';
  //   if (_pendingOperations.contains(operationKey)) {
  //     print('⚠️ Unfollow operation already in progress for $communityName');
  //     return;
  //   }

  //   if (authState is AuthAuthenticated) {
  //     // Get authenticated user ID using production-ready auth service
  //     String userId = authState.user.id.isNotEmpty
  //         ? authState.user.id
  //         : AuthService.instance.getCurrentUserId() ?? '';
  //     if (userId.isEmpty) {
  //       print('⚠️ No valid user ID found - user may not be authenticated');
  //     }
  //     print('   UserId: "$userId"');
  //     print('   User: ${authState.user.fullName} (${authState.user.userType})');

  //     if (communityId.isNotEmpty && userId.isNotEmpty) {
  //       print('✅ Dispatching UnfollowCommunityEvent');

  //       // Track pending operation
  //       _pendingOperations.add(operationKey);

  //       // Show immediate feedback
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Unfollowing $communityName...'),
  //           backgroundColor: Colors.orange,
  //           duration: const Duration(seconds: 2),
  //         ),
  //       );

  //       print('✅ Dispatching UnfollowCommunityEvent to BLoC');

  //       // Dispatch unfollow community event
  //       context.read<CommunityBloc>().add(UnfollowCommunityEvent(
  //             communityId: communityId,
  //             userId: userId,
  //           ));

  //       // Show success feedback after a short delay
  //       Future.delayed(const Duration(milliseconds: 500), () {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(
  //                 '✅ Unfollowed $communityName! You can now follow other communities.'),
  //             backgroundColor: AppTheme.successColor,
  //             duration: const Duration(seconds: 2),
  //           ),
  //         );
  //       });

  //       // Remove from pending operations after a delay
  //       Future.delayed(const Duration(seconds: 3), () {
  //         _pendingOperations.remove(operationKey);
  //       });
  //     } else {
  //       print(
  //           '❌ Validation failed: communityId="$communityId", userId="$userId"');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content:
  //               Text('Unable to unfollow $communityName. Missing ID data.'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } else {
  //     print('❌ User not authenticated');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Please log in to unfollow $communityName.'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  T _getSafeProperty<T>(dynamic obj, String property, T defaultValue,
      {bool isList = false}) {
    try {
      if (obj == null) return defaultValue;
      if (obj is Map) {
        final value = obj[property];
        if (value == null) return defaultValue;
        if (isList && value is! List) return defaultValue;
        return value as T;
      }

      // Enhanced property access for different object types
      switch (property) {
        case 'name':
          return obj.name ?? defaultValue;
        case 'id':
          // Handle both User and Community objects
          final id = obj.id;
          if (id == null || (id is String && id.isEmpty)) {
            print('⚠️ Object ID is null/empty: ${obj.runtimeType} - $obj');
            return defaultValue;
          }
          return id as T;
        case 'memberCount':
          return obj.memberCount ?? defaultValue;
        case 'followerCount':
          return obj.followerCount ?? defaultValue;
        case 'followers':
          return obj.followers ?? defaultValue;
        case 'userType':
          return obj.userType ?? defaultValue;
        default:
          print(
              '⚠️ Unknown property "$property" for object: ${obj.runtimeType}');
          return defaultValue;
      }
    } catch (e) {
      print('❌ Error accessing property "$property": $e');
      return defaultValue;
    }
  }
}
