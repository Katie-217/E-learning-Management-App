// ========================================
// FILE: question_model.dart
// MÔ TẢ: Model câu hỏi cho ngân hàng câu hỏi và quiz
// ========================================

class QuestionModel {
  final String id;
  final String courseId;
  final String question;
  final QuestionType type;
  final List<AnswerOption> options; // Cho multiple choice
  final String correctAnswer; // ID của đáp án đúng hoặc text
  final String? explanation; // Giải thích đáp án
  final QuestionDifficulty difficulty;
  final List<String> tags; // Tags để phân loại
  final String authorId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final int usageCount; // Số lần được sử dụng trong quiz

  const QuestionModel({
    required this.id,
    required this.courseId,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    required this.difficulty,
    this.tags = const [],
    required this.authorId,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.usageCount = 0,
  });

  // ========================================
  // HÀM: fromMap()
  // MÔ TẢ: Tạo QuestionModel từ Map (Firebase data)
  // ========================================
  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] ?? '',
      courseId: map['courseId'] ?? '',
      question: map['question'] ?? '',
      type: _parseQuestionType(map['type'] ?? 'multiple_choice'),
      options: (map['options'] as List<dynamic>?)
              ?.map(
                  (item) => AnswerOption.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      correctAnswer: map['correctAnswer'] ?? '',
      explanation: map['explanation'],
      difficulty: _parseDifficulty(map['difficulty'] ?? 'medium'),
      tags: List<String>.from(map['tags'] ?? []),
      authorId: map['authorId'] ?? '',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']),
      isActive: map['isActive'] ?? true,
      usageCount: map['usageCount'] ?? 0,
    );
  }

  // ========================================
  // HÀM: toMap()
  // MÔ TẢ: Chuyển QuestionModel thành Map để lưu Firebase
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'question': question,
      'type': type.name,
      'options': options.map((option) => option.toMap()).toList(),
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty.name,
      'tags': tags,
      'authorId': authorId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'usageCount': usageCount,
    };
  }

  // ========================================
  // HÀM: copyWith()
  // MÔ TẢ: Tạo bản sao với một số field thay đổi
  // ========================================
  QuestionModel copyWith({
    String? id,
    String? courseId,
    String? question,
    QuestionType? type,
    List<AnswerOption>? options,
    String? correctAnswer,
    String? explanation,
    QuestionDifficulty? difficulty,
    List<String>? tags,
    String? authorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? usageCount,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  // ========================================
  // HÀM: incrementUsageCount()
  // MÔ TẢ: Tăng số lần sử dụng
  // ========================================
  QuestionModel incrementUsageCount() {
    return copyWith(usageCount: usageCount + 1);
  }

  // ========================================
  // HÀM: isCorrectAnswer()
  // MÔ TẢ: Kiểm tra đáp án có đúng không
  // ========================================
  bool isCorrectAnswer(String answer) {
    return answer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
  }

  // ========================================
  // HÀM: getCorrectOption()
  // MÔ TẢ: Lấy option đúng (cho multiple choice)
  // ========================================
  AnswerOption? getCorrectOption() {
    if (type != QuestionType.multipleChoice) return null;

    try {
      return options.firstWhere((option) => option.id == correctAnswer);
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // Static Helper Methods
  // ========================================
  static QuestionType _parseQuestionType(String type) {
    switch (type.toLowerCase()) {
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'true_false':
        return QuestionType.trueFalse;
      case 'short_answer':
        return QuestionType.shortAnswer;
      case 'essay':
        return QuestionType.essay;
      default:
        return QuestionType.multipleChoice;
    }
  }

  static QuestionDifficulty _parseDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return QuestionDifficulty.easy;
      case 'medium':
        return QuestionDifficulty.medium;
      case 'hard':
        return QuestionDifficulty.hard;
      default:
        return QuestionDifficulty.medium;
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
    return 'QuestionModel(id: $id, type: $type, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ========================================
// CLASS: AnswerOption
// MÔ TẢ: Option cho câu hỏi multiple choice
// ========================================
class AnswerOption {
  final String id;
  final String text;
  final bool isCorrect;

  const AnswerOption({
    required this.id,
    required this.text,
    this.isCorrect = false,
  });

  factory AnswerOption.fromMap(Map<String, dynamic> map) {
    return AnswerOption(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isCorrect: map['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isCorrect': isCorrect,
    };
  }
}

// ========================================
// ENUM: QuestionType
// MÔ TẢ: Loại câu hỏi
// ========================================
enum QuestionType {
  multipleChoice, // Trắc nghiệm
  trueFalse, // Đúng/Sai
  shortAnswer, // Câu trả lời ngắn
  essay, // Tự luận
}

extension QuestionTypeExtension on QuestionType {
  String get displayName {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Trắc nghiệm';
      case QuestionType.trueFalse:
        return 'Đúng/Sai';
      case QuestionType.shortAnswer:
        return 'Câu trả lời ngắn';
      case QuestionType.essay:
        return 'Tự luận';
    }
  }

  String get name {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'multiple_choice';
      case QuestionType.trueFalse:
        return 'true_false';
      case QuestionType.shortAnswer:
        return 'short_answer';
      case QuestionType.essay:
        return 'essay';
    }
  }
}

// ========================================
// ENUM: QuestionDifficulty
// MÔ TẢ: Độ khó câu hỏi
// ========================================
enum QuestionDifficulty {
  easy, // Dễ
  medium, // Trung bình
  hard, // Khó
}

extension QuestionDifficultyExtension on QuestionDifficulty {
  String get displayName {
    switch (this) {
      case QuestionDifficulty.easy:
        return 'Dễ';
      case QuestionDifficulty.medium:
        return 'Trung bình';
      case QuestionDifficulty.hard:
        return 'Khó';
    }
  }

  String get name {
    switch (this) {
      case QuestionDifficulty.easy:
        return 'easy';
      case QuestionDifficulty.medium:
        return 'medium';
      case QuestionDifficulty.hard:
        return 'hard';
    }
  }
}
