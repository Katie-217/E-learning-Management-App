// ========================================
// FILE: submission_model.dart
// MÔ TẢ: Model nộp bài của sinh viên
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String courseId;
  final String
      semesterId; // ✅ NEW: Root Collection support - semester filtering
  final String groupId; // ✅ NEW: Root Collection support - group filtering
  final DateTime submittedAt;
  final SubmissionStatus status;
  final List<AttachmentModel> attachments;
  final String? textContent; // Nội dung text nếu có
  final double? score; // Điểm số (nullable khi chưa chấm)
  final double? maxScore; // Điểm tối đa
  final String? feedback; // Phản hồi từ giảng viên
  final String? gradedBy; // UID của người chấm điểm
  final DateTime? gradedAt; // Thời gian chấm điểm
  final bool isLate; // Nộp muộn
  final int attemptNumber; // Lần nộp thứ mấy
  final DateTime? lastModified;

  const SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.semesterId, // ✅ REQUIRED: Root Collection support
    required this.groupId, // ✅ REQUIRED: Root Collection support
    required this.submittedAt,
    required this.status,
    this.attachments = const [],
    this.textContent,
    this.score,
    this.maxScore,
    this.feedback,
    this.gradedBy,
    this.gradedAt,
    this.isLate = false,
    this.attemptNumber = 1,
    this.lastModified,
  });

  // ========================================
  // HÀM: fromMap()
  // MÔ TẢ: Tạo SubmissionModel từ Map (Firebase data)
  // ========================================
  factory SubmissionModel.fromMap(Map<String, dynamic> map) {
    final attachments = _parseAttachments(map['attachments']);
    final submittedAt = _parseDateTime(map['submittedAt']);

    final submission = SubmissionModel(
      id: map['id'] ?? '',
      assignmentId: map['assignmentId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      courseId: map['courseId'] ?? '',
      semesterId: map['semesterId'] ?? '', // ✅ Read semesterId from Firebase
      groupId: map['groupId'] ?? '', // ✅ Read groupId from Firebase
      submittedAt: submittedAt ?? DateTime.now(),
      status: _parseStatus(map['status'] ?? 'submitted'),
      attachments: attachments,
      textContent: map['textContent'],
      score: map['score']?.toDouble(),
      maxScore: map['maxScore']?.toDouble(),
      feedback: map['feedback'],
      gradedBy: map['gradedBy'],
      gradedAt: _parseDateTime(map['gradedAt']),
      isLate: map['isLate'] ?? false,
      attemptNumber: (map['attemptNumber'] as int?) ?? 1,
      lastModified: _parseDateTime(map['lastModified']),
    );

    return submission;
  }

  // ========================================
  // HÀM: toMap()
  // MÔ TẢ: Chuyển SubmissionModel thành Map để lưu Firebase
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'semesterId': semesterId, // ✅ Write semesterId to Firebase
      'groupId': groupId, // ✅ Write groupId to Firebase
      'submittedAt': submittedAt.toIso8601String(),
      'status': status.name,
      'attachments':
          attachments.map((attachment) => attachment.toMap()).toList(),
      'textContent': textContent,
      'score': score,
      'maxScore': maxScore,
      'feedback': feedback,
      'gradedBy': gradedBy,
      'gradedAt': gradedAt?.toIso8601String(),
      'isLate': isLate,
      'attemptNumber': attemptNumber,
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  // ========================================
  // HÀM: copyWith()
  // MÔ TẢ: Tạo bản sao với một số field thay đổi
  // ========================================
  SubmissionModel copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? studentName,
    String? courseId,
    String? semesterId, // ✅ Support semesterId updates
    String? groupId, // ✅ Support groupId updates
    DateTime? submittedAt,
    SubmissionStatus? status,
    List<AttachmentModel>? attachments,
    String? textContent,
    double? score,
    double? maxScore,
    String? feedback,
    String? gradedBy,
    DateTime? gradedAt,
    bool? isLate,
    int? attemptNumber,
    DateTime? lastModified,
  }) {
    return SubmissionModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      groupId: groupId ?? this.groupId,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      textContent: textContent ?? this.textContent,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      feedback: feedback ?? this.feedback,
      gradedBy: gradedBy ?? this.gradedBy,
      gradedAt: gradedAt ?? this.gradedAt,
      isLate: isLate ?? this.isLate,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  // ========================================
  // GETTER: isGraded
  // MÔ TẢ: Kiểm tra đã được chấm điểm chưa
  // ========================================
  bool get isGraded => score != null && gradedAt != null;

  // ========================================
  // GETTER: scorePercentage
  // MÔ TẢ: Điểm số theo phần trăm
  // ========================================
  double? get scorePercentage {
    if (score == null || maxScore == null || maxScore == 0) return null;
    return (score! / maxScore!) * 100;
  }

  // ========================================
  // GETTER: hasAttachments
  // MÔ TẢ: Kiểm tra có file đính kèm không
  // ========================================
  bool get hasAttachments => attachments.isNotEmpty;

  // ========================================
  // GETTER: hasTextContent
  // MÔ TẢ: Kiểm tra có nội dung text không
  // ========================================
  bool get hasTextContent => textContent != null && textContent!.isNotEmpty;

  // ========================================
  // GETTER: gradeDisplay
  // MÔ TẢ: Hiển thị điểm số
  // ========================================
  String get gradeDisplay {
    if (!isGraded) return 'Chưa chấm điểm';

    if (scorePercentage != null) {
      return '${score!.toStringAsFixed(1)}/${maxScore!.toStringAsFixed(1)} (${scorePercentage!.toStringAsFixed(1)}%)';
    }

    return '${score!.toStringAsFixed(1)}';
  }

  // ========================================
  // HÀM: grade()
  // MÔ TẢ: Chấm điểm bài nộp
  // ========================================
  SubmissionModel grade({
    required double score,
    required double maxScore,
    required String gradedBy,
    String? feedback,
  }) {
    return copyWith(
      score: score,
      maxScore: maxScore,
      gradedBy: gradedBy,
      gradedAt: DateTime.now(),
      feedback: feedback,
      status: SubmissionStatus.graded,
      lastModified: DateTime.now(),
    );
  }

  // ========================================
  // Static Helper Methods
  // ========================================
  static List<AttachmentModel> _parseAttachments(dynamic attachmentsData) {
    if (attachmentsData == null) {
      return [];
    }

    // If it's a List (array)
    if (attachmentsData is List) {
      return attachmentsData
          .map((item) {
            try {
              if (item is Map) {
                final map = Map<String, dynamic>.from(item);
                final attachment = AttachmentModel.fromMap(map);
                return attachment;
              }
              return null;
            } catch (e) {
              return null;
            }
          })
          .whereType<AttachmentModel>()
          .toList();
    }

    // If it's a Map (object) - convert to list with single item
    if (attachmentsData is Map) {
      try {
        final map = Map<String, dynamic>.from(attachmentsData);
        final attachment = AttachmentModel.fromMap(map);
        return [attachment];
      } catch (e) {
        return [];
      }
    }

    return [];
  }

  static SubmissionStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return SubmissionStatus.draft;
      case 'submitted':
        return SubmissionStatus.submitted;
      case 'graded':
        return SubmissionStatus.graded;
      case 'returned':
        return SubmissionStatus.returned;
      default:
        return SubmissionStatus.submitted;
    }
  }

  static DateTime? _parseDateTime(dynamic dateData) {
    if (dateData == null) {
      return null;
    }

    if (dateData is DateTime) {
      return dateData;
    }

    // Handle Firestore Timestamp
    if (dateData is Timestamp) {
      final date = dateData.toDate();
      return date;
    }

    try {
      final parsed = DateTime.parse(dateData.toString());
      return parsed;
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'SubmissionModel(id: $id, studentName: $studentName, status: $status, isGraded: $isGraded)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubmissionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ========================================
// ENUM: SubmissionStatus
// MÔ TẢ: Trạng thái bài nộp
// ========================================
enum SubmissionStatus {
  draft, // Nháp
  submitted, // Đã nộp
  graded, // Đã chấm điểm
  returned, // Trả lại (cần sửa)
}

extension SubmissionStatusExtension on SubmissionStatus {
  String get displayName {
    switch (this) {
      case SubmissionStatus.draft:
        return 'Nháp';
      case SubmissionStatus.submitted:
        return 'Đã nộp';
      case SubmissionStatus.graded:
        return 'Đã chấm điểm';
      case SubmissionStatus.returned:
        return 'Trả lại';
    }
  }

  String get name {
    switch (this) {
      case SubmissionStatus.draft:
        return 'draft';
      case SubmissionStatus.submitted:
        return 'submitted';
      case SubmissionStatus.graded:
        return 'graded';
      case SubmissionStatus.returned:
        return 'returned';
    }
  }
}

// ========================================
// CLASS: AttachmentModel
// MÔ TẢ: Tái sử dụng cho file đính kèm
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
    // Parse uploadedAt - handle Timestamp, DateTime, or String
    DateTime parseUploadedAt(dynamic dateData) {
      if (dateData == null) {
        return DateTime.now();
      }
      if (dateData is DateTime) {
        return dateData;
      }
      if (dateData is Timestamp) {
        return dateData.toDate();
      }
      try {
        return DateTime.parse(dateData.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    final attachment = AttachmentModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      mimeType: map['mimeType']?.toString() ?? '',
      sizeInBytes: (map['sizeInBytes'] as int?) ??
          (map['size'] as int?) ??
          ((map['sizeInBytes'] as num?)?.toInt()) ??
          ((map['size'] as num?)?.toInt()) ??
          0,
      uploadedAt: parseUploadedAt(map['uploadedAt']),
    );

    return attachment;
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
