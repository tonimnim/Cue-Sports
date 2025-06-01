import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/post_comment.dart';

/// Data model class for PostComment with JSON serialization support
class PostCommentModel extends PostComment {
  const PostCommentModel({
    required String id,
    required String postId,
    required String authorId,
    required String content,
    required DateTime createdAt,
    DateTime? updatedAt,
    List<String>? attachments,
    List<String> likes = const [],
    List<String>? replies,
  }) : super(
          id: id,
          postId: postId,
          authorId: authorId,
          content: content,
          createdAt: createdAt,
          updatedAt: updatedAt,
          attachments: attachments,
          likes: likes,
          replies: replies,
        );

  /// Creates a PostCommentModel from JSON data
  factory PostCommentModel.fromJson(Map<String, dynamic> json) {
    return PostCommentModel(
      id: json['id'] as String,
      postId: json['postId'] as String,
      authorId: json['authorId'] as String,
      content: json['content'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      attachments: (json['attachments'] as List<dynamic>?)?.map((e) => e as String).toList(),
      likes: (json['likes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      replies: (json['replies'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  /// Creates a PostCommentModel from a Firestore document
  factory PostCommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostCommentModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  /// Converts the PostCommentModel to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'authorId': authorId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'attachments': attachments,
      'likes': likes,
      'replies': replies,
    };
  }

  /// Creates a copy of this PostCommentModel with some fields updated
  PostCommentModel copyWithModel({
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
    return PostCommentModel(
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
} 