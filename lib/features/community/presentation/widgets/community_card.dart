import 'package:flutter/material.dart';
import 'package:pool_billiard_app/core/config/theme.dart';

class CommunityCard extends StatelessWidget {
  final dynamic community; // Accept dynamic to handle different entity types
  final dynamic currentUser; // Accept dynamic to handle different user types
  final bool isJoined;
  final bool isFollowed;
  final bool isUserCommunity; // True if this is user's own community
  final bool
      userAlreadyHasCommunity; // True if user already follows/joined a community
  final VoidCallback? onJoinPressed;
  final VoidCallback? onFollowPressed; // This will handle both follow/unfollow
  final VoidCallback? onViewDetails;

  const CommunityCard({
    Key? key,
    required this.community,
    required this.currentUser,
    this.isJoined = false,
    this.isFollowed = false,
    this.isUserCommunity = false,
    this.userAlreadyHasCommunity = false,
    this.onJoinPressed,
    this.onFollowPressed, // Single callback for follow/unfollow toggle
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: isUserCommunity ? 8 : 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF16543A), // Set card background to #16543A
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onViewDetails,
          child: Container(
            padding: const EdgeInsets.all(12), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 8), // Reduced spacing
                _buildDescription(),
                const SizedBox(height: 8), // Reduced spacing
                _buildTags(),
                const SizedBox(height: 12), // Reduced spacing
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = _getProperty('name', 'Unknown Community');
    final location = _getProperty('location', 'Unknown Location');
    final county = _getProperty('county', '');
    final followerCount = _getProperty('followerCount', 0);
    final memberCount = _getProperty('memberCount', 0);
    final logoUrl = _getProperty('logoUrl', null);
    final initials = _getInitials(name);
    final userType = _getProperty('userType', 'fan', fromObject: currentUser);

    return Row(
      children: [
        // Community Avatar
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: logoUrl != null
              ? ClipOval(
                  child: Image.network(
                    logoUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildInitialsAvatar(initials);
                    },
                  ),
                )
              : _buildInitialsAvatar(initials),
        ),
        const SizedBox(width: 16),

        // Community Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      county.isNotEmpty ? '$location, $county' : location,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.people,
                    size: 14,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$memberCount members',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    final description = _getProperty('description', '');

    if (description.isEmpty) return const SizedBox.shrink();

    return Text(
      description,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.white70,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTags() {
    final tags = _getProperty('tags', <String>[], isList: true);
    final skillLevel = _getProperty('skillLevel', '');

    List<String> displayTags = [];

    // Add skill level if available
    if (skillLevel.isNotEmpty) {
      displayTags.add(skillLevel);
    }

    // Add up to 3 additional tags
    displayTags.addAll(tags.take(3));

    if (displayTags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: displayTags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions() {
    final userType = _getProperty('userType', 'fan', fromObject: currentUser);

    return Row(
      children: [
        // Show actions based on user type and community status
        if (isUserCommunity) ...[
          // User's own community - show member status for players, follower status for fans
          if (userType == 'player') ...[
            Flexible(
              child: Container(
                height: 32,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(0.6),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: AppTheme.successColor,
                      size: 14,
                    ),
                    SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        'My Community',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (userType == 'fan') ...[
            // For fans, show following status
            Flexible(
              child: Container(
                height: 32,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.6),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: Colors.blue,
                      size: 14,
                    ),
                    SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        'Following',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ] else ...[
          // Other communities - NO JOIN BUTTONS for players (they can only have one community from registration)
          // Only show follow buttons for fans if they don't already have a community
          if (userType == 'fan' &&
              !userAlreadyHasCommunity &&
              onFollowPressed != null) ...[
            Flexible(
              child: SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: onFollowPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isFollowed ? Colors.blue : AppTheme.accentColor,
                    foregroundColor: isFollowed ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    elevation: 0,
                  ),
                  icon: Icon(
                    isFollowed ? Icons.favorite : Icons.favorite_border,
                    size: 12,
                  ),
                  label: Text(
                    isFollowed ? 'Following' : 'Follow',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],

        // Add spacing only if there's an action button
        if ((isUserCommunity) ||
            (userType == 'fan' &&
                !userAlreadyHasCommunity &&
                onFollowPressed != null))
          const SizedBox(width: 8),

        // View Details Button - always available and clickable
        Flexible(
          child: InkWell(
            onTap: onViewDetails,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Details',
                      style: TextStyle(
                        color: isUserCommunity
                            ? AppTheme.accentColor
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward,
                    color:
                        isUserCommunity ? AppTheme.accentColor : Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods for safe property access
  T _getProperty<T>(String property, T defaultValue,
      {dynamic fromObject, bool isList = false}) {
    try {
      final obj = fromObject ?? community;
      if (obj == null) return defaultValue;

      final value =
          obj is Map ? obj[property] : _getPropertyFromObject(obj, property);

      if (value == null) return defaultValue;
      if (isList && value is! List) return defaultValue;

      return value as T;
    } catch (e) {
      return defaultValue;
    }
  }

  dynamic _getPropertyFromObject(dynamic obj, String property) {
    try {
      switch (property) {
        case 'name':
          return obj.name;
        case 'description':
          return obj.description ?? '';
        case 'location':
          return obj.location ?? '';
        case 'county':
          // Handle both Entity and Model objects
          if (obj.runtimeType.toString().contains('Community')) {
            return obj.county ?? '';
          }
          return '';
        case 'memberCount':
          return obj.memberCount ?? 0;
        case 'followerCount':
          return obj.followerCount ?? 0;
        case 'logoUrl':
          return obj.logoUrl;
        case 'tags':
          return obj.tags ?? <String>[];
        case 'skillLevel':
          return obj.skillLevel ?? '';
        case 'userType':
          return obj.userType ?? 'fan';
        default:
          // Debug print for unknown properties to help troubleshoot
          // print('⚠️ Unknown property "$property" for object: ${obj.runtimeType}');
          return null;
      }
    } catch (e) {
      // Silent fail for property access errors
      return null;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'CC';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }
}
