// ========================================
// FILE: quiz_submission_provider.dart
// MÔ TẢ: Riverpod providers for quiz submission flow
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/data/repositories/quiz/quiz_submission_repository.dart';
import 'package:elearning_management_app/domain/models/quiz_submission_model.dart';

// ========================================
// REPOSITORY PROVIDER
// ========================================
final quizSubmissionRepositoryProvider =
    Provider<QuizSubmissionRepository>((ref) {
  return QuizSubmissionRepository();
});

// ========================================
// START QUIZ PROVIDER
// Calls Cloud Function to start a new quiz attempt
// ========================================
final startQuizProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, String>>(
        (ref, params) async {
  final repository = ref.watch(quizSubmissionRepositoryProvider);
  return await repository.startQuiz(
    quizId: params['quizId']!,
    courseId: params['courseId']!,
  );
});

// ========================================
// CURRENT SUBMISSION PROVIDER (Stream)
// Real-time updates for active quiz submission
// ========================================
final currentSubmissionProvider =
    StreamProvider.family<QuizSubmissionModel?, String>((ref, submissionId) {
  final repository = ref.watch(quizSubmissionRepositoryProvider);
  return repository.streamSubmission(submissionId);
});

// ========================================
// GET SUBMISSION PROVIDER (Future)
// One-time fetch of submission data
// ========================================
final getSubmissionProvider =
    FutureProvider.family<QuizSubmissionModel?, String>(
        (ref, submissionId) async {
  final repository = ref.watch(quizSubmissionRepositoryProvider);
  return await repository.getSubmission(submissionId);
});

// ========================================
// STUDENT ATTEMPTS PROVIDER
// Get all attempts for a quiz by a student
// ========================================
final studentAttemptsProvider =
    FutureProvider.family<List<QuizSubmissionModel>, Map<String, String>>(
        (ref, params) async {
  final repository = ref.watch(quizSubmissionRepositoryProvider);
  return await repository.getStudentAttempts(
    quizId: params['quizId']!,
    studentId: params['studentId']!,
  );
});

// ========================================
// IN-PROGRESS SUBMISSION PROVIDER
// Check if student has an ongoing quiz attempt
// ========================================
final inProgressSubmissionProvider =
    FutureProvider.family<QuizSubmissionModel?, Map<String, String>>(
        (ref, params) async {
  final repository = ref.watch(quizSubmissionRepositoryProvider);
  return await repository.getInProgressSubmission(
    quizId: params['quizId']!,
    studentId: params['studentId']!,
  );
});

// ========================================
// COMPLETED ATTEMPTS COUNT PROVIDER
// Count how many times student completed quiz
// ========================================
final completedAttemptsCountProvider =
    FutureProvider.family<int, Map<String, String>>((ref, params) async {
  final repository = ref.watch(quizSubmissionRepositoryProvider);
  return await repository.countCompletedAttempts(
    quizId: params['quizId']!,
    studentId: params['studentId']!,
  );
});

// ========================================
// ANSWER UPDATE NOTIFIER
// StateNotifier for updating answers during quiz
// ========================================
class AnswerUpdateNotifier extends StateNotifier<Map<String, int>> {
  final QuizSubmissionRepository repository;
  final String submissionId;

  AnswerUpdateNotifier({
    required this.repository,
    required this.submissionId,
  }) : super({});

  // Update answer locally and in Firestore
  Future<void> updateAnswer(String questionId, int answerIndex) async {
    // Update local state
    state = {...state, questionId: answerIndex};

    // Update Firestore
    try {
      await repository.updateAnswer(
        submissionId: submissionId,
        questionId: questionId,
        answerIndex: answerIndex,
      );
    } catch (e) {
      // Revert on error
      final newState = Map<String, int>.from(state);
      newState.remove(questionId);
      state = newState;
      rethrow;
    }
  }

  // Clear answer
  void clearAnswer(String questionId) {
    final newState = Map<String, int>.from(state);
    newState.remove(questionId);
    state = newState;
  }
}

// ========================================
// ANSWER UPDATE PROVIDER
// ========================================
final answerUpdateProvider = StateNotifierProvider.family<AnswerUpdateNotifier,
    Map<String, int>, String>((ref, submissionId) {
  final repository = ref.watch(quizSubmissionRepositoryProvider);
  return AnswerUpdateNotifier(
    repository: repository,
    submissionId: submissionId,
  );
});

// ========================================
// SUBMIT QUIZ NOTIFIER
// StateNotifier for quiz submission
// ========================================
class SubmitQuizNotifier extends StateNotifier<AsyncValue<double>> {
  final QuizSubmissionRepository repository;

  SubmitQuizNotifier({required this.repository})
      : super(const AsyncValue.data(0.0));

  Future<void> submitQuiz({
    required String submissionId,
    required bool isAutoSubmitted,
  }) async {
    state = const AsyncValue.loading();

    try {
      final score = await repository.submitQuiz(
        submissionId: submissionId,
        isAutoSubmitted: isAutoSubmitted,
      );
      state = AsyncValue.data(score);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ========================================
// SUBMIT QUIZ PROVIDER
// ========================================
final submitQuizProvider =
    StateNotifierProvider<SubmitQuizNotifier, AsyncValue<double>>((ref) {
  final repository = ref.watch(quizSubmissionRepositoryProvider);
  return SubmitQuizNotifier(repository: repository);
});
