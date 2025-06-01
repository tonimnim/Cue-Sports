import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/entities/community_post.dart';

class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      post.authorId, // TODO: Replace with author name
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (post.isPinned)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.push_pin,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                timeago.format(post.createdAt),
                style: theme.textTheme.bodySmall,
              ),
              trailing: PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: Text('Report'),
                  ),
                  if (post.isEdited)
                    const PopupMenuItem(
                      value: 'history',
                      child: Text('View Edit History'),
                    ),
                ],
                onSelected: (value) {
                  // TODO: Handle menu actions
                },
              ),
            ),

            // Post Type Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getPostTypeColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post.type.toString().split('.').last.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getPostTypeColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Post Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Post Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Post Attachments
            if (post.hasAttachments) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: post.attachments!.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.attachments![index],
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ],

            // Post Tags
            if (post.hasTags) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: post.tags!.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Chip(
                      label: Text(
                        '#${post.tags![index]}',
                        style: theme.textTheme.labelSmall,
                      ),
                      padding: const EdgeInsets.all(4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  },
                ),
              ),
            ],

            // Post Actions
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // Like Button
                  TextButton.icon(
                    onPressed: onLike,
                    icon: Icon(
                      post.hasLikes ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: post.hasLikes ? theme.colorScheme.primary : null,
                    ),
                    label: Text(
                      post.likeCount.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: post.hasLikes ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ),
                  // Comment Button
                  TextButton.icon(
                    onPressed: onComment,
                    icon: const Icon(Icons.comment_outlined, size: 20),
                    label: Text(
                      post.commentCount.toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  // Share Button
                  TextButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined, size: 20),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPostTypeColor(BuildContext context) {
    switch (post.type) {
      case PostType.text:
        return Theme.of(context).colorScheme.primary;
      case PostType.announcement:
        return Theme.of(context).colorScheme.error;
      case PostType.event:
        return Theme.of(context).colorScheme.secondary;
      case PostType.discussion:
        return Theme.of(context).colorScheme.tertiary;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
} 