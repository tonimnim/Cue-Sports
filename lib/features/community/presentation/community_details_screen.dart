import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pool_billiard_app/core/config/theme.dart';
import 'package:pool_billiard_app/core/di/injection_container.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:pool_billiard_app/features/community/domain/entities.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_bloc.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_event.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_state.dart';
import 'package:pool_billiard_app/widget/buttons/primary_button.dart';
import 'package:pool_billiard_app/widget/display/loading_indicator.dart';

/// Community details screen
///
/// Shows detailed information about a specific community
class CommunityDetailsScreen extends StatelessWidget {
  static const String routeName = '/community-details';

  final String communityId;

  const CommunityDetailsScreen({
    Key? key,
    required this.communityId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<CommunityBloc>()..add(LoadCommunityDetailsEvent(communityId)),
      child: const Scaffold(
        body: _CommunityDetailsView(),
      ),
    );
  }
}

class _CommunityDetailsView extends StatelessWidget {
  const _CommunityDetailsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final String? userId =
        authState is AuthAuthenticated ? authState.user.id : null;

    // If user is authenticated, check membership status
    if (userId != null) {
      final communityId =
          (context.read<CommunityBloc>().state.selectedCommunity?.id);
      if (communityId != null) {
        context.read<CommunityBloc>().add(CheckCommunityMembershipEvent(
              userId: userId,
              communityId: communityId,
            ));
      }
    }

    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        if (state.status == CommunityStatus.loading ||
            state.selectedCommunity == null) {
          return const Center(child: LoadingIndicator());
        } else if (state.status == CommunityStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.errorMessage ?? 'Failed to load community details',
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Try Again',
                  onPressed: () => context.read<CommunityBloc>().add(
                        LoadCommunityDetailsEvent(
                            state.selectedCommunity?.id ?? ''),
                      ),
                ),
              ],
            ),
          );
        }

        final community = state.selectedCommunity!;
        // Player users can join communities
        // Check if the user is authenticated and assume they can join if they have a userId
        final isPlayerUser = userId != null && authState is AuthAuthenticated;
        final isAdmin = community.adminId == userId;

        return CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              expandedHeight: 200.0,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(community.name),
                background: Container(
                  color: AppTheme.primaryColor,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              community.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.textDark,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Navigate to edit community screen
                      // This functionality would be implemented in the admin web app
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Editing is available in the admin web app')),
                      );
                    },
                  ),
              ],
            ),

            // Content
            SliverList(
              delegate: SliverChildListDelegate([
                // Basic Info Card
                _buildInfoCard(
                  title: 'Community Information',
                  children: [
                    if (community.description != null &&
                        community.description!.isNotEmpty)
                      _buildInfoRow(Icons.info_outline, 'Description',
                          community.description!),
                    if (community.location != null &&
                        community.location!.isNotEmpty)
                      _buildInfoRow(Icons.location_on_outlined, 'Location',
                          community.location!),
                    _buildInfoRow(Icons.people_outline, 'Members',
                        '${community.memberCount}'),
                    _buildInfoRow(Icons.emoji_events_outlined, 'Ranking',
                        community.rankingTier),
                    _buildInfoRow(
                      Icons.calendar_today_outlined,
                      'Established',
                      '${community.createdAt.day}/${community.createdAt.month}/${community.createdAt.year}',
                    ),
                  ],
                ),

                // Statistics Card
                _buildInfoCard(
                  title: 'Community Statistics',
                  children: [
                    _buildStatisticRow('Community Points',
                        community.communityPoints.toStringAsFixed(0)),
                    _buildStatisticRow(
                        'Trophies', community.trophyCount.toString()),
                    _buildStatisticRow(
                        'Achievements', community.achievementCount.toString()),
                  ],
                ),

                // Achievements section (if any)
                if (community.hasAchievements)
                  _buildAchievementsSection(community),

                // Join button for players who are not members
                if (isPlayerUser && !(state.isMember ?? false) && !isAdmin) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: PrimaryButton(
                      text: 'Join Community',
                      onPressed: () {
                        context.read<CommunityBloc>().add(JoinCommunityEvent(
                              userId: userId!,
                              communityId: community.id,
                            ));
                      },
                    ),
                  ),
                ],

                // Membership status indicator
                if (userId != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      color:
                          (state.isMember ?? false) ? Colors.green[50] : Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              (state.isMember ?? false) ? Icons.check_circle : Icons.info,
                              color:
                                  (state.isMember ?? false) ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                (state.isMember ?? false)
                                    ? 'You are a member of this community'
                                    : isPlayerUser
                                        ? 'You are not a member of this community'
                                        : 'Upgrade to player account to join communities',
                                style: TextStyle(
                                  color: (state.isMember ?? false)
                                      ? Colors.green[800]
                                      : Colors.orange[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // Upgrade prompt for non-player users
                // Show upgrade button only for authenticated non-player users (fans)
                if (userId != null && !isPlayerUser) 
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: PrimaryButton(
                      text: 'Upgrade to Player',
                      onPressed: () {
                        Navigator.of(context).pushNamed('/upgrade-player');
                      },
                    ),
                  ),

                const SizedBox(height: 32),
              ]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.secondary1, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(color: AppTheme.textDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(Community community) {
    return _buildInfoCard(
      title: 'Achievements',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (community.achievements ?? []).map((achievement) {
            return Chip(
              backgroundColor: AppTheme.accentColor.withValues(alpha: 51), // 0.2 * 255 ≈ 51
              avatar:
                  const Icon(Icons.star, color: AppTheme.accentColor, size: 18),
              label: Text(
                achievement,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
