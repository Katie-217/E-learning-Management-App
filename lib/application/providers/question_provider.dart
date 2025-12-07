// ========================================
// FILE: question_provider.dart
// MÔ TẢ: Riverpod providers cho Question Bank
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/question_model.dart';
import 'package:elearning_management_app/data/repositories/question/question_repository.dart';

// ========================================
// PROVIDER: questionStreamProvider
// MÔ TẢ: Stream câu hỏi theo courseCode
// QUAN TRỌNG: Dùng courseCode để tái sử dụng giữa các học kỳ
// ========================================
final questionStreamProvider =
    StreamProvider.family<List<QuestionModel>, String>((ref, courseCode) {
  return QuestionRepository.streamQuestionsByCourseCode(courseCode);
});

// ========================================
// PROVIDER: filteredQuestionsProvider
// MÔ TẢ: Lọc câu hỏi theo difficulty và search query
// ========================================
final filteredQuestionsProvider = Provider.family<
    List<QuestionModel>,
    ({
      String courseCode,
      String? difficulty,
      String searchQuery,
    })>((ref, params) {
  final questionsAsync = ref.watch(questionStreamProvider(params.courseCode));

  return questionsAsync.when(
    data: (questions) {
      var filtered = questions;

      // Filter by difficulty
      if (params.difficulty != null && params.difficulty != 'all') {
        filtered = filtered
            .where((q) => q.difficulty.name == params.difficulty)
            .toList();
      }

      // Filter by search query
      if (params.searchQuery.isNotEmpty) {
        final query = params.searchQuery.toLowerCase();
        filtered = filtered
            .where((q) => q.question.toLowerCase().contains(query))
            .toList();
      }

      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ========================================
// PROVIDER: questionCountProvider
// MÔ TẢ: Đếm số câu hỏi theo courseCode và difficulty
// ========================================
final questionCountProvider =
    Provider.family<Map<String, int>, String>((ref, courseCode) {
  final questionsAsync = ref.watch(questionStreamProvider(courseCode));

  return questionsAsync.when(
    data: (questions) {
      return {
        'all': questions.length,
        'easy': questions
            .where((q) => q.difficulty == QuestionDifficulty.easy)
            .length,
        'medium': questions
            .where((q) => q.difficulty == QuestionDifficulty.medium)
            .length,
        'hard': questions
            .where((q) => q.difficulty == QuestionDifficulty.hard)
            .length,
      };
    },
    loading: () => {'all': 0, 'easy': 0, 'medium': 0, 'hard': 0},
    error: (_, __) => {'all': 0, 'easy': 0, 'medium': 0, 'hard': 0},
  );
});
