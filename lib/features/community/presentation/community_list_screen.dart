import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pool_billiard_app/core/config/theme.dart';
import 'package:pool_billiard_app/core/di/injection_container.dart';
import 'package:pool_billiard_app/features/community/domain/entities/community.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_bloc.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_event.dart';
import 'package:pool_billiard_app/features/community/presentation/bloc/community_state.dart';
import 'package:pool_billiard_app/widget/buttons/primary_button.dart';

/// Communities list screen
///
/// Shows a list of all available communities with search and filter options
class CommunityListScreen extends StatelessWidget {
  static const String routeName = '/communities';

  final bool isSelectionMode;

  const CommunityListScreen({
    Key? key,
    this.isSelectionMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<CommunityBloc>()..add(const LoadCommunitiesEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(isSelectionMode ? 'Select Community' : 'Communities'),
        ),
        body: const _CommunityListView(),
      ),
    );
  }
}

class _CommunityListView extends StatefulWidget {
  const _CommunityListView({Key? key}) : super(key: key);

  @override
  State<_CommunityListView> createState() => _CommunityListViewState();
}

class _CommunityListViewState extends State<_CommunityListView> {
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
        // Community list
        Expanded(
          child: BlocBuilder<CommunityBloc, CommunityState>(
            builder: (context, state) {
              if (state.status == CommunityStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state.status == CommunityStatus.error) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.errorMessage ?? 'An error occurred',
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        text: 'Try Again',
                        onPressed: () => context
                            .read<CommunityBloc>()
                            .add(const LoadCommunitiesEvent()),
                      ),
                    ],
                  ),
                );
              } else {
                // Determine which list to show based on filters
                final communities =
                    state.searchQuery != null || state.filterLocation != null
                        ? state.filteredCommunities ?? []
                        : state.communities ?? [];

                if (communities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.group_off,
                            size: 64, color: AppTheme.secondary1),
                        const SizedBox(height: 16),
                        Text(
                          state.searchQuery != null ||
                                  state.filterLocation != null
                              ? 'No communities match your filters'
                              : 'No communities available',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (state.searchQuery != null ||
                            state.filterLocation != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _selectedLocation = null;
                              });
                              context
                                  .read<CommunityBloc>()
                                  .add(const ResetFiltersEvent());
                              context
                                  .read<CommunityBloc>()
                                  .add(const LoadCommunitiesEvent());
                            },
                            child: const Text('Clear Filters'),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: communities.length,
                  itemBuilder: (context, index) {
                    return _CommunityListTile(
                      community: communities[index],
                      isSelectionMode: (context.findAncestorWidgetOfExactType<
                                  CommunityListScreen>())
                              ?.isSelectionMode ??
                          false,
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class _CommunityListTile extends StatelessWidget {
  final Community community;
  final bool isSelectionMode;

  const _CommunityListTile({
    Key? key,
    required this.community,
    this.isSelectionMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (isSelectionMode) {
            // Return selected community for registration
            Navigator.of(context).pop(community);
          } else {
            // Navigate to community details
            Navigator.of(context).pushNamed(
              '/community-details',
              arguments: community.id,
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Community avatar/logo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        community.initials,
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Community info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          community.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: AppTheme.secondary1),
                            const SizedBox(width: 4),
                            Text(
                              '${community.location}, ${community.county}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.people,
                                size: 16, color: AppTheme.secondary1),
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
                ],
              ),
              const SizedBox(height: 12),
              Text(
                community.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Members
                  _StatBadge(
                    icon: Icons.people,
                    value: community.memberCount.toString(),
                    label: 'Members',
                  ),
                  // Followers (for fans)
                  _StatBadge(
                    icon: Icons.favorite,
                    value: community.followerCount.toString(),
                    label: 'Followers',
                  ),
                  // Skill Level
                  _StatBadge(
                    icon: Icons.stars,
                    value: community.skillLevel,
                    label: 'Level',
                  ),
                ],
              ),
              // Tags
              if (community.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: community.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.accentColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
