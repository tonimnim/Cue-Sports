import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/theme.dart';
import '../../../core/di/injection_container.dart';
import '../../auth/domain/entities/user.dart' as auth;
import '../domain/entities/community.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_bloc.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_event.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_state.dart';
import 'package:pool_billiard_app/features/community/presentation/community_details_screen.dart';
import 'package:pool_billiard_app/widget/buttons/primary_button.dart';
import 'widgets/community_card.dart';
import 'widgets/community_event_card.dart';
import 'widgets/community_post_card.dart';


/// Communities page that displays either:
/// 1. For fans: A list of all communities with search, filter options, and a call to action to become a player
/// 2. For players: Information about their community and a list of other communities
class CommunitiesPage extends StatefulWidget {
  static const String routeName = '/communities';
  
  const CommunitiesPage({Key? key}) : super(key: key);

  @override
  State<CommunitiesPage> createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunitiesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isPlayer = false; // Will be determined by auth state
  String? _userCommunityId; // Will be set if user is a player
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // In a real app, we would get the user's type and community from auth
    // For now, using mock data
    _checkUserStatus();
  }
  
  Future<void> _checkUserStatus() async {
    // This would be replaced with actual auth state check
    // For MVP, using mock data
    final mockUser = auth.User(
      id: 'user123',
      email: 'user@example.com',
      fullName: 'John Doe',
      phoneNumber: '+254712345678',
      createdAt: DateTime.now(),
      isEmailVerified: true,
      userType: 'player', // Change to 'fan' to see fan view
      communityId: 'comm123', // Would be null for fans
      profileImageUrl: null,
      registeredAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    
    setState(() {
      _isPlayer = mockUser.isPlayer;
      _userCommunityId = mockUser.communityId;
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CommunityBloc>()..add(const LoadCommunitiesEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Communities'),
          bottom: _isPlayer ? TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'My Community'),
              Tab(text: 'All Communities'),
            ],
          ) : null,
        ),
        body: _isPlayer 
          ? TabBarView(
              controller: _tabController,
              children: [
                _MyCommunityView(communityId: _userCommunityId!),
                const _AllCommunitiesView(isPlayer: true),
              ],
            )
          : const _AllCommunitiesView(isPlayer: false),
      ),
    );
  }
}

/// Shows information about the player's own community
class _MyCommunityView extends StatelessWidget {
  final String communityId;
  
