import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';
import '../widgets/community_card.dart';
import '../widgets/community_event_card.dart';
import '../widgets/community_post_card.dart';
import '../../domain/entities/community_event.dart';
import '../../domain/entities/community_post.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<CommunityBloc>().add(const LoadCommunitiesEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filters
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Communities'),
            Tab(text: 'Events'),
            Tab(text: 'Posts'),
          ],
        ),
      ),
      body: BlocBuilder<CommunityBloc, CommunityState>(
        builder: (context, state) {
          if (state.status == CommunityStatus.loading) {
            return const LoadingView();
          }

          if (state.status == CommunityStatus.error) {
            return ErrorView(
              message: state.errorMessage ?? 'Unknown error occurred',
              onRetry: () {
                context.read<CommunityBloc>().add(const LoadCommunitiesEvent());
              },
            );
          }

          if (state.status == CommunityStatus.loaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                // Communities Tab
                RefreshIndicator(
                  onRefresh: () async {
                    context.read<CommunityBloc>().add(const LoadCommunitiesEvent());
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.communities?.length ?? 0,
                    itemBuilder: (context, index) {
                      final communities = state.communities ?? [];
                      if (index >= communities.length) return const SizedBox();
                      final community = communities[index];
                      return CommunityCard(
                        community: community,
                        onTap: () {
                          // TODO: Navigate to community details
                        },
                      );
                    },
                  ),
                ),

                // Events Tab
                RefreshIndicator(
                  onRefresh: () async {
                    context.read<CommunityBloc>().add(const LoadCommunityEventsEvent(''));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.events?.length ?? 0,
                    itemBuilder: (context, index) {
                      final events = state.events ?? [];
                      if (index >= events.length) return const SizedBox();
                      final event = events[index];
                      return CommunityEventCard(
                        event: event,
                        onTap: () {
                          // TODO: Navigate to event details
                        },
                      );
                    },
                  ),
                ),

                // Posts Tab
                RefreshIndicator(
                  onRefresh: () async {
                    context.read<CommunityBloc>().add(const LoadCommunityPostsEvent(''));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.posts?.length ?? 0,
                    itemBuilder: (context, index) {
                      final posts = state.posts ?? [];
                      if (index >= posts.length) return const SizedBox();
                      final post = posts[index];
                      return CommunityPostCard(
                        post: post,
                        onTap: () {
                          // TODO: Navigate to post details
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Show create options based on current tab
          switch (_tabController.index) {
            case 0:
              // Create community
              break;
            case 1:
              // Create event
              break;
            case 2:
              // Create post
              break;
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 