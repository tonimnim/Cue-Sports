import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';
import '../../domain/entities/community_post.dart';
import '../../../auth/domain/entities/user.dart';
import '../widgets/post_comment_card.dart';

class PostDetailsScreen extends StatefulWidget {
  final CommunityPost post;
  final User currentUser;

  const PostDetailsScreen({
    super.key,
    required this.post,
    required this.currentUser,
  });

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        actions: [
          if (widget.post.authorId == widget.currentUser.id)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/edit-post',
                  arguments: widget.post,
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showPostOptions(context);
            },
          ),
        ],
      ),
      body: BlocListener<CommunityBloc, CommunityState>(
        listener: (context, state) {
          if (state.status == CommunityStatus.loaded && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          } else if (state.status == CommunityStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Unknown error'),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Post Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author Info
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.post.authorId, // TODO: Replace with author name
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.post.isPinned)
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
                        timeago.format(widget.post.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Post Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPostTypeColor(theme).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getPostTypeText(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getPostTypeColor(theme),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Post Title
                    Text(
                      widget.post.title,
                      style: theme.textTheme.headlineSmall,
                    ),

                    const SizedBox(height: 16),

                    // Post Content
                    Text(
                      widget.post.content,
                      style: theme.textTheme.bodyMedium,
                    ),

                    // Post Attachments
                    if (widget.post.hasAttachments) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.post.attachments!.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.post.attachments![index],
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // Post Tags
                    if (widget.post.hasTags) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: widget.post.tags!.map((tag) {
                          return Chip(
                            label: Text(
                              '#$tag',
                              style: theme.textTheme.labelSmall,
                            ),
                            padding: const EdgeInsets.all(4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Post Actions
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            if (widget.post.likes.contains(widget.currentUser.id)) {
                              context.read<CommunityBloc>().add(
                                    UnlikePostEvent(
                                      postId: widget.post.id,
                                      userId: widget.currentUser.id,
                                    ),
                                  );
                            } else {
                              context.read<CommunityBloc>().add(
                                    LikePostEvent(
                                      postId: widget.post.id,
                                      userId: widget.currentUser.id,
                                    ),
                                  );
                            }
                          },
                          icon: Icon(
                            widget.post.likes.contains(widget.currentUser.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 20,
                            color: widget.post.likes.contains(widget.currentUser.id)
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          label: Text(
                            widget.post.likeCount.toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: widget.post.likes.contains(widget.currentUser.id)
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            _focusNode.requestFocus();
                          },
                          icon: const Icon(Icons.comment_outlined, size: 20),
                          label: Text(
                            widget.post.commentCount.toString(),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            // TODO: Implement share functionality
                          },
                          icon: const Icon(Icons.share_outlined, size: 20),
                          label: const Text('Share'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Comments Section
                    Text(
                      'Comments',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    // TODO: Implement comments list
                  ],
                ),
              ),
            ),

            // Comment Input
            if (!widget.post.isLocked)
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: theme.dividerColor,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _focusNode,
                          decoration: const InputDecoration(
                            hintText: 'Write a comment...',
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _commentController.text.trim().isEmpty
                            ? null
                            : () {
                                // TODO: Implement add comment
                                _commentController.clear();
                              },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    final isAuthor = widget.post.authorId == widget.currentUser.id;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAuthor) ...[
                ListTile(
                  leading: Icon(
                    widget.post.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  ),
                  title: Text(
                    widget.post.isPinned ? 'Unpin Post' : 'Pin Post',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.post.isPinned) {
                      context.read<CommunityBloc>().add(
                            UnpinPostEvent(postId: widget.post.id),
                          );
                    } else {
                      context.read<CommunityBloc>().add(
                            PinPostEvent(postId: widget.post.id),
                          );
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    widget.post.isLocked ? Icons.lock_open : Icons.lock,
                  ),
                  title: Text(
                    widget.post.isLocked ? 'Unlock Comments' : 'Lock Comments',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement lock/unlock comments
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Delete Post'),
                  textColor: Theme.of(context).colorScheme.error,
                  iconColor: Theme.of(context).colorScheme.error,
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Post'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement share functionality
                },
              ),
              if (!isAuthor)
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text('Report Post'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement report functionality
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement delete post
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

  Color _getPostTypeColor(ThemeData theme) {
    switch (widget.post.type) {
      case PostType.text:
        return theme.colorScheme.primary;
      case PostType.announcement:
        return theme.colorScheme.error;
      case PostType.event:
        return theme.colorScheme.tertiary;
      case PostType.discussion:
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _getPostTypeText() {
    switch (widget.post.type) {
      case PostType.text:
        return 'Text Post';
      case PostType.announcement:
        return 'Announcement';
      case PostType.event:
        return 'Event Post';
      case PostType.discussion:
        return 'Discussion';
      default:
        return 'Post';
    }
  }
} 