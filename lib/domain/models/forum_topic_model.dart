// ========================================
// FILE: forum_topic_model.dart
// MÔ TẢ: Model chủ đề trong diễn đàn
// ========================================

class ForumTopicModel {
  final String id;
  final String courseId;
  final String title;
  final String content;
  final ForumTopicType type;
  final String authorId;
  final String authorName;
  final String authorRole;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<AttachmentModel> attachments;
  final bool isPinned;
  final bool isLocked;
  final bool isResolved; // Cho Q&A topics
  final int viewCount;
  final int replyCount;
  final DateTime? lastReplyAt;
  final String? lastReplyBy;
  final List<String> tags;
  final ForumTopicStatus status;

  const ForumTopicModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.type,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
    this.updatedAt,
    this.attachments = const [],
    this.isPinned = false,
    this.isLocked = false,
    this.isResolved = false,
    this.viewCount = 0,
    this.replyCount = 0,
    this.lastReplyAt,
    this.lastReplyBy,
    this.tags = const [],
    this.status = ForumTopicStatus.active,
  });

  factory ForumTopicModel.fromMap(Map<String, dynamic> map) {
    return ForumTopicModel(
      id: map['id'] ?? '',
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      type: _parseTopicType(map['type'] ?? 'discussion'),
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorRole: map['authorRole'] ?? 'student',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']),
      attachments: (map['attachments'] as List<dynamic>?)
              ?.map((item) =>
                  AttachmentModel.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      isPinned: map['isPinned'] ?? false,
      isLocked: map['isLocked'] ?? false,
      isResolved: map['isResolved'] ?? false,
      viewCount: map['viewCount'] ?? 0,
      replyCount: map['replyCount'] ?? 0,
      lastReplyAt: _parseDateTime(map['lastReplyAt']),
      lastReplyBy: map['lastReplyBy'],
      tags: List<String>.from(map['tags'] ?? []),
      status: _parseStatus(map['status'] ?? 'active'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'content': content,
      'type': type.name,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'attachments':
          attachments.map((attachment) => attachment.toMap()).toList(),
      'isPinned': isPinned,
      'isLocked': isLocked,
      'isResolved': isResolved,
      'viewCount': viewCount,
      'replyCount': replyCount,
      'lastReplyAt': lastReplyAt?.toIso8601String(),
      'lastReplyBy': lastReplyBy,
      'tags': tags,
      'status': status.name,
    };
  }

  ForumTopicModel copyWith({
    String? id,
    String? courseId,
    String? title,
    String? content,
    ForumTopicType? type,
    String? authorId,
    String? authorName,
    String? authorRole,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AttachmentModel>? attachments,
    bool? isPinned,
    bool? isLocked,
    bool? isResolved,
    int? viewCount,
    int? replyCount,
    DateTime? lastReplyAt,
    String? lastReplyBy,
    List<String>? tags,
    ForumTopicStatus? status,
  }) {
    return ForumTopicModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      isResolved: isResolved ?? this.isResolved,
      viewCount: viewCount ?? this.viewCount,
      replyCount: replyCount ?? this.replyCount,
      lastReplyAt: lastReplyAt ?? this.lastReplyAt,
      lastReplyBy: lastReplyBy ?? this.lastReplyBy,
      tags: tags ?? this.tags,
      status: status ?? this.status,
    );
  }

  // ========================================
  // GETTER: hasAttachments
  // ========================================
  bool get hasAttachments => attachments.isNotEmpty;

  // ========================================
  // GETTER: hasReplies
  // ========================================
  bool get hasReplies => replyCount > 0;

  // ========================================
  // HÀM: incrementViewCount()
  // ========================================
  ForumTopicModel incrementViewCount() {
    return copyWith(viewCount: viewCount + 1);
  }

  // ========================================
  // HÀM: addReply()
  // ========================================
  ForumTopicModel addReply(String replyById) {
    return copyWith(
      replyCount: replyCount + 1,
      lastReplyAt: DateTime.now(),
      lastReplyBy: replyById,
    );
  }

  static ForumTopicType _parseTopicType(String type) {
    switch (type.toLowerCase()) {
      case 'discussion':
        return ForumTopicType.discussion;
      case 'question':
        return ForumTopicType.question;
      case 'announcement':
        return ForumTopicType.announcement;
      case 'resource':
        return ForumTopicType.resource;
      default:
        return ForumTopicType.discussion;
    }
  }

  static ForumTopicStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return ForumTopicStatus.active;
      case 'closed':
        return ForumTopicStatus.closed;
      case 'archived':
        return ForumTopicStatus.archived;
      default:
        return ForumTopicStatus.active;
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
  String toString() => 'ForumTopicModel(id: $id, title: $title, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForumTopicModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ========================================
// ENUM: ForumTopicType
// ========================================
enum ForumTopicType {
  discussion, // Thảo luận chung
  question, // Câu hỏi
  announcement, // Thông báo
  resource, // Chia sẻ tài liệu
}

extension ForumTopicTypeExtension on ForumTopicType {
  String get displayName {
    switch (this) {
      case ForumTopicType.discussion:
        return 'Thảo luận';
      case ForumTopicType.question:
        return 'Câu hỏi';
      case ForumTopicType.announcement:
        return 'Thông báo';
      case ForumTopicType.resource:
        return 'Tài liệu';
    }
  }

  String get name {
    switch (this) {
      case ForumTopicType.discussion:
        return 'discussion';
      case ForumTopicType.question:
        return 'question';
      case ForumTopicType.announcement:
        return 'announcement';
      case ForumTopicType.resource:
        return 'resource';
    }
  }
}

// ========================================
// ENUM: ForumTopicStatus
// ========================================
enum ForumTopicStatus {
  active, // Đang hoạt động
  closed, // Đã đóng
  archived, // Đã lưu trữ
}

extension ForumTopicStatusExtension on ForumTopicStatus {
  String get displayName {
    switch (this) {
      case ForumTopicStatus.active:
        return 'Hoạt động';
      case ForumTopicStatus.closed:
        return 'Đã đóng';
      case ForumTopicStatus.archived:
        return 'Lưu trữ';
    }
  }

  String get name {
    switch (this) {
      case ForumTopicStatus.active:
        return 'active';
      case ForumTopicStatus.closed:
        return 'closed';
      case ForumTopicStatus.archived:
        return 'archived';
    }
  }
}

// ========================================
// CLASS: AttachmentModel (Reused)
// ========================================
class AttachmentModel {
  final String id;
  final String name;
  final String url;
  final String mimeType;
  final int sizeInBytes;
  final DateTime uploadedAt;

  const AttachmentModel({
    required this.id,
    required this.name,
    required this.url,
    required this.mimeType,
    required this.sizeInBytes,
    required this.uploadedAt,
  });

  factory AttachmentModel.fromMap(Map<String, dynamic> map) {
    return AttachmentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      mimeType: map['mimeType'] ?? '',
      sizeInBytes: map['sizeInBytes'] ?? 0,
      uploadedAt:
          DateTime.parse(map['uploadedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'mimeType': mimeType,
      'sizeInBytes': sizeInBytes,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}
