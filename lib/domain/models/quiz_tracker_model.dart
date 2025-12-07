// ========================================
// FILE: quiz_tracker_model.dart
// PURPOSE: Quiz Tracker Model for Real-time Grade Tracking
// DESCRIPTION: Denormalized model similar to AssignmentTracker
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';

class QuizTrackerModel {
  final String id; // Composite key: ${quizId}_${studentId}

  // Foreign Keys
  final String quizId;
  final String studentId;
  final String courseId;
  final String groupId;

  // Denormalized Student Info (Snapshot)
  final String studentName;
  final String studentEmail;
  final String groupName;

  // Status & Results
  final String status; // 'not_started', 'in_progress', 'completed'
  final int attemptCount; // Number of attempts used (1, 2, 3...)
  final double? score; // Best score achieved

  // Timestamps
  final DateTime? startedAt; // First attempt started
  final DateTime? lastAttemptAt; // Most recent attempt
  final DateTime? completedAt; // Last completion time

  // Submission Link
  final String? lastSubmissionId; // Link to latest submission for review

  QuizTrackerModel({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.courseId,
    required this.groupId,
    required this.studentName,
    required this.studentEmail,
    required this.groupName,
    required this.status,
    required this.attemptCount,
    this.score,
    this.startedAt,
    this.lastAttemptAt,
    this.completedAt,
    this.lastSubmissionId,
  });

  // Factory constructor from Firestore document
  factory QuizTrackerModel.fromMap(Map<String, dynamic> map) {
    return QuizTrackerModel(
      id: map['id'] as String,
      quizId: map['quizId'] as String,
      studentId: map['studentId'] as String,
      courseId: map['courseId'] as String,
      groupId: map['groupId'] as String,
      studentName: map['studentName'] as String,
      studentEmail: map['studentEmail'] as String,
      groupName: map['groupName'] as String,
      status: map['status'] as String,
      attemptCount: map['attemptCount'] as int,
      score: map['score'] != null ? (map['score'] as num).toDouble() : null,
      startedAt: map['startedAt'] != null
          ? (map['startedAt'] as Timestamp).toDate()
          : null,
      lastAttemptAt: map['lastAttemptAt'] != null
          ? (map['lastAttemptAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      lastSubmissionId: map['lastSubmissionId'] as String?,
    );
  }

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'studentId': studentId,
      'courseId': courseId,
      'groupId': groupId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'groupName': groupName,
      'status': status,
      'attemptCount': attemptCount,
      'score': score,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'lastAttemptAt':
          lastAttemptAt != null ? Timestamp.fromDate(lastAttemptAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'lastSubmissionId': lastSubmissionId,
    };
  }

  // CopyWith method for updates
  QuizTrackerModel copyWith({
    String? id,
    String? quizId,
    String? studentId,
    String? courseId,
    String? groupId,
    String? studentName,
    String? studentEmail,
    String? groupName,
    String? status,
    int? attemptCount,
    double? score,
    DateTime? startedAt,
    DateTime? lastAttemptAt,
    DateTime? completedAt,
    String? lastSubmissionId,
  }) {
    return QuizTrackerModel(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      groupId: groupId ?? this.groupId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      groupName: groupName ?? this.groupName,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      score: score ?? this.score,
      startedAt: startedAt ?? this.startedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      completedAt: completedAt ?? this.completedAt,
      lastSubmissionId: lastSubmissionId ?? this.lastSubmissionId,
    );
  }

  // Helper: Check if quiz is started
  bool get isStarted => status != 'not_started';

  // Helper: Check if quiz is completed
  bool get isCompleted => status == 'completed';

  // Helper: Check if quiz is in progress
  bool get isInProgress => status == 'in_progress';

  // Helper: Format status display
  String get statusDisplay {
    switch (status) {
      case 'not_started':
        return 'Not Started';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }
}
