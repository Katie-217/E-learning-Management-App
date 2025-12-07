// ========================================
// FILE: snapshot_question_model.dart
// MÔ TẢ: Immutable snapshot of a question for quiz submission
// This ensures questions won't change even if question bank is updated
// ========================================

class SnapshotQuestionModel {
  final String id; // Original question ID
  final String question; // Question text
  final String type; // 'multiple_choice', 'true_false', etc.
  final List<String> options; // Answer options (A, B, C, D)
  final int correctAnswer; // Index of correct answer (0, 1, 2, 3)
  final String? explanation; // Explanation for the answer
  final String difficulty; // 'easy', 'medium', 'hard'

  const SnapshotQuestionModel({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    required this.difficulty,
  });

  // ========================================
  // HÀM: fromMap()
  // MÔ TẢ: Create SnapshotQuestionModel from Map (Firestore data)
  // ========================================
  factory SnapshotQuestionModel.fromMap(Map<String, dynamic> map) {
    // Parse options - can be either List<String> or List<Map> (from Cloud Function)
    List<String> parsedOptions = [];
    final optionsRaw = map['options'];

    if (optionsRaw is List) {
      for (var option in optionsRaw) {
        if (option is String) {
          parsedOptions.add(option);
        } else if (option is Map) {
          // Option is an object with {id, text, isCorrect}
          parsedOptions.add(option['text']?.toString() ?? '');
        }
      }
    }

    // Parse correctAnswer - can be int (index) or String (option_id)
    int correctAnswerIndex = 0;
    final correctAnswerRaw = map['correctAnswer'];

    if (correctAnswerRaw is int) {
      correctAnswerIndex = correctAnswerRaw;
    } else if (correctAnswerRaw is String && optionsRaw is List) {
      // Find index of option with matching id
      for (int i = 0; i < optionsRaw.length; i++) {
        if (optionsRaw[i] is Map && optionsRaw[i]['id'] == correctAnswerRaw) {
          correctAnswerIndex = i;
          break;
        }
      }
    }

    return SnapshotQuestionModel(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      type: map['type'] ?? 'multiple_choice',
      options: parsedOptions,
      correctAnswer: correctAnswerIndex,
      explanation: map['explanation'],
      difficulty: map['difficulty'] ?? 'medium',
    );
  }

  // ========================================
  // HÀM: toMap()
  // MÔ TẢ: Convert SnapshotQuestionModel to Map for Firestore
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'type': type,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty,
    };
  }

  // ========================================
  // HÀM: copyWith()
  // MÔ TẢ: Create a copy with some fields modified
  // ========================================
  SnapshotQuestionModel copyWith({
    String? id,
    String? question,
    String? type,
    List<String>? options,
    int? correctAnswer,
    String? explanation,
    String? difficulty,
  }) {
    return SnapshotQuestionModel(
      id: id ?? this.id,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  @override
  String toString() {
    return 'SnapshotQuestionModel(id: $id, question: $question, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SnapshotQuestionModel &&
        other.id == id &&
        other.question == question &&
        other.type == type &&
        other.correctAnswer == correctAnswer &&
        other.difficulty == difficulty;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        question.hashCode ^
        type.hashCode ^
        correctAnswer.hashCode ^
        difficulty.hashCode;
  }
}
