import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String id;
  final String courseId; // ✅ NEW: Support Collection Group Query
  final String
      semesterId; // ✅ NEW: Support Root Collection - semester filtering and CSV export
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime deadline;
  final bool allowLateSubmissions;
  final DateTime? lateDeadline; // Nullable
  final int maxSubmissionAttempts;
  final List<String> allowedFileFormats;
  final int maxFileSizeMB;
  final List<Map<String, dynamic>>
      attachments; // e.g., [{'fileName': 'name', 'url': '...'}]
  final List<String> groupIds; // IDs của các nhóm được giao

  Assignment({
    required this.id,
    required this.courseId, // ✅ REQUIRED: Parent course ID
    required this.semesterId, // ✅ REQUIRED: Root Collection support
    required this.title,
    required this.description,
    required this.startDate,
    required this.deadline,
    this.allowLateSubmissions = false,
    this.lateDeadline,
    this.maxSubmissionAttempts = 1,
    this.allowedFileFormats = const [], // Mặc định là trống (cho phép tất cả)
    this.maxFileSizeMB = 10, // Mặc định 10MB
    this.attachments = const [],
    this.groupIds = const [],
  });

  // "Phiên dịch" từ Firebase (Firestore Document) về đối tượng Dart
  factory Assignment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Xử lý Attachments và GroupIDs (phải convert từ List<dynamic>)
    List<Map<String, dynamic>> attachments =
        (data['attachments'] as List<dynamic>?)
                ?.map((item) => Map<String, dynamic>.from(item as Map))
                .toList() ??
            [];

    List<String> groupIds = (data['groupIds'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList() ??
        [];

    List<String> allowedFileFormats =
        (data['allowedFileFormats'] as List<dynamic>?)
                ?.map((item) => item.toString())
                .toList() ??
            [];

    // Parse dates - handle both Timestamp and DateTime
    DateTime parseDate(dynamic dateData) {
      if (dateData == null) {
        return DateTime.now();
      }
      if (dateData is Timestamp) {
        return dateData.toDate();
      }
      if (dateData is DateTime) {
        return dateData;
      }
      return DateTime.now();
    }

    return Assignment(
      id: doc.id,
      courseId: data['courseId'] ?? '', // ✅ Read courseId from Firebase
      semesterId: data['semesterId'] ?? '', // ✅ Read semesterId from Firebase
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: parseDate(data['startDate'] ?? data['timestamp']),
      deadline: parseDate(data['deadline']),
      allowLateSubmissions: data['allowLateSubmissions'] ?? false,
      lateDeadline:
          data['lateDeadline'] != null ? parseDate(data['lateDeadline']) : null,
      maxSubmissionAttempts: data['maxSubmissionAttempts'] ?? 1,
      allowedFileFormats: allowedFileFormats,
      maxFileSizeMB: data['maxFileSizeMB'] ?? 10,
      attachments: attachments,
      groupIds: groupIds,
    );
  }

  // "Phiên dịch" từ đối tượng Dart sang Map để ghi lên Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId, // ✅ Write courseId to Firebase
      'semesterId': semesterId, // ✅ Write semesterId to Firebase
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'deadline': Timestamp.fromDate(deadline),
      'allowLateSubmissions': allowLateSubmissions,
      'lateDeadline':
          lateDeadline != null ? Timestamp.fromDate(lateDeadline!) : null,
      'maxSubmissionAttempts': maxSubmissionAttempts,
      'allowedFileFormats': allowedFileFormats,
      'maxFileSizeMB': maxFileSizeMB,
      'attachments': attachments,
      'groupIds': groupIds,
    };
  }

  // ========================================
  // copyWith method for immutable updates
  // ========================================
  Assignment copyWith({
    String? id,
    String? courseId, // ✅ Support courseId updates
    String? semesterId, // ✅ Support semesterId updates
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? deadline,
    bool? allowLateSubmissions,
    DateTime? lateDeadline,
    int? maxSubmissionAttempts,
    List<String>? allowedFileFormats,
    int? maxFileSizeMB,
    List<Map<String, dynamic>>? attachments,
    List<String>? groupIds,
  }) {
    return Assignment(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      allowLateSubmissions: allowLateSubmissions ?? this.allowLateSubmissions,
      lateDeadline: lateDeadline ?? this.lateDeadline,
      maxSubmissionAttempts:
          maxSubmissionAttempts ?? this.maxSubmissionAttempts,
      allowedFileFormats: allowedFileFormats ?? this.allowedFileFormats,
      maxFileSizeMB: maxFileSizeMB ?? this.maxFileSizeMB,
      attachments: attachments ?? this.attachments,
      groupIds: groupIds ?? this.groupIds,
    );
  }
}