import 'package:equatable/equatable.dart';

/// Type of community post
enum PostType {
  /// Regular text post
  text,
  
  /// Post with an image
  image,
  
  /// Post with a video
  video,
  
  /// Post with a link
  link,
  
  /// Post with a poll
  poll,
  
  /// Announcement post
  announcement,
  
  /// Event post
  event,
  
  /// Discussion post
  discussion,
}

/// Entity representing a community post
class CommunityPost extends Equatable {
  final String id;
  final String communityId;
  final String authorId;
  final String title;
  final String content;
  final PostType type;
  final List<String> attachments;
  final List<String> imageUrls;
  final List<String> tags;
  final List<String> likes;
  final List<String> likedBy;
  final int likesCount;
  final int commentCount;
  final bool isLocked;
  final bool isPinned;
  final bool isActive;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CommunityPost({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.title,
    required this.content,
    this.type = PostType.text,
    required this.attachments,
    required this.imageUrls,
    required this.tags,
    required this.likes,
    required this.likedBy,
    required this.likesCount,
    this.commentCount = 0,
    required this.isLocked,
    required this.isPinned,
    this.isActive = true,
    this.isEdited = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if a user has liked this post
  bool isLikedBy(String userId) => likedBy.contains(userId);

  /// Get the number of likes
  int get likeCount => likesCount;

  /// Check if post has likes
  bool get hasLikes => likesCount > 0;

  /// Check if post has attachments
  bool get hasAttachments => attachments.isNotEmpty;

  /// Check if post has images
  bool get hasImages => imageUrls.isNotEmpty;

  /// Check if post has tags
  bool get hasTags => tags.isNotEmpty;

  /// Create a copy of this post with some fields updated
  CommunityPost copyWith({
    String? id,
    String? communityId,
    String? authorId,
    String? title,
    String? content,
    PostType? type,
    List<String>? attachments,
    List<String>? imageUrls,
    List<String>? tags,
    List<String>? likes,
    List<String>? likedBy,
    int? likesCount,
    int? commentCount,
    bool? isLocked,
    bool? isPinned,
    bool? isActive,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      attachments: attachments ?? this.attachments,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      likesCount: likesCount ?? this.likesCount,
      commentCount: commentCount ?? this.commentCount,
      isLocked: isLocked ?? this.isLocked,
      isPinned: isPinned ?? this.isPinned,
      isActive: isActive ?? this.isActive,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        communityId,
        authorId,
        title,
        content,
        type,
        attachments,
        imageUrls,
        tags,
        likes,
        likedBy,
        likesCount,
        commentCount,
        isLocked,
        isPinned,
        isActive,
        isEdited,
        createdAt,
        updatedAt,
      ];
} 