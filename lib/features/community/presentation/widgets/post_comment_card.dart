import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/entities/post_comment.dart';

class PostCommentCard extends StatelessWidget {
  final PostComment comment;
  final bool isAuthor;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  const PostCommentCard({
    super.key,
    required this.comment,
    this.isAuthor = false,
    this.onDelete,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Info
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorId, // TODO: Replace with author name
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        timeago.format(comment.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isAuthor || onReport != null)
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      if (isAuthor)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      if (onReport != null)
                        const PopupMenuItem(
                          value: 'report',
                          child: Text('Report'),
                        ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'delete':
                          onDelete?.call();
                          break;
                        case 'report':
                          onReport?.call();
                          break;
                      }
                    },
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Comment Content
            Text(
              comment.content,
              style: theme.textTheme.bodyMedium,
            ),

            // Comment Attachments
            if (comment.hasAttachments) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: comment.attachments!.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        comment.attachments![index],
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 