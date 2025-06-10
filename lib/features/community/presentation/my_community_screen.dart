import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pool_billiard_app/core/config/theme.dart';
import 'package:pool_billiard_app/core/di/injection_container.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_bloc.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_event.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_state.dart';
import 'package:pool_billiard_app/widget/buttons/primary_button.dart';
import 'package:pool_billiard_app/widget/display/loading_indicator.dart';

/// My Community Screen
///
/// Shows the user's current community information
/// Only accessible to paid players, not basic users
class MyCommunityScreen extends StatelessWidget {
  static const String routeName = '/my-community';

  const MyCommunityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          // Check if user is a paid player based on their membership type
          // For Kenya Pool Billiards, players have paid the KSh 500 fee
          final isPaidPlayer = authState
              .user.isPlayer; // Using the provided getter in User entity

          if (isPaidPlayer) {
            return BlocProvider(
              create: (context) => sl<CommunityBloc>()
                ..add(LoadUserCommunityEvent(authState.user.id)),
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('My Community'),
                ),
                body: const _MyCommunityView(),
              ),
            );
          } else {
            // Show upgrade prompt for basic users
            return Scaffold(
              appBar: AppBar(
                title: const Text('My Community'),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: AppTheme.secondary1,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Upgrade Required',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'You need to upgrade to a Player account to join communities and access this feature.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: 'Upgrade to Player (KSh 500)',
                      onPressed: () {
                        Navigator.of(context).pushNamed('/upgrade-player');
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        } else {
          // User not authenticated
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Community'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 64,
                    color: AppTheme.secondary1,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sign In Required',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Please sign in to view your community.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Sign In',
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

class _MyCommunityView extends StatelessWidget {
  const _MyCommunityView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        if (state.status == CommunityStatus.loading) {
          return const Center(child: LoadingIndicator());
        } else if (state.status == CommunityStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.errorMessage ?? 'Failed to load your community',
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Try Again',
                  onPressed: () => context.read<CommunityBloc>().add(
                        LoadUserCommunityEvent(
                          (context.read<AuthBloc>().state as AuthAuthenticated)
                              .user
                              .id,
                        ),
                      ),
                ),
              ],
            ),
          );
        } else if (state.userCommunity == null) {
          // User doesn't belong to any community
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppTheme.secondary1,
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Community Yet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'You haven\'t joined a community yet. Join a community to connect with other players in your area.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Browse Communities',
                  onPressed: () {
                    Navigator.of(context).pushNamed('/communities');
                  },
                ),
              ],
            ),
          );
        }

        // User has a community
        final community = state.userCommunity!;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Community Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: AppTheme.primaryColor,
                child: Column(
                  children: [
                    // Community avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          community.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.textDark,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Community name
                    Text(
                      community.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                    if (community.location != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        community.location!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Member count
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${community.memberCount} Members',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Community statistics
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Community Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Information cards
                    Row(
                      children: [
                        _buildStatCard(
                          title: 'Members',
                          value: community.memberCount.toString(),
                          icon: Icons.people,
                          flex: 1,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          title: 'Followers',
                          value: community.followerCount.toString(),
                          icon: Icons.favorite,
                          flex: 1,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatCard(
                          title: 'Skill Level',
                          value: community.skillLevel,
                          icon: Icons.trending_up,
                          flex: 1,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          title: 'Tags',
                          value: community.tags.length.toString(),
                          icon: Icons.tag,
                          flex: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Description
              if (community.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            community.description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Tags section
              if (community.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tags',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: community.tags.map((tag) {
                              return Chip(
                                backgroundColor: AppTheme.accentColor
                                    .withValues(alpha: 51), // 0.2 * 255 ≈ 51
                                avatar: const Icon(Icons.tag,
                                    color: AppTheme.accentColor, size: 18),
                                label: Text(
                                  tag,
                                  style: const TextStyle(
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required int flex,
  }) {
    return Expanded(
      flex: flex,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
