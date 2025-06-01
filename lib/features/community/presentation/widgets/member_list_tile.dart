import 'package:flutter/material.dart';
import '../../domain/entities/community_member.dart';

class MemberListTile extends StatelessWidget {
  final CommunityMember member;
  final bool isAdmin;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const MemberListTile({
    super.key,
    required this.member,
    this.isAdmin = false,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: member.profileImageUrl != null
            ? NetworkImage(member.profileImageUrl!)
            : null,
        child: member.profileImageUrl == null
            ? Text(
                member.displayName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Admin',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rank: ${member.rank}',
            style: theme.textTheme.bodySmall,
          ),
          if (member.hasBadges)
            Wrap(
              spacing: 4,
              children: member.badges!.map((badge) {
                return Chip(
                  label: Text(
                    badge,
                    style: theme.textTheme.labelSmall,
                  ),
                  padding: const EdgeInsets.all(4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
        ],
      ),
      trailing: onRemove != null
          ? IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: theme.colorScheme.error,
              onPressed: onRemove,
            )
          : null,
      onTap: onTap,
    );
  }
} 