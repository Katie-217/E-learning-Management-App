// ========================================
// FILE: quiz_submission_model.dart
// MÔ TẢ: Model for student's quiz submission (attempt)
// Contains snapshot questions, answers, score, and status
// ========================================

import 'package:elearning_management_app/domain/models/snapshot_question_model.dart';

class QuizSubmissionModel {
  final String id; // Submission ID
  final String quizId; // Quiz ID
  final String courseId; // Course ID
  final String studentId; // Student ID
  final String studentName; // Student name
  final List<SnapshotQuestionModel> questions; // Snapshot of questions
  final Map<String, int> answers; // questionId -> selected answer index
  final DateTime startedAt; // When the quiz was started
  final DateTime? submittedAt; // When the quiz was submitted
  final double? score; // Final score (0-100)
  final String status; // 'in_progress', 'completed'
  final int attemptNumber; // Which attempt (1, 2, 3...)
  final bool isAutoSubmitted; // Auto-submitted when time expired
  final int timeSpentSeconds; // Time spent in seconds

  const QuizSubmissionModel({
    required this.id,
    required this.quizId,
    required this.courseId,
    required this.studentId,
    required this.studentName,
    required this.questions,
    this.answers = const {},
    required this.startedAt,
    this.submittedAt,
    this.score,
    this.status = 'in_progress',
    this.attemptNumber = 1,
    this.isAutoSubmitted = false,
    this.timeSpentSeconds = 0,
  });

  // ========================================
  // HÀM: fromMap()
  // MÔ TẢ: Create QuizSubmissionModel from Map (Firestore data)
  // ========================================
  factory QuizSubmissionModel.fromMap(Map<String, dynamic> map) {
    return QuizSubmissionModel(
      id: map['id'] ?? '',
      quizId: map['quizId'] ?? '',
      courseId: map['courseId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      questions: (map['questions'] as List<dynamic>?)
              ?.map((q) =>
                  SnapshotQuestionModel.fromMap(q as Map<String, dynamic>))
              .toList() ??
          [],
      answers: Map<String, int>.from(map['answers'] ?? {}),
      startedAt: _parseDateTime(map['startedAt']) ?? DateTime.now(),
      submittedAt: _parseDateTime(map['submittedAt']),
      score: map['score']?.toDouble(),
      status: map['status'] ?? 'in_progress',
      attemptNumber: map['attemptNumber'] ?? 1,
      isAutoSubmitted: map['isAutoSubmitted'] ?? false,
      timeSpentSeconds: map['timeSpentSeconds'] ?? 0,
    );
  }

  // ========================================
  // HÀM: toMap()
  // MÔ TẢ: Convert QuizSubmissionModel to Map for Firestore
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'courseId': courseId,
      'studentId': studentId,
      'studentName': studentName,
      'questions': questions.map((q) => q.toMap()).toList(),
      'answers': answers,
      'startedAt': startedAt.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'score': score,
      'status': status,
      'attemptNumber': attemptNumber,
      'isAutoSubmitted': isAutoSubmitted,
      'timeSpentSeconds': timeSpentSeconds,
    };
  }

  // ========================================
  // HÀM: copyWith()
  // MÔ TẢ: Create a copy with some fields modified
  // ========================================
  QuizSubmissionModel copyWith({
    String? id,
    String? quizId,
    String? courseId,
    String? studentId,
    String? studentName,
    List<SnapshotQuestionModel>? questions,
    Map<String, int>? answers,
    DateTime? startedAt,
    DateTime? submittedAt,
    double? score,
    String? status,
    int? attemptNumber,
    bool? isAutoSubmitted,
    int? timeSpentSeconds,
  }) {
    return QuizSubmissionModel(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      courseId: courseId ?? this.courseId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      score: score ?? this.score,
      status: status ?? this.status,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      isAutoSubmitted: isAutoSubmitted ?? this.isAutoSubmitted,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    );
  }

  // ========================================
  // HELPER: Parse DateTime
  // ========================================
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // ========================================
  // COMPUTED: Number of answered questions
  // ========================================
  int get answeredCount => answers.length;

  // ========================================
  // COMPUTED: Is quiz completed
  // ========================================
  bool get isCompleted => status == 'completed';

  // ========================================
  // COMPUTED: Did student pass
  // ========================================
  bool isPassed(double passingScore) {
    return score != null && score! >= passingScore;
  }

  @override
  String toString() {
    return 'QuizSubmissionModel(id: $id, quizId: $quizId, status: $status, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is QuizSubmissionModel &&
        other.id == id &&
        other.quizId == quizId &&
        other.studentId == studentId &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^ quizId.hashCode ^ studentId.hashCode ^ status.hashCode;
  }
}
