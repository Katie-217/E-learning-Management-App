// ========================================
// FILE: material_model.dart
// MÔ TẢ: Model tài liệu học tập
// ========================================

class MaterialModel {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final MaterialType type;
  final String? url; // Link tài liệu hoặc file URL
  final String? filePath; // Đường dẫn file local
  final AttachmentModel? attachment; // File đính kèm
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPublished;
  final List<String> targetGroupIds; // Nếu rỗng = cho tất cả
  final int downloadCount;

  const MaterialModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.type,
    this.url,
    this.filePath,
    this.attachment,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
    this.isPublished = true,
    this.targetGroupIds = const [],
    this.downloadCount = 0,
  });

  // ========================================
  // HÀM: fromMap()
  // MÔ TẢ: Tạo MaterialModel từ Map (Firebase data)
  // ========================================
  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      id: map['id'] ?? '',
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      type: _parseMaterialType(map['type'] ?? 'document'),
      url: map['url'],
      filePath: map['filePath'],
      attachment: map['attachment'] != null
          ? AttachmentModel.fromMap(map['attachment'] as Map<String, dynamic>)
          : null,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']),
      isPublished: map['isPublished'] ?? true,
      targetGroupIds: List<String>.from(map['targetGroupIds'] ?? []),
      downloadCount: map['downloadCount'] ?? 0,
    );
  }

  // ========================================
  // HÀM: toMap()
  // MÔ TẢ: Chuyển MaterialModel thành Map để lưu Firebase
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'type': type.name,
      'url': url,
      'filePath': filePath,
      'attachment': attachment?.toMap(),
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isPublished': isPublished,
      'targetGroupIds': targetGroupIds,
      'downloadCount': downloadCount,
    };
  }

  // ========================================
  // HÀM: copyWith()
  // MÔ TẢ: Tạo bản sao với một số field thay đổi
  // ========================================
  MaterialModel copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    MaterialType? type,
    String? url,
    String? filePath,
    AttachmentModel? attachment,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
    List<String>? targetGroupIds,
    int? downloadCount,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      attachment: attachment ?? this.attachment,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
      targetGroupIds: targetGroupIds ?? this.targetGroupIds,
      downloadCount: downloadCount ?? this.downloadCount,
    );
  }

  // ========================================
  // GETTER: hasAttachment
  // MÔ TẢ: Kiểm tra có file đính kèm không
  // ========================================
  bool get hasAttachment => attachment != null;

  // ========================================
  // GETTER: hasUrl
  // MÔ TẢ: Kiểm tra có URL link không
  // ========================================
  bool get hasUrl => url != null && url!.isNotEmpty;

  // ========================================
  // GETTER: isForAllGroups
  // MÔ TẢ: Kiểm tra tài liệu có dành cho tất cả nhóm không
  // ========================================
  bool get isForAllGroups => targetGroupIds.isEmpty;

  // ========================================
  // HÀM: incrementDownloadCount()
  // MÔ TẢ: Tăng số lần download
  // ========================================
  MaterialModel incrementDownloadCount() {
    return copyWith(downloadCount: downloadCount + 1);
  }

  // ========================================
  // HÀM: _parseMaterialType()
  // MÔ TẢ: Parse MaterialType từ string
  // ========================================
  static MaterialType _parseMaterialType(String type) {
    switch (type.toLowerCase()) {
      case 'document':
        return MaterialType.document;
      case 'presentation':
        return MaterialType.presentation;
      case 'video':
        return MaterialType.video;
      case 'audio':
        return MaterialType.audio;
      case 'link':
        return MaterialType.link;
      case 'ebook':
        return MaterialType.ebook;
      default:
        return MaterialType.other;
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
    return 'MaterialModel(id: $id, title: $title, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaterialModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ========================================
// ENUM: MaterialType
// MÔ TẢ: Loại tài liệu
// ========================================
enum MaterialType {
  document, // Tài liệu
  presentation, // Slide thuyết trình
  video, // Video
  audio, // Audio
  link, // Link website
  ebook, // Sách điện tử
  other, // Khác
}

extension MaterialTypeExtension on MaterialType {
  String get displayName {
    switch (this) {
      case MaterialType.document:
        return 'Tài liệu';
      case MaterialType.presentation:
        return 'Slide thuyết trình';
      case MaterialType.video:
        return 'Video';
      case MaterialType.audio:
        return 'Audio';
      case MaterialType.link:
        return 'Link website';
      case MaterialType.ebook:
        return 'Sách điện tử';
      case MaterialType.other:
        return 'Khác';
    }
  }

  String get name {
    switch (this) {
      case MaterialType.document:
        return 'document';
      case MaterialType.presentation:
        return 'presentation';
      case MaterialType.video:
        return 'video';
      case MaterialType.audio:
        return 'audio';
      case MaterialType.link:
        return 'link';
      case MaterialType.ebook:
        return 'ebook';
      case MaterialType.other:
        return 'other';
    }
  }

  static MaterialType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'document':
        return MaterialType.document;
      case 'presentation':
        return MaterialType.presentation;
      case 'video':
        return MaterialType.video;
      case 'audio':
        return MaterialType.audio;
      case 'link':
        return MaterialType.link;
      case 'ebook':
        return MaterialType.ebook;
      default:
        return MaterialType.other;
    }
  }
}

// ========================================
// CLASS: AttachmentModel
// MÔ TẢ: Tái sử dụng từ announcement_model.dart
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
