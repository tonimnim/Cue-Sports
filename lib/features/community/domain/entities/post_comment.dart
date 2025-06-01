import 'package:equatable/equatable.dart';

/// Domain entity representing a comment on a post
class PostComment extends Equatable {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String>? attachments;
  final List<String> likes;
  final List<String>? replies;

  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.attachments,
    this.likes = const [],
    this.replies,
  });

  /// Check if the comment has been edited
  bool get isEdited => updatedAt != null;

  /// Check if the comment has any likes
  bool get hasLikes => likes.isNotEmpty;

  /// Get the like count
  int get likeCount => likes.length;

  /// Check if a user has liked this comment
  bool isLikedBy(String userId) => likes.contains(userId);

  /// Check if the comment has any attachments
  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;

  /// Check if the comment has any replies
  bool get hasReplies => replies != null && replies!.isNotEmpty;

  /// Get the reply count
  int get replyCount => replies?.length ?? 0;

  /// Create a copy of this PostComment with some fields updated
  PostComment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? attachments,
    List<String>? likes,
    List<String>? replies,
  }) {
    return PostComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
      likes: likes ?? this.likes,
      replies: replies ?? this.replies,
    );
  }

  @override
  List<Object?> get props => [
        id,
        postId,
        authorId,
        content,
        createdAt,
        updatedAt,
        attachments,
        likes,
        replies,
      ];
} 