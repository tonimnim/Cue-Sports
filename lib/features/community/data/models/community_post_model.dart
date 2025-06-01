import '../../domain/entities/community_post.dart';

/// Model class for community posts
class CommunityPostModel extends CommunityPost {
  const CommunityPostModel({
    required String id,
    required String communityId,
    required String authorId,
    required String title,
    required String content,
    PostType type = PostType.text,
    required List<String> attachments,
    required List<String> imageUrls,
    required List<String> tags,
    required List<String> likes,
    required List<String> likedBy,
    required int likesCount,
    int commentCount = 0,
    required bool isLocked,
    required bool isPinned,
    bool isActive = true,
    bool isEdited = false,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) : super(
          id: id,
          communityId: communityId,
          authorId: authorId,
          title: title,
          content: content,
          type: type,
          attachments: attachments,
          imageUrls: imageUrls,
          tags: tags,
          likes: likes,
          likedBy: likedBy,
          likesCount: likesCount,
          commentCount: commentCount,
          isLocked: isLocked,
          isPinned: isPinned,
          isActive: isActive,
          isEdited: isEdited,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Create a CommunityPostModel from a map
  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: json['id'] as String,
      communityId: json['communityId'] as String,
      authorId: json['authorId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: PostType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => PostType.text,
      ),
      attachments: List<String>.from(json['attachments'] as List? ?? []),
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? []),
      tags: List<String>.from(json['tags'] as List? ?? []),
      likes: List<String>.from(json['likes'] as List? ?? []),
      likedBy: List<String>.from(json['likedBy'] as List? ?? []),
      likesCount: json['likesCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isLocked: json['isLocked'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      isEdited: json['isEdited'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Create a CommunityPostModel from a CommunityPost entity
  factory CommunityPostModel.fromEntity(CommunityPost entity) {
    return CommunityPostModel(
      id: entity.id,
      communityId: entity.communityId,
      authorId: entity.authorId,
      title: entity.title,
      content: entity.content,
      type: entity.type,
      attachments: entity.attachments,
      imageUrls: entity.imageUrls,
      tags: entity.tags,
      likes: entity.likes,
      likedBy: entity.likedBy,
      likesCount: entity.likesCount,
      commentCount: entity.commentCount,
      isLocked: entity.isLocked,
      isPinned: entity.isPinned,
      isActive: entity.isActive,
      isEdited: entity.isEdited,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert to entity (since this extends CommunityPost, it can be used directly)
  CommunityPost toEntity() => this;

  /// Convert the CommunityPostModel to a map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'authorId': authorId,
      'title': title,
      'content': content,
      'type': type.toString().split('.').last,
      'attachments': attachments,
      'imageUrls': imageUrls,
      'tags': tags,
      'likes': likes,
      'likedBy': likedBy,
      'likesCount': likesCount,
      'commentCount': commentCount,
      'isLocked': isLocked,
      'isPinned': isPinned,
      'isActive': isActive,
      'isEdited': isEdited,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy of this model with some fields updated
  CommunityPostModel copyWith({
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
    return CommunityPostModel(
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
} 