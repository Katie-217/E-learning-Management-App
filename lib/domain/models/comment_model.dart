// ========================================
// FILE: comment_model.dart
// MÔ TẢ: Model bình luận đơn giản dưới Announcement (SIMPLIFIED)
// NOTE: Bỏ Reply và Like logic - dành cho Forum
// ========================================

class CommentModel {
  final String id;
  final String announcementId; // ID của announcement mẹ
  final String courseId;
  final String content;
  final String authorId;
  final String authorName;
  final String authorRole; // 'instructor' hoặc 'student'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final bool isDeleted;

  const CommentModel({
    required this.id,
    required this.announcementId,
    required this.courseId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.isDeleted = false,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      announcementId: map['announcementId'] ?? '',
      courseId: map['courseId'] ?? '',
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorRole: map['authorRole'] ?? 'student',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']),
      isEdited: map['isEdited'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'announcementId': announcementId,
      'courseId': courseId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isEdited': isEdited,
      'isDeleted': isDeleted,
    };
  }

  CommentModel copyWith({
    String? id,
    String? announcementId,
    String? courseId,
    String? content,
    String? authorId,
    String? authorName,
    String? authorRole,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    bool? isDeleted,
  }) {
    return CommentModel(
      id: id ?? this.id,
      announcementId: announcementId ?? this.announcementId,
      courseId: courseId ?? this.courseId,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

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
      'CommentModel(id: $id, authorName: $authorName, announcementId: $announcementId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
