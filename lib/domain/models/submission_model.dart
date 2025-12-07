// ========================================
// FILE: submission_model.dart
// MÃ” Táº¢: Model ná»™p bÃ i cá»§a sinh viÃªn
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String courseId;
  final String
      semesterId; // âœ… NEW: Root Collection support - semester filtering
  final String groupId; // âœ… NEW: Root Collection support - group filtering
  final DateTime submittedAt;
  final SubmissionStatus status;
  final List<AttachmentModel> attachments;
  final String? textContent; // Ná»™i dung text náº¿u cÃ³
  final double? score; // Äiá»ƒm sá»‘ (nullable khi chÆ°a cháº¥m)
  final double? maxScore; // Äiá»ƒm tá»‘i Ä‘a
  final String? feedback; // Pháº£n há»“i tá»« giáº£ng viÃªn
  final String? gradedBy; // UID cá»§a ngÆ°á»i cháº¥m Ä‘iá»ƒm
  final DateTime? gradedAt; // Thá»i gian cháº¥m Ä‘iá»ƒm
  final bool isLate; // Ná»™p muá»™n
  final int attemptNumber; // Láº§n ná»™p thá»© máº¥y
  final DateTime? lastModified;

  const SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.semesterId, // âœ… REQUIRED: Root Collection support
    required this.groupId, // âœ… REQUIRED: Root Collection support
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
  // HÃ€M: fromMap()
  // MÃ” Táº¢: Táº¡o SubmissionModel tá»« Map (Firebase data)
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
      semesterId: map['semesterId'] ?? '', // âœ… Read semesterId from Firebase
      groupId: map['groupId'] ?? '', // âœ… Read groupId from Firebase
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
  // HÃ€M: toMap()
  // MÃ” Táº¢: Chuyá»ƒn SubmissionModel thÃ nh Map Ä‘á»ƒ lÆ°u Firebase
  // âš ï¸ NOTE: 'id' is NOT included because it's stored as document ID, not a field
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      // 'id': id, // âŒ REMOVED: ID should not be saved as a field in Firestore
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'semesterId': semesterId, // âœ… Write semesterId to Firebase
      'groupId': groupId, // âœ… Write groupId to Firebase
      'submittedAt':
          submittedAt.toUtc().toIso8601String(), // ✅ Convert to UTC first
      'status': status.name,
      'attachments':
          attachments.map((attachment) => attachment.toMap()).toList(),
      'textContent': textContent,
      'score': score,
      'maxScore': maxScore,
      'feedback': feedback,
      'gradedBy': gradedBy,
      'gradedAt': gradedAt?.toUtc().toIso8601String(), // ✅ Convert to UTC first
      'isLate': isLate,
      'attemptNumber': attemptNumber,
      'lastModified':
          lastModified?.toUtc().toIso8601String(), // ✅ Convert to UTC first
    };
  }

  // ========================================
  // HÃ€M: copyWith()
  // MÃ” Táº¢: Táº¡o báº£n sao vá»›i má»™t sá»‘ field thay Ä‘á»•i
  // ========================================
  SubmissionModel copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? studentName,
    String? courseId,
    String? semesterId, // âœ… Support semesterId updates
    String? groupId, // âœ… Support groupId updates
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
  // MÃ” Táº¢: Kiá»ƒm tra Ä‘Ã£ Ä‘Æ°á»£c cháº¥m Ä‘iá»ƒm chÆ°a
  // ========================================
  bool get isGraded => score != null && gradedAt != null;

  // ========================================
  // GETTER: scorePercentage
  // MÃ” Táº¢: Äiá»ƒm sá»‘ theo pháº§n trÄƒm
  // ========================================
  double? get scorePercentage {
    if (score == null || maxScore == null || maxScore == 0) return null;
    return (score! / maxScore!) * 100;
  }

  // ========================================
  // GETTER: hasAttachments
  // MÃ” Táº¢: Kiá»ƒm tra cÃ³ file Ä‘Ã­nh kÃ¨m khÃ´ng
  // ========================================
  bool get hasAttachments => attachments.isNotEmpty;

  // ========================================
  // GETTER: hasTextContent
  // MÃ” Táº¢: Kiá»ƒm tra cÃ³ ná»™i dung text khÃ´ng
  // ========================================
  bool get hasTextContent => textContent != null && textContent!.isNotEmpty;

  // ========================================
  // GETTER: gradeDisplay
  // MÃ” Táº¢: Hiá»ƒn thá»‹ Ä‘iá»ƒm sá»‘
  // ========================================
  String get gradeDisplay {
    if (!isGraded) return 'ChÆ°a cháº¥m Ä‘iá»ƒm';

    if (scorePercentage != null) {
      return '${score!.toStringAsFixed(1)}/${maxScore!.toStringAsFixed(1)} (${scorePercentage!.toStringAsFixed(1)}%)';
    }

    return '${score!.toStringAsFixed(1)}';
  }

  // ========================================
  // HÃ€M: grade()
  // MÃ” Táº¢: Cháº¥m Ä‘iá»ƒm bÃ i ná»™p
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
      case 'missing':
        return SubmissionStatus.missing;
      case 'submitted':
        return SubmissionStatus.submitted;
      case 'late':
        return SubmissionStatus.late;
      case 'graded':
        return SubmissionStatus.graded;
      default:
        return SubmissionStatus.missing;
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
      print('DEBUG: âš ï¸ Error parsing date: $e');
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
// MÃ” Táº¢: Tráº¡ng thÃ¡i bÃ i ná»™p
// ========================================
enum SubmissionStatus {
  missing,
  submitted,
  late,
  graded,
}

extension SubmissionStatusExtension on SubmissionStatus {
  String get displayName {
    switch (this) {
      case SubmissionStatus.missing:
        return 'ChÆ°a ná»™p';
      case SubmissionStatus.submitted:
        return 'ÄÃ£ ná»™p';
      case SubmissionStatus.late:
        return 'Ná»™p muá»™n';
      case SubmissionStatus.graded:
        return 'ÄÃ£ cháº¥m Ä‘iá»ƒm';
    }
  }

  String get name {
    switch (this) {
      case SubmissionStatus.missing:
        return 'missing';
      case SubmissionStatus.submitted:
        return 'submitted';
      case SubmissionStatus.late:
        return 'late';
      case SubmissionStatus.graded:
        return 'graded';
    }
  }
}

// ========================================
// CLASS: AttachmentModel
// MÃ” Táº¢: TÃ¡i sá»­ dá»¥ng cho file Ä‘Ã­nh kÃ¨m
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
