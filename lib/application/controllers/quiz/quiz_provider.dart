import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/data/repositories/quiz/quiz_repository.dart';
import 'package:elearning_management_app/domain/models/quiz_model.dart';

// ========================================
// QUIZ STREAM PROVIDER BY COURSE
// ========================================
final quizStreamProvider =
    StreamProvider.family<List<Quiz>, String>((ref, courseId) {
  final quizRepository = QuizRepository();
  return quizRepository.streamQuizzesByCourse(courseId);
});

// ========================================
// QUIZ REPOSITORY PROVIDER
// ========================================
final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository();
});
