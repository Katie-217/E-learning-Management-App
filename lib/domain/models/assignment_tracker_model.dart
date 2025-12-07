// ========================================
// FILE: assignment_tracker_model.dart
// PURPOSE: Assignment Tracking System Model
// DESCRIPTION: Denormalized model for fast gradebook queries
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for Tracker Status
enum TrackerStatus {
  missing, // Chưa nộp
  submitted, // Đã nộp đúng hạn
  late, // Nộp muộn
  graded, // Đã chấm điểm
}

extension TrackerStatusExtension on TrackerStatus {
  String get name {
    switch (this) {
      case TrackerStatus.missing:
        return 'missing';
      case TrackerStatus.submitted:
        return 'submitted';
      case TrackerStatus.late:
        return 'late';
      case TrackerStatus.graded:
        return 'graded';
    }
  }

  String get displayName {
    switch (this) {
      case TrackerStatus.missing:
        return 'Chưa nộp';
      case TrackerStatus.submitted:
        return 'Đã nộp';
      case TrackerStatus.late:
        return 'Nộp muộn';
      case TrackerStatus.graded:
        return 'Đã chấm';
    }
  }

  static TrackerStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'missing':
        return TrackerStatus.missing;
      case 'submitted':
        return TrackerStatus.submitted;
      case 'late':
        return TrackerStatus.late;
      case 'graded':
        return TrackerStatus.graded;
      default:
        return TrackerStatus.missing;
    }
  }
}

/// Attachment Model for Tracker
class TrackerAttachment {
  final String id;
  final String name;
  final String url;
  final String mimeType;
  final int sizeInBytes;

  const TrackerAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.mimeType,
    required this.sizeInBytes,
  });

  factory TrackerAttachment.fromMap(Map<String, dynamic> map) {
    return TrackerAttachment(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      mimeType: map['mimeType']?.toString() ?? '',
      sizeInBytes: (map['sizeInBytes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'mimeType': mimeType,
      'sizeInBytes': sizeInBytes,
    };
  }
}

/// Assignment Tracker Model
/// Denormalized model containing all info needed for gradebook display
class AssignmentTrackerModel {
  final String id; // compositeKey: ${assignmentId}_${studentId}

  // Primary Keys
  final String assignmentId;
  final String studentId;
  final String courseId;
  final String groupId;

  // Denormalized Student Info (No JOIN needed!)
  final String studentName;
  final String studentEmail;
  final String groupName;

  // Status & Tracking
  final TrackerStatus status;
  final DateTime? submittedAt;
  final bool isLate;
  final int attemptCount;

  // Grading
  final double? grade;
  final double maxPoints;
  final String? feedback;
  final String? gradedBy;
  final DateTime? gradedAt;

  // Submission Data
  final List<TrackerAttachment> attachments;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const AssignmentTrackerModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.courseId,
    required this.groupId,
    required this.studentName,
    required this.studentEmail,
    required this.groupName,
    required this.status,
    this.submittedAt,
    required this.isLate,
    required this.attemptCount,
    this.grade,
    required this.maxPoints,
    this.feedback,
    this.gradedBy,
    this.gradedAt,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse DateTime from Firestore (Timestamp or DateTime)
  static DateTime _parseDateTime(dynamic dateData) {
    if (dateData == null) {
      return DateTime.now();
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
      return DateTime.now();
    }
  }

  /// Create from Firestore Document
  factory AssignmentTrackerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AssignmentTrackerModel.fromMap(doc.id, data);
  }

  /// Create from Map
  factory AssignmentTrackerModel.fromMap(String id, Map<String, dynamic> map) {
    // Parse attachments
    final List<TrackerAttachment> attachments = [];
    if (map['attachments'] is List) {
      for (final item in map['attachments']) {
        if (item is Map) {
          attachments.add(TrackerAttachment.fromMap(
            Map<String, dynamic>.from(item),
          ));
        }
      }
    }

    return AssignmentTrackerModel(
      id: id,
      assignmentId: map['assignmentId']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      courseId: map['courseId']?.toString() ?? '',
      groupId: map['groupId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? 'Student',
      studentEmail: map['studentEmail']?.toString() ?? '',
      groupName: map['groupName']?.toString() ?? 'Unknown Group',
      status: TrackerStatusExtension.fromString(
        map['status']?.toString() ?? 'missing',
      ),
      submittedAt: map['submittedAt'] != null
          ? _parseDateTime(map['submittedAt'])
          : null,
      isLate: map['isLate'] as bool? ?? false,
      attemptCount: (map['attemptCount'] as num?)?.toInt() ?? 0,
      grade: map['grade']?.toDouble(),
      maxPoints: (map['maxPoints'] as num?)?.toDouble() ?? 100.0,
      feedback: map['feedback']?.toString(),
      gradedBy: map['gradedBy']?.toString(),
      gradedAt:
          map['gradedAt'] != null ? _parseDateTime(map['gradedAt']) : null,
      attachments: attachments,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'courseId': courseId,
      'groupId': groupId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'groupName': groupName,
      'status': status.name,
      'submittedAt': submittedAt,
      'isLate': isLate,
      'attemptCount': attemptCount,
      'grade': grade,
      'maxPoints': maxPoints,
      'feedback': feedback,
      'gradedBy': gradedBy,
      'gradedAt': gradedAt,
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Generate composite trackerId
  static String getTrackerId(String assignmentId, String studentId) {
    return '${assignmentId}_${studentId}';
  }

  /// Check if tracker has been graded
  bool get isGraded => status == TrackerStatus.graded && grade != null;

  /// Get grade percentage (0-100)
  double? get gradePercentage {
    if (grade == null || maxPoints == 0) return null;
    return (grade! / maxPoints) * 100;
  }

  /// Get status color for UI
  String get statusColorHex {
    switch (status) {
      case TrackerStatus.missing:
        return '#EF4444'; // Red
      case TrackerStatus.submitted:
        return '#3B82F6'; // Blue
      case TrackerStatus.late:
        return '#F59E0B'; // Orange
      case TrackerStatus.graded:
        return '#10B981'; // Green
    }
  }

  /// Copy with method for updates
  AssignmentTrackerModel copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? courseId,
    String? groupId,
    String? studentName,
    String? studentEmail,
    String? groupName,
    TrackerStatus? status,
    DateTime? submittedAt,
    bool? isLate,
    int? attemptCount,
    double? grade,
    double? maxPoints,
    String? feedback,
    String? gradedBy,
    DateTime? gradedAt,
    List<TrackerAttachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssignmentTrackerModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      groupId: groupId ?? this.groupId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      groupName: groupName ?? this.groupName,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      isLate: isLate ?? this.isLate,
      attemptCount: attemptCount ?? this.attemptCount,
      grade: grade ?? this.grade,
      maxPoints: maxPoints ?? this.maxPoints,
      feedback: feedback ?? this.feedback,
      gradedBy: gradedBy ?? this.gradedBy,
      gradedAt: gradedAt ?? this.gradedAt,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AssignmentTrackerModel(id: $id, student: $studentName, status: ${status.displayName}, grade: $grade/$maxPoints)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssignmentTrackerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
