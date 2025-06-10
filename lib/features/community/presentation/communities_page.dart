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

/// Communities page that displays either:
/// 1. For fans: A list of all communities with search, filter options, and a call to action to become a player
/// 2. For players: "My Community" section showing their community, then "Other Communities" section
class CommunitiesPage extends StatefulWidget {
  static const String routeName = '/communities';

  const CommunitiesPage({Key? key}) : super(key: key);

  @override
  State<CommunitiesPage> createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunitiesPage>
    with SingleTickerProviderStateMixin {
  bool _isPlayer = false; // Will be determined by auth state
  String? _userCommunityId; // Will be set if user is a player

  @override
  void initState() {
    super.initState();

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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<CommunityBloc>()..add(const LoadCommunitiesEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Communities'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: _isPlayer
            ? _PlayerCommunitiesView(communityId: _userCommunityId!)
            : const _AllCommunitiesView(isPlayer: false),
      ),
    );
  }
}

/// Shows player's community first, then other communities
class _PlayerCommunitiesView extends StatelessWidget {
  final String communityId;

  const _PlayerCommunitiesView({Key? key, required this.communityId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        if (state.status == CommunityStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == CommunityStatus.error) {
          return Center(
              child: Text(state.errorMessage ?? 'Failed to load communities',
                  style: const TextStyle(color: Colors.red)));
        }

        if (state.communities == null || state.communities!.isEmpty) {
          return Center(
              child: Text(state.errorMessage ?? 'Failed to load communities',
                  style: const TextStyle(color: Colors.red)));
        }

        final allCommunities = state.communities!;
        final myCommunity = allCommunities.firstWhere(
          (c) => c.id == communityId,
          orElse: () => Community(
            id: '',
            name: 'Community not found',
            description: 'Please try again later',
            initials: 'NF',
            location: '',
            county: '',
            memberCount: 0,
            followerCount: 0,
            followers: const [],
            createdAt: DateTime.now(),
            lastActivityAt: DateTime.now(),
            tags: const [],
            adminUserId: '',
          ),
        );

        // Filter out user's community from other communities
        final otherCommunities =
            allCommunities.where((c) => c.id != communityId).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // My Community Section
              if (myCommunity.id.isNotEmpty) ...[
                Text(
                  'My Community',
                  style: AppTheme.h2Style, // 20px SemiBold Raleway
                ),
                const SizedBox(height: 12),
                _MyCommunityCard(community: myCommunity),
                const SizedBox(height: 32),
              ],

              // Other Communities Section
              Text(
                'Other Communities',
                style: AppTheme.h2Style, // 20px SemiBold Raleway
              ),
              const SizedBox(height: 12),

              if (otherCommunities.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No other communities available',
                      style: AppTheme.bodyLargeStyle.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                )
              else
                ...otherCommunities
                    .map((community) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _CommunityCard(
                            community: community,
                            isPlayer: true,
                            onTap: () =>
                                _viewCommunityDetails(context, community),
                          ),
                        ))
                    .toList(),
            ],
          ),
        );
      },
    );
  }

  void _viewCommunityDetails(BuildContext context, Community community) {
    Navigator.pushNamed(
      context,
      CommunityDetailsScreen.routeName,
      arguments: {'communityId': community.id},
    );
  }
}

/// Enhanced card for user's own community
class _MyCommunityCard extends StatelessWidget {
  final Community community;

  const _MyCommunityCard({Key? key, required this.community}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with crown icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.crown,
                  color: AppTheme.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: AppTheme.h2Style.copyWith(
                        color: AppTheme.accentColor,
                      ), // 20px SemiBold Raleway
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      community.location,
                      style: AppTheme.bodySmallStyle.copyWith(
                        color: Colors.white70,
                      ), // 14px Regular Raleway
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          if (community.description.isNotEmpty) ...[
            Text(
              community.description,
              style: AppTheme.bodyLargeStyle.copyWith(
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ), // 16px Regular Raleway
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
          ],

          // Stats row
          Row(
            children: [
              _buildStatChip(
                icon: Icons.people,
                label: 'Members',
                value: community.memberCount.toString(),
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.emoji_events,
                label: 'Followers',
                value: community.followerCount.toString(),
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.star,
                label: 'Tags',
                value: '${community.tags.length}',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                CommunityDetailsScreen.routeName,
                arguments: {'communityId': community.id},
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: AppTheme.textDark,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.visibility),
              label: Text(
                'View Community Details',
                style: AppTheme.bodyLargeStyle.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white70,
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTheme.bodySmallStyle.copyWith(
                fontWeight: FontWeight.w600,
              ), // 14px SemiBold Raleway
            ),
            Text(
              label,
              style: AppTheme.captionStyle.copyWith(
                color: Colors.white70,
              ), // 12px Regular Raleway
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a list of all available communities
class _AllCommunitiesView extends StatefulWidget {
  final bool isPlayer;

  const _AllCommunitiesView({Key? key, required this.isPlayer})
      : super(key: key);

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
      context
          .read<CommunityBloc>()
          .add(SearchCommunitiesEvent(_searchController.text));
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
      context
          .read<CommunityBloc>()
          .add(LoadCommunitiesByLocationEvent(location));
    } else {
      context.read<CommunityBloc>().add(const ResetFiltersEvent());
      context.read<CommunityBloc>().add(const LoadCommunitiesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and filters for fans
        if (!widget.isPlayer) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search communities...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Location filter
                DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  decoration: InputDecoration(
                    labelText: 'Filter by location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All locations')),
                    DropdownMenuItem(value: 'Nairobi', child: Text('Nairobi')),
                    DropdownMenuItem(value: 'Mombasa', child: Text('Mombasa')),
                    DropdownMenuItem(value: 'Kisumu', child: Text('Kisumu')),
                  ],
                  onChanged: _onLocationFilterChanged,
                ),
              ],
            ),
          ),
        ],

        // Communities list
        Expanded(
          child: BlocBuilder<CommunityBloc, CommunityState>(
            builder: (context, state) {
              if (state.status == CommunityStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == CommunityStatus.error) {
                return Center(
                  child: Text(
                      state.errorMessage ?? 'Failed to load communities',
                      style: const TextStyle(color: Colors.red)),
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
      color: AppTheme.cardColor, // Using proper card color
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
                          style: AppTheme.bodyLargeStyle.copyWith(
                            fontWeight: FontWeight.w600,
                          ), // 16px SemiBold Raleway
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                community.location,
                                style: AppTheme.bodySmallStyle.copyWith(
                                  color: Colors.white70,
                                ), // 14px Regular Raleway
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.people,
                                size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              '${community.memberCount} members',
                              style: AppTheme.bodySmallStyle.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Ranking badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRankingColor(community.level.name),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      community.level.name,
                      style: AppTheme.captionStyle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ), // 12px SemiBold Raleway
                    ),
                  ),
                ],
              ),
              if (community.description != null &&
                  community.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  community.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySmallStyle.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ), // 14px Regular Raleway
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
        Icon(icon, color: AppTheme.accentColor, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.captionStyle.copyWith(
            fontWeight: FontWeight.w600,
          ), // 12px SemiBold Raleway
        ),
        Text(
          label,
          style: AppTheme.overlineStyle.copyWith(
            color: Colors.white70,
          ), // 10px Regular Raleway
        ),
      ],
    );
  }
}
