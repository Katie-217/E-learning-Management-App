// ========================================
// FILE: quiz_attempt_model.dart
// MÔ TẢ: Model lần làm quiz của sinh viên
// ========================================

class QuizAttemptModel {
  final String id;
  final String quizId;
  final String studentId;
  final String studentName;
  final String courseId;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final QuizAttemptStatus status;
  final List<QuizAnswer> answers;
  final double? score; // Điểm số
  final double? maxScore; // Điểm tối đa
  final int timeSpentInSeconds; // Thời gian làm bài (giây)
  final int attemptNumber; // Lần làm thứ mấy
  final bool isAutoSubmitted; // Tự động nộp khi hết time
  final String? feedback; // Phản hồi tổng quan
  final Map<String, dynamic>? metadata; // Thông tin thêm

  const QuizAttemptModel({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.startedAt,
    this.submittedAt,
    required this.status,
    this.answers = const [],
    this.score,
    this.maxScore,
    this.timeSpentInSeconds = 0,
    this.attemptNumber = 1,
    this.isAutoSubmitted = false,
    this.feedback,
    this.metadata,
  });

  // ========================================
  // HÀM: fromMap()
  // MÔ TẢ: Tạo QuizAttemptModel từ Map (Firebase data)
  // ========================================
  factory QuizAttemptModel.fromMap(Map<String, dynamic> map) {
    return QuizAttemptModel(
      id: map['id'] ?? '',
      quizId: map['quizId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      courseId: map['courseId'] ?? '',
      startedAt: _parseDateTime(map['startedAt']) ?? DateTime.now(),
      submittedAt: _parseDateTime(map['submittedAt']),
      status: _parseStatus(map['status'] ?? 'in_progress'),
      answers: (map['answers'] as List<dynamic>?)
              ?.map((item) => QuizAnswer.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      score: map['score']?.toDouble(),
      maxScore: map['maxScore']?.toDouble(),
      timeSpentInSeconds: map['timeSpentInSeconds'] ?? 0,
      attemptNumber: map['attemptNumber'] ?? 1,
      isAutoSubmitted: map['isAutoSubmitted'] ?? false,
      feedback: map['feedback'],
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  // ========================================
  // HÀM: toMap()
  // MÔ TẢ: Chuyển QuizAttemptModel thành Map để lưu Firebase
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'startedAt': startedAt.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'status': status.name,
      'answers': answers.map((answer) => answer.toMap()).toList(),
      'score': score,
      'maxScore': maxScore,
      'timeSpentInSeconds': timeSpentInSeconds,
      'attemptNumber': attemptNumber,
      'isAutoSubmitted': isAutoSubmitted,
      'feedback': feedback,
      'metadata': metadata,
    };
  }

  // ========================================
  // HÀM: copyWith()
  // MÔ TẢ: Tạo bản sao với một số field thay đổi
  // ========================================
  QuizAttemptModel copyWith({
    String? id,
    String? quizId,
    String? studentId,
    String? studentName,
    String? courseId,
    DateTime? startedAt,
    DateTime? submittedAt,
    QuizAttemptStatus? status,
    List<QuizAnswer>? answers,
    double? score,
    double? maxScore,
    int? timeSpentInSeconds,
    int? attemptNumber,
    bool? isAutoSubmitted,
    String? feedback,
    Map<String, dynamic>? metadata,
  }) {
    return QuizAttemptModel(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      courseId: courseId ?? this.courseId,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      answers: answers ?? this.answers,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      timeSpentInSeconds: timeSpentInSeconds ?? this.timeSpentInSeconds,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      isAutoSubmitted: isAutoSubmitted ?? this.isAutoSubmitted,
      feedback: feedback ?? this.feedback,
      metadata: metadata ?? this.metadata,
    );
  }

  // ========================================
  // GETTER: isCompleted
  // MÔ TẢ: Kiểm tra đã hoàn thành chưa
  // ========================================
  bool get isCompleted => status == QuizAttemptStatus.completed;

  // ========================================
  // GETTER: isInProgress
  // MÔ TẢ: Kiểm tra đang làm bài không
  // ========================================
  bool get isInProgress => status == QuizAttemptStatus.inProgress;

  // ========================================
  // GETTER: scorePercentage
  // MÔ TẢ: Điểm số theo phần trăm
  // ========================================
  double? get scorePercentage {
    if (score == null || maxScore == null || maxScore == 0) return null;
    return (score! / maxScore!) * 100;
  }

  // ========================================
  // GETTER: duration
  // MÔ TẢ: Thời lượng làm bài
  // ========================================
  Duration get duration => Duration(seconds: timeSpentInSeconds);

  // ========================================
  // GETTER: answeredQuestions
  // MÔ TẢ: Số câu đã trả lời
  // ========================================
  int get answeredQuestions => answers.where((a) => a.hasAnswer).length;

  // ========================================
  // HÀM: addAnswer()
  // MÔ TẢ: Thêm/cập nhật câu trả lời
  // ========================================
  QuizAttemptModel addAnswer(QuizAnswer answer) {
    final updatedAnswers = [...answers];
    final existingIndex =
        updatedAnswers.indexWhere((a) => a.questionId == answer.questionId);

    if (existingIndex >= 0) {
      updatedAnswers[existingIndex] = answer;
    } else {
      updatedAnswers.add(answer);
    }

    return copyWith(answers: updatedAnswers);
  }

  // ========================================
  // HÀM: submit()
  // MÔ TẢ: Nộp bài quiz
  // ========================================
  QuizAttemptModel submit({bool isAutoSubmitted = false}) {
    return copyWith(
      submittedAt: DateTime.now(),
      status: QuizAttemptStatus.completed,
      isAutoSubmitted: isAutoSubmitted,
    );
  }

  // ========================================
  // Static Helper Methods
  // ========================================
  static QuizAttemptStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return QuizAttemptStatus.inProgress;
      case 'completed':
        return QuizAttemptStatus.completed;
      case 'abandoned':
        return QuizAttemptStatus.abandoned;
      default:
        return QuizAttemptStatus.inProgress;
    }
  }

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
    return 'QuizAttemptModel(id: $id, studentName: $studentName, status: $status, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizAttemptModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ========================================
// CLASS: QuizAnswer
// MÔ TẢ: Câu trả lời cho một câu hỏi
// ========================================
class QuizAnswer {
  final String questionId;
  final String? selectedAnswerId; // Cho multiple choice
  final String? textAnswer; // Cho text answer
  final List<String>? selectedAnswerIds; // Cho multiple select
  final DateTime? answeredAt;
  final bool isCorrect; // Tự động tính hoặc manual grading

