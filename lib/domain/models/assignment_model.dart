import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String id;
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
}
