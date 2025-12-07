// ========================================
// FILE: quiz_result_screen.dart
// MÔ TẢ: Màn hình hiển thị kết quả quiz sau khi submit
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/quiz_submission_model.dart';
import 'package:elearning_management_app/domain/models/snapshot_question_model.dart';
import 'package:elearning_management_app/data/repositories/quiz/quiz_submission_repository.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

// Provider to fetch submission details
final submissionDetailProvider =
    FutureProvider.family<QuizSubmissionModel?, String>(
  (ref, submissionId) async {
    final repository = QuizSubmissionRepository();
    return await repository.getSubmission(submissionId);
  },
);

class QuizResultScreen extends ConsumerWidget {
  final String submissionId;
  final double score;
  final String courseId;

  const QuizResultScreen({
    super.key,
    required this.submissionId,
    required this.score,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionAsync = ref.watch(submissionDetailProvider(submissionId));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: submissionAsync.when(
        data: (submission) {
          if (submission == null) {
            return const Center(
              child: Text('Submission not found',
                  style: TextStyle(color: Colors.white)),
            );
          }
          return _buildResultContent(context, submission);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Error loading results: $error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultContent(
      BuildContext context, QuizSubmissionModel submission) {
    final isPassed = submission.score! >= 70; // Assuming 70% is passing score
    final correctAnswers = _countCorrectAnswers(submission);
    final totalQuestions = submission.questions.length;
    final timeSpent = Duration(seconds: submission.timeSpentSeconds);

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: isPassed ? Colors.green : Colors.red,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isPassed
                      ? [Colors.green.shade700, Colors.green.shade500]
                      : [Colors.red.shade700, Colors.red.shade500],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPassed
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isPassed ? 'Congratulations!' : 'Keep Trying!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPassed
                          ? 'You passed the quiz'
                          : 'You did not pass this time',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Results Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Score Card
                _buildScoreCard(
                    submission.score!, correctAnswers, totalQuestions),

                const SizedBox(height: 16),

                // Stats Grid
                _buildStatsGrid(submission, timeSpent),

                const SizedBox(height: 24),

                // Review Section Header
                const Text(
                  'Question Review',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Questions Review
                ...List.generate(
                  submission.questions.length,
                  (index) => _buildQuestionReviewCard(
                    index + 1,
                    submission.questions[index],
                    submission.answers[submission.questions[index].id],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(context, submission),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard(double score, int correct, int total) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '${score.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Score',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$correct correct',
                  style: const TextStyle(color: Colors.green, fontSize: 16),
                ),
                const SizedBox(width: 24),
                Icon(Icons.cancel, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${total - correct} incorrect',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(QuizSubmissionModel submission, Duration timeSpent) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.timer_outlined,
            'Time Spent',
            _formatDuration(timeSpent),
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.repeat,
            'Attempt',
            '#${submission.attemptNumber}',
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.quiz_outlined,
            'Questions',
            '${submission.questions.length}',
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      IconData icon, String label, String value, Color color) {
    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionReviewCard(
    int questionNumber,
    SnapshotQuestionModel question,
    int? selectedAnswer,
  ) {
    final isCorrect = selectedAnswer == question.correctAnswer;
    final wasAnswered = selectedAnswer != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green.withOpacity(0.2)
                        : wasAnswered
                            ? Colors.red.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Q$questionNumber',
                    style: TextStyle(
                      color: isCorrect
                          ? Colors.green
                          : wasAnswered
                              ? Colors.red
                              : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  isCorrect
                      ? Icons.check_circle
                      : wasAnswered
                          ? Icons.cancel
                          : Icons.help_outline,
                  color: isCorrect
                      ? Colors.green
                      : wasAnswered
                          ? Colors.red
                          : Colors.grey,
                  size: 24,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(question.difficulty)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    question.difficulty.toUpperCase(),
                    style: TextStyle(
                      color: _getDifficultyColor(question.difficulty),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question Text
            Text(
              question.question,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Options
            ...List.generate(question.options.length, (index) {
              final isSelected = selectedAnswer == index;
              final isCorrectOption = index == question.correctAnswer;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCorrectOption
                      ? Colors.green.withOpacity(0.15)
                      : isSelected && !isCorrect
                          ? Colors.red.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCorrectOption
                        ? Colors.green
                        : isSelected && !isCorrect
                            ? Colors.red
                            : Colors.grey.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCorrectOption
                            ? Colors.green
                            : isSelected && !isCorrect
                                ? Colors.red
                                : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCorrectOption
                              ? Colors.green
                              : isSelected && !isCorrect
                                  ? Colors.red
                                  : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: TextStyle(
                            color: isCorrectOption || (isSelected && !isCorrect)
                                ? Colors.white
                                : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.options[index],
                        style: TextStyle(
                          color: isCorrectOption || (isSelected && !isCorrect)
                              ? Colors.white
                              : Colors.grey[300],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isCorrectOption)
                      const Icon(Icons.check, color: Colors.green, size: 20),
                    if (isSelected && !isCorrect)
                      const Icon(Icons.close, color: Colors.red, size: 20),
                  ],
                ),
              );
            }),

            // Explanation (if available)
            if (question.explanation != null &&
                question.explanation!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.explanation!,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, QuizSubmissionModel submission) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Navigate back to course (pop all quiz screens)
              Navigator.popUntil(context,
                  (route) => route.isFirst || route.settings.name == '/course');
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Course'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate back to lobby to retry
              Navigator.pop(context);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  int _countCorrectAnswers(QuizSubmissionModel submission) {
    int count = 0;
    for (var question in submission.questions) {
      final selectedAnswer = submission.answers[question.id];
      if (selectedAnswer != null && selectedAnswer == question.correctAnswer) {
        count++;
      }
    }
    return count;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
