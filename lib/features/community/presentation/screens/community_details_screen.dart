import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';
import '../widgets/community_event_card.dart';
import '../widgets/community_post_card.dart';
import '../widgets/member_list_tile.dart';
import '../widgets/community_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/domain/entities/user.dart';

class CommunityDetailsScreen extends StatefulWidget {
  final String communityId;
  final User currentUser;

  const CommunityDetailsScreen({
    super.key,
    required this.communityId,
    required this.currentUser,
  });

  @override
  State<CommunityDetailsScreen> createState() => _CommunityDetailsScreenState();
}

class _CommunityDetailsScreenState extends State<CommunityDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCommunityData();
  }

  void _loadCommunityData() {
    context.read<CommunityBloc>().add(const LoadCommunitiesEvent());
    context.read<CommunityBloc>().add(LoadCommunityEventsEvent(widget.communityId));
    context.read<CommunityBloc>().add(LoadCommunityPostsEvent(widget.communityId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CommunityBloc, CommunityState>(
      listener: (context, state) {
        if (state.status == CommunityStatus.loaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        } else if (state.status == CommunityStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Unknown error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: BlocBuilder<CommunityBloc, CommunityState>(
        builder: (context, state) {
          if (state.status == CommunityStatus.loading) {
            return const LoadingView();
          }

          if (state.status == CommunityStatus.error) {
            return ErrorView(
              message: state.errorMessage ?? 'Failed to load community details',
              onRetry: () {
                context.read<CommunityBloc>().add(const LoadCommunitiesEvent());
              },
            );
          }

          if (state.status == CommunityStatus.loaded) {
            final community = state.selectedCommunity ?? 
              (state.communities?.isNotEmpty == true ? state.communities!.first : null);
            
            if (community == null) {
              return const ErrorView(message: 'Community not found');
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(community.name),
                actions: [
                  if (community.adminId == widget.currentUser.id)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/edit-community',
                          arguments: community,
                        );
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showCommunityOptions(context, community);
                    },
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'About'),
                    Tab(text: 'Events'),
                    Tab(text: 'Posts'),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  // About Tab
                  _buildAboutTab(context, community),

                  // Events Tab
                  _buildEventsTab(context, state.events ?? []),

                  // Posts Tab
                  _buildPostsTab(context, state.posts ?? []),
                ],
              ),
              floatingActionButton: _buildFloatingActionButton(context),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildAboutTab(BuildContext context, Community community) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommunityCard(
            community: community,
            showFullDescription: true,
          ),
          const SizedBox(height: 24),
          Text(
            'Members',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          BlocBuilder<CommunityBloc, CommunityState>(
            builder: (context, state) {
              if (state.status == CommunityStatus.loaded) {
                final members = state.members ?? [];
                if (members.isEmpty) {
                  return const Center(
                    child: Text('No members found'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return MemberListTile(
                      member: member,
                      isAdmin: community.adminId == member.userId,
                      onTap: () {
                        // TODO: Navigate to member profile
                      },
                    );
                  },
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab(BuildContext context, List<CommunityEvent> events) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          'No events yet',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<CommunityBloc>().add(
          LoadCommunityEventsEvent(widget.communityId)
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return CommunityEventCard(
            event: event,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/event-details',
                arguments: event,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPostsTab(BuildContext context, List<CommunityPost> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Text(
          'No posts yet',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<CommunityBloc>().add(
          LoadCommunityPostsEvent(widget.communityId)
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return CommunityPostCard(
            post: post,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/post-details',
                arguments: post,
              );
            },
            onLike: () {
              context.read<CommunityBloc>().add(
                LikePostEvent(
                  postId: post.id,
                  userId: 'current_user_id', // TODO: Get from auth
                ),
              );
            },
            onComment: () {
              Navigator.pushNamed(
                context,
                '/post-details',
                arguments: post,
              );
            },
            onShare: () {
              // TODO: Implement share functionality
            },
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        switch (_tabController.index) {
          case 1: // Events tab
            Navigator.pushNamed(
              context,
              '/create-event',
              arguments: widget.communityId,
            );
            break;
          case 2: // Posts tab
            Navigator.pushNamed(
              context,
              '/create-post',
              arguments: widget.communityId,
            );
            break;
        }
      },
      child: Icon(
        _tabController.index == 1 ? Icons.event_available : Icons.post_add,
      ),
    );
  }

  void _showCommunityOptions(BuildContext context, Community community) {
    final bool isMember = true; // TODO: Check if user is member
    final bool isAdmin = community.adminId == widget.currentUser.id;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMember)
                ListTile(
                  leading: const Icon(Icons.group_add),
                  title: const Text('Join Community'),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<CommunityBloc>().add(
                      JoinCommunityEvent(
                        communityId: community.id,
                        userId: 'current_user_id', // TODO: Get from auth
                      ),
                    );
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.group_remove),
                  title: const Text('Leave Community'),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<CommunityBloc>().add(
                      LeaveCommunityEvent(
                        communityId: community.id,
                        userId: 'current_user_id', // TODO: Get from auth
                      ),
                    );
                  },
                ),
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Delete Community'),
                  textColor: Theme.of(context).colorScheme.error,
                  iconColor: Theme.of(context).colorScheme.error,
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, community);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Community community) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Community'),
          content: const Text(
            'Are you sure you want to delete this community? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement delete community
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 