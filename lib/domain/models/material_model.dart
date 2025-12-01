// ========================================
// FILE: material_model.dart
// MÔ TẢ: Model tài liệu học tập
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialModel {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final String? url; // Link tài liệu hoặc file URL
  final String? filePath; // Đường dẫn file local
  final AttachmentModel? attachment; // File đính kèm
  final LinkMetadataModel?
      linkMetadata; // Metadata của link (title, image, description)
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPublished;

  const MaterialModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.url,
    this.filePath,
    this.attachment,
    this.linkMetadata,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
    this.isPublished = true,
  });

  // ========================================
  // HÀM: fromFirestore()
  // MÔ TẢ: Tạo MaterialModel từ Firestore DocumentSnapshot
  // ========================================
  factory MaterialModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse dates - handle both Timestamp and DateTime
    DateTime? parseDate(dynamic dateData) {
      if (dateData == null) {
        return null;
      }
      if (dateData is Timestamp) {
        return dateData.toDate();
      }
      if (dateData is DateTime) {
        return dateData;
      }
      try {
        return DateTime.parse(dateData.toString());
      } catch (e) {
        return null;
      }
    }

    // Helper to build attachment from Map
    AttachmentModel? buildAttachmentFromMap(Map<String, dynamic>? map) {
      if (map == null) return null;
      try {
        return AttachmentModel(
          id: map['id']?.toString() ?? map['fileId']?.toString() ?? doc.id,
          name: map['name']?.toString() ??
              map['fileName']?.toString() ??
              'Attachment',
          url: map['url']?.toString() ?? '',
          mimeType: map['mimeType']?.toString() ??
              map['type']?.toString() ??
              'application/octet-stream',
          sizeInBytes: (map['sizeInBytes'] as int?) ??
              (map['size'] as int?) ??
              ((map['sizeInBytes'] as num?)?.toInt()) ??
              ((map['size'] as num?)?.toInt()) ??
              0,
          uploadedAt: parseDate(map['uploadedAt']) ??
              parseDate(data['createdAt']) ??
              DateTime.now(),
        );
      } catch (e) {
        return null;
      }
    }

    // Parse attachment - hỗ trợ nhiều định dạng ('attachment', 'files', 'attachments')
    AttachmentModel? attachment = buildAttachmentFromMap(
        (data['attachment'] as Map?)?.cast<String, dynamic>());

    if (attachment == null && data['files'] != null) {
      attachment = buildAttachmentFromMap(
          (data['files'] as Map?)?.cast<String, dynamic>());
    }

    if (attachment == null && data['attachments'] != null) {
      final attachmentsData = data['attachments'];
      if (attachmentsData is List && attachmentsData.isNotEmpty) {
        final firstAttachment = attachmentsData.first;
        if (firstAttachment is Map<String, dynamic>) {
          attachment = buildAttachmentFromMap(firstAttachment);
        } else if (firstAttachment is Map) {
          attachment =
              buildAttachmentFromMap(firstAttachment.cast<String, dynamic>());
        }
      }
    }

    // Lấy title từ nhiều field khác nhau
    String title = data['title']?.toString() ??
        (data['files'] != null && data['files'] is Map
            ? (data['files'] as Map)['title']?.toString()
            : null) ??
        (data['name']?.toString()) ??
        'Untitled Material';

    // Lấy description từ nhiều field (description, details, content)
    String? description = data['description']?.toString();
    description ??= data['details']?.toString();
    description ??= data['content']?.toString();

    // Lấy URL từ files.url hoặc data.url
    String? url = data['url']?.toString() ??
        (data['files'] != null && data['files'] is Map
            ? (data['files'] as Map)['url']?.toString()
            : null);

    // Parse linkMetadata nếu có
    LinkMetadataModel? linkMetadata;
    if (data['linkMetadata'] != null && data['linkMetadata'] is Map) {
      linkMetadata = LinkMetadataModel.fromMap(
          (data['linkMetadata'] as Map).cast<String, dynamic>());
    }

    return MaterialModel(
      id: doc.id,
      courseId: data['courseId']?.toString() ??
          '', // Có thể cần lấy từ parent collection
      title: title,
      description: description,
      url: url,
      filePath: data['filePath']?.toString(),
      attachment: attachment,
      linkMetadata: linkMetadata,
      authorId: data['authorId']?.toString() ?? '',
      authorName: data['authorName']?.toString() ?? '',
      createdAt: parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(data['updatedAt']),
      isPublished:
          data['isPublished'] ?? true, // Default true nếu không có field
    );
  }

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
      url: map['url'],
      filePath: map['filePath'],
      attachment: map['attachment'] != null
          ? AttachmentModel.fromMap(map['attachment'] as Map<String, dynamic>)
          : null,
      linkMetadata: map['linkMetadata'] != null
          ? LinkMetadataModel.fromMap(
              map['linkMetadata'] as Map<String, dynamic>)
          : null,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']),
      isPublished: map['isPublished'] ?? true,
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
      'url': url,
      'filePath': filePath,
      'attachment': attachment?.toMap(),
      'linkMetadata': linkMetadata?.toMap(),
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isPublished': isPublished,
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
    String? url,
    String? filePath,
    AttachmentModel? attachment,
    LinkMetadataModel? linkMetadata,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      attachment: attachment ?? this.attachment,
      linkMetadata: linkMetadata ?? this.linkMetadata,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
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

  @override
  String toString() {
    return 'MaterialModel(id: $id, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaterialModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

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
}

// ========================================
// CLASS: LinkMetadataModel
// MÔ TẢ: Metadata của link (title, imageUrl, description, domain)
// ========================================
class LinkMetadataModel {
  final String url;
  final String title;
  final String? imageUrl;
  final String? description;
  final String domain;

  const LinkMetadataModel({
    required this.url,
    required this.title,
    this.imageUrl,
    this.description,
    required this.domain,
  });

  factory LinkMetadataModel.fromMap(Map<String, dynamic> map) {
    return LinkMetadataModel(
      url: map['url'] ?? '',
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'],
      description: map['description'],
      domain: map['domain'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'title': title,
      'imageUrl': imageUrl,
      'description': description,
      'domain': domain,
    };
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
