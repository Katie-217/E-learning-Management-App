// ========================================
// FILE: comment_model.dart
// MÔ TẢ: Model bình luận ngắn dưới Announcement
// ========================================

class CommentModel {
  final String id;
  final String parentId; // ID của announcement hoặc comment cha
  final String parentType; // 'announcement' hoặc 'comment'
  final String courseId;
  final String content;
  final String authorId;
  final String authorName;
  final String authorRole; // 'instructor' hoặc 'student'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final List<String> replyIds; // IDs của replies
  final int likeCount;
  final List<String> likedBy; // UIDs của người like
  final bool isDeleted;

  const CommentModel({
    required this.id,
    required this.parentId,
    required this.parentType,
    required this.courseId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.replyIds = const [],
    this.likeCount = 0,
    this.likedBy = const [],
    this.isDeleted = false,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      parentId: map['parentId'] ?? '',
      parentType: map['parentType'] ?? 'announcement',
      courseId: map['courseId'] ?? '',
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorRole: map['authorRole'] ?? 'student',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']),
      isEdited: map['isEdited'] ?? false,
      replyIds: List<String>.from(map['replyIds'] ?? []),
      likeCount: map['likeCount'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'parentType': parentType,
      'courseId': courseId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isEdited': isEdited,
      'replyIds': replyIds,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'isDeleted': isDeleted,
    };
  }

  CommentModel copyWith({
    String? id,
    String? parentId,
    String? parentType,
    String? courseId,
    String? content,
    String? authorId,
    String? authorName,
    String? authorRole,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    List<String>? replyIds,
    int? likeCount,
    List<String>? likedBy,
    bool? isDeleted,
  }) {
    return CommentModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      parentType: parentType ?? this.parentType,
      courseId: courseId ?? this.courseId,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      replyIds: replyIds ?? this.replyIds,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // ========================================
  // GETTER: hasReplies
  // ========================================
  bool get hasReplies => replyIds.isNotEmpty;

  // ========================================
  // GETTER: timeAgo
  // ========================================
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  // ========================================
  // HÀM: isLikedBy()
  // ========================================
  bool isLikedBy(String userId) => likedBy.contains(userId);

  // ========================================
  // HÀM: toggleLike()
  // ========================================
  CommentModel toggleLike(String userId) {
    final isCurrentlyLiked = isLikedBy(userId);
    final updatedLikedBy = [...likedBy];

    if (isCurrentlyLiked) {
      updatedLikedBy.remove(userId);
    } else {
      updatedLikedBy.add(userId);
    }

    return copyWith(
      likedBy: updatedLikedBy,
      likeCount: updatedLikedBy.length,
    );
  }

  static DateTime? _parseDateTime(dynamic dateData) {
    if (dateData == null) return null;
    if (dateData is DateTime) return dateData;
    try {
      return DateTime.parse(dateData.toString());
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() =>
      'CommentModel(id: $id, authorName: $authorName, parentType: $parentType)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