  const _MyCommunityView({Key? key, required this.communityId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        if (state.status == CommunityStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state.status == CommunityStatus.error) {
          return Center(child: Text(state.errorMessage ?? 'Failed to load community', style: const TextStyle(color: Colors.red)));
        }
        
        if (state.communities == null || state.communities!.isEmpty) {
          return Center(child: Text(state.errorMessage ?? 'Failed to load community', style: const TextStyle(color: Colors.red)));
        }
        
        final myCommunity = state.communities!.firstWhere(
          (c) => c.id == communityId,
          orElse: () => Community(
            id: '',
            name: 'Community not found',
            description: 'Please try again later',
            location: '',
            leaderId: '',
            level: CommunityLevel.local,
            totalPlayers: 0,
            points: 0,
            trophyCount: 0,
            followCount: 0,
            playerIds: const [],
            followerIds: const [],
            trophies: const [],
            memberCount: 0,
            communityPoints: 0,
            achievements: const [],
            createdAt: DateTime.now(),
          ),
        );
        
        if (myCommunity.id.isEmpty) {
          context.read<CommunityBloc>().add(LoadCommunityDetailsEvent(communityId));
          return const Center(child: CircularProgressIndicator());
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Community Header Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Community logo or placeholder
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryColor,
                        // Community logo - using first letter as placeholder since logoUrl isn't part of the entity
                        child: Text(
                          myCommunity.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 40, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        myCommunity.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (myCommunity.location?.isNotEmpty == true)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              myCommunity.location!,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getRankingColor(myCommunity.rankingTier),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          myCommunity.rankingTier,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Community Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Community Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (myCommunity.description != null && myCommunity.description!.isNotEmpty) ...[  
                        const Text(
                          'About',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(myCommunity.description!),
                        const SizedBox(height: 16),
                      ],
                      
                      // Member count
                      Row(
                        children: [
                          const Icon(Icons.people, size: 20, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            '${myCommunity.memberCount} members',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Points
                          _StatColumn(
                            icon: Icons.emoji_events,
                            value: myCommunity.communityPoints.toStringAsFixed(0),
                            label: 'Points',
                          ),
                          // Trophies
                          _StatColumn(
                            icon: Icons.emoji_events_outlined,
                            value: myCommunity.trophyCount.toString(),
                            label: 'Trophies',
                          ),
                          // Achievements
                          _StatColumn(
                            icon: Icons.star_outline,
                            value: myCommunity.achievementCount.toString(),
                            label: 'Achievements',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Note: This is just the MVP, no leaderboard or tournament info yet
              const Center(
                child: Text(
                  'You are a registered member of this community',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Color _getRankingColor(String rankingTier) {
    switch (rankingTier) {
      case 'Elite':
        return Colors.purple;
      case 'Premier':
        return Colors.indigo;
      case 'Professional':
        return Colors.blue;
      case 'Advanced':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

/// Shows a list of all available communities
class _AllCommunitiesView extends StatefulWidget {
  final bool isPlayer;
  
  const _AllCommunitiesView({Key? key, required this.isPlayer}) : super(key: key);

  @override
  State<_AllCommunitiesView> createState() => _AllCommunitiesViewState();
}

class _AllCommunitiesViewState extends State<_AllCommunitiesView> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedLocation;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      context.read<CommunityBloc>().add(SearchCommunitiesEvent(_searchController.text));
    } else {
      context.read<CommunityBloc>().add(const ResetFiltersEvent());
      context.read<CommunityBloc>().add(const LoadCommunitiesEvent());
    }
  }
  
  void _onLocationFilterChanged(String? location) {
    setState(() {
      _selectedLocation = location;
    });
    
    if (location != null && location.isNotEmpty) {
      context.read<CommunityBloc>().add(LoadCommunitiesByLocationEvent(location));
    } else {
      context.read<CommunityBloc>().add(const ResetFiltersEvent());
      context.read<CommunityBloc>().add(const LoadCommunitiesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and filter section
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.primaryColor.withValues(alpha: 26), // 0.1 * 255 ≈ 26
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search communities',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Location filter dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Filter by location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                value: _selectedLocation,
                items: const [
                  DropdownMenuItem(value: '', child: Text('All locations')),
                  DropdownMenuItem(value: 'Nairobi', child: Text('Nairobi')),
                  DropdownMenuItem(value: 'Mombasa', child: Text('Mombasa')),
                  DropdownMenuItem(value: 'Kisumu', child: Text('Kisumu')),
                  DropdownMenuItem(value: 'Nakuru', child: Text('Nakuru')),
                  DropdownMenuItem(value: 'Eldoret', child: Text('Eldoret')),
                ],
                onChanged: _onLocationFilterChanged,
              ),
            ],
          ),
        ),
        
        // List of communities
        Expanded(
          child: BlocBuilder<CommunityBloc, CommunityState>(
            builder: (context, state) {
              if (state.status == CommunityStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (state.status == CommunityStatus.error) {
                return Center(
                  child: Text(state.errorMessage ?? 'Failed to load communities', style: const TextStyle(color: Colors.red)),
                );
              }
              
              if (state.communities?.isEmpty ?? true) {
                return const Center(
                  child: Text('No communities found matching your criteria'),
                );
              }
              
              final communities = state.communities!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: communities.length,
                itemBuilder: (context, index) {
                  final community = communities[index];
                  return _CommunityCard(
                    community: community, 
                    isPlayer: widget.isPlayer,
                    onTap: () => _viewCommunityDetails(community),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  void _viewCommunityDetails(Community community) {
    Navigator.pushNamed(
      context, 
      CommunityDetailsScreen.routeName,
      arguments: {'communityId': community.id},
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final Community community;
  final bool isPlayer;
  final VoidCallback onTap;
  
  const _CommunityCard({
    Key? key, 
    required this.community, 
    required this.isPlayer,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Community logo or placeholder
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryColor,
                    // Community logo - using first letter as placeholder since logoUrl isn't part of the entity
                    child: Text(
                      community.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name, location, and member count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          community.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (community.location != null && community.location!.isNotEmpty) ...[  
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                community.location!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.people, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${community.memberCount} members',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Ranking badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRankingColor(community.rankingTier),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      community.rankingTier,
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (community.description != null && community.description!.isNotEmpty) ...[  
                const SizedBox(height: 12),
                Text(
                  community.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Points
                  _StatBadge(
                    icon: Icons.emoji_events,
                    value: community.communityPoints.toStringAsFixed(0),
                    label: 'Points',
                  ),
                  // Trophies
                  _StatBadge(
                    icon: Icons.emoji_events_outlined,
                    value: community.trophyCount.toString(),
                    label: 'Trophies',
                  ),
                  // Achievements
                  _StatBadge(
                    icon: Icons.star_outline,
                    value: community.achievementCount.toString(),
                    label: 'Achievements',
                  ),
                ],
              ),
              
              // Join button for fans only
              if (!isPlayer) ...[  
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Join Community',
                    onPressed: () => _joinCommunity(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  void _joinCommunity(BuildContext context) {
    // For fans, joining a community requires upgrading to player
    // Navigate to the payment screen with this community selected
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'communityId': community.id,
        'communityName': community.name,
        'isUpgrade': true,
      },
    );
  }
  
  Color _getRankingColor(String rankingTier) {
    switch (rankingTier) {
      case 'Elite':
        return Colors.purple;
      case 'Premier':
        return Colors.indigo;
      case 'Professional':
        return Colors.blue;
      case 'Advanced':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatBadge({
    Key? key,
    required this.icon,
    required this.value,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.accentColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatColumn({
    Key? key,
    required this.icon,
    required this.value,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppTheme.accentColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