  const QuizAnswer({
    required this.questionId,
    this.selectedAnswerId,
    this.textAnswer,
    this.selectedAnswerIds,
    this.answeredAt,
    this.isCorrect = false,
  });

  factory QuizAnswer.fromMap(Map<String, dynamic> map) {
    return QuizAnswer(
      questionId: map['questionId'] ?? '',
      selectedAnswerId: map['selectedAnswerId'],
      textAnswer: map['textAnswer'],
      selectedAnswerIds: map['selectedAnswerIds'] != null
          ? List<String>.from(map['selectedAnswerIds'])
          : null,
      answeredAt:
          map['answeredAt'] != null ? DateTime.parse(map['answeredAt']) : null,
      isCorrect: map['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'selectedAnswerId': selectedAnswerId,
      'textAnswer': textAnswer,
      'selectedAnswerIds': selectedAnswerIds,
      'answeredAt': answeredAt?.toIso8601String(),
      'isCorrect': isCorrect,
    };
  }

  // ========================================
  // GETTER: hasAnswer
  // MÔ TẢ: Kiểm tra có câu trả lời không
  // ========================================
  bool get hasAnswer {
    return selectedAnswerId != null ||
        textAnswer != null ||
        (selectedAnswerIds != null && selectedAnswerIds!.isNotEmpty);
  }

  QuizAnswer copyWith({
    String? questionId,
    String? selectedAnswerId,
    String? textAnswer,
    List<String>? selectedAnswerIds,
    DateTime? answeredAt,
    bool? isCorrect,
  }) {
    return QuizAnswer(
      questionId: questionId ?? this.questionId,
      selectedAnswerId: selectedAnswerId ?? this.selectedAnswerId,
      textAnswer: textAnswer ?? this.textAnswer,
      selectedAnswerIds: selectedAnswerIds ?? this.selectedAnswerIds,
      answeredAt: answeredAt ?? this.answeredAt,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

// ========================================
// ENUM: QuizAttemptStatus
// MÔ TẢ: Trạng thái lần làm quiz
// ========================================
enum QuizAttemptStatus {
  inProgress, // Đang làm
  completed, // Đã hoàn thành
  abandoned, // Bỏ dở
}

extension QuizAttemptStatusExtension on QuizAttemptStatus {
  String get displayName {
    switch (this) {
      case QuizAttemptStatus.inProgress:
        return 'Đang làm';
      case QuizAttemptStatus.completed:
        return 'Đã hoàn thành';
      case QuizAttemptStatus.abandoned:
        return 'Bỏ dở';
    }
  }

  String get name {
    switch (this) {
      case QuizAttemptStatus.inProgress:
        return 'in_progress';
      case QuizAttemptStatus.completed:
        return 'completed';
      case QuizAttemptStatus.abandoned:
        return 'abandoned';
    }
  }
}
