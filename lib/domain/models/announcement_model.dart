// ========================================
// FILE: announcement_model.dart
// MÔ TẢ: Model thông báo trong tab Stream
// ========================================

class AnnouncementModel {
  final String id;
  final String courseId;
  final String title;
  final String content; // Rich text content
  final String authorId; // UID của người tạo
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<AttachmentModel> attachments;
  final bool isPublished;
  final bool isPinned; // Ghim thông báo
  final List<String> targetGroupIds; // Nếu rỗng = gửi cho tất cả

  const AnnouncementModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
    this.attachments = const [],
    this.isPublished = true,
    this.isPinned = false,
    this.targetGroupIds = const [],
  });

  // ========================================
  // HÀM: fromMap()
  // MÔ TẢ: Tạo AnnouncementModel từ Map (Firebase data)
  // ========================================
  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    return AnnouncementModel(
      id: map['id'] ?? '',
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']),
      attachments: (map['attachments'] as List<dynamic>?)
              ?.map((item) =>
                  AttachmentModel.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      isPublished: map['isPublished'] ?? true,
      isPinned: map['isPinned'] ?? false,
      targetGroupIds: List<String>.from(map['targetGroupIds'] ?? []),
    );
  }

  // ========================================
  // HÀM: toMap()
  // MÔ TẢ: Chuyển AnnouncementModel thành Map để lưu Firebase
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'attachments':
          attachments.map((attachment) => attachment.toMap()).toList(),
      'isPublished': isPublished,
      'isPinned': isPinned,
      'targetGroupIds': targetGroupIds,
    };
  }

  // ========================================
  // HÀM: copyWith()
  // MÔ TẢ: Tạo bản sao với một số field thay đổi
  // ========================================
  AnnouncementModel copyWith({
    String? id,
    String? courseId,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AttachmentModel>? attachments,
    bool? isPublished,
    bool? isPinned,
    List<String>? targetGroupIds,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
      isPublished: isPublished ?? this.isPublished,
      isPinned: isPinned ?? this.isPinned,
      targetGroupIds: targetGroupIds ?? this.targetGroupIds,
    );
  }

  // ========================================
  // GETTER: hasAttachments
  // MÔ TẢ: Kiểm tra có file đính kèm không
  // ========================================
  bool get hasAttachments => attachments.isNotEmpty;

  // ========================================
  // GETTER: isForAllGroups
  // MÔ TẢ: Kiểm tra thông báo có gửi cho tất cả nhóm không
  // ========================================
  bool get isForAllGroups => targetGroupIds.isEmpty;

  // ========================================
  // GETTER: timeAgo
  // MÔ TẢ: Thời gian tạo thông báo (relative)
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
  // HÀM: _parseDateTime()
  // MÔ TẢ: Parse datetime từ string/dynamic
  // ========================================
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
  String toString() {
    return 'AnnouncementModel(id: $id, title: $title, isPinned: $isPinned)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnnouncementModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ========================================
// CLASS: AttachmentModel
// MÔ TẢ: Model file đính kèm
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

  // ========================================
  // GETTER: fileExtension
  // MÔ TẢ: Lấy phần mở rộng file
  // ========================================
  String get fileExtension {
    return name.split('.').last.toLowerCase();
  }

  // ========================================
  // GETTER: fileSizeFormatted
  // MÔ TẢ: Kích thước file định dạng readable
  // ========================================
  String get fileSizeFormatted {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024)
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ========================================
  // GETTER: isImage
  // MÔ TẢ: Kiểm tra có phải file ảnh không
  // ========================================
  bool get isImage {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    return imageExtensions.contains(fileExtension);
  }

  // ========================================
  // GETTER: isDocument
  // MÔ TẢ: Kiểm tra có phải file tài liệu không
  // ========================================
  bool get isDocument {
    final docExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'];
    return docExtensions.contains(fileExtension);
  }
}
