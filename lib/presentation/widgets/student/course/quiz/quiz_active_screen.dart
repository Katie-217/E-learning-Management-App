// ========================================
// FILE: quiz_active_screen.dart
// MÔ TẢ: Màn hình làm bài quiz (Real-time với QuizSubmission)
// ========================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/quiz_submission_model.dart';
import 'package:elearning_management_app/domain/models/snapshot_question_model.dart';
import 'package:elearning_management_app/data/repositories/quiz/quiz_submission_repository.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';
import 'quiz_result_screen.dart';
import 'quiz_lobby_screen.dart';

// Provider for streaming submission in real-time
final quizSubmissionStreamProvider =
    StreamProvider.family<QuizSubmissionModel?, String>(
  (ref, submissionId) {
    final repository = QuizSubmissionRepository();
    return repository.streamSubmission(submissionId);
  },
);

class QuizActiveScreen extends ConsumerStatefulWidget {
  final String submissionId;
  final String courseId;

  const QuizActiveScreen({
    super.key,
    required this.submissionId,
    required this.courseId,
  });

  @override
  ConsumerState<QuizActiveScreen> createState() => _QuizActiveScreenState();
}

class _QuizActiveScreenState extends ConsumerState<QuizActiveScreen> {
  late PageController _pageController;
  Timer? _timer;
  Timer? _countdownTimer;
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Start countdown timer to refresh UI every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Rebuild to update timer display
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer(int durationMinutes) {
    _timer?.cancel();
    _timer = Timer(Duration(minutes: durationMinutes), () {
      if (mounted && !_isSubmitting) {
        _autoSubmit();
      }
    });
  }

  Future<void> _autoSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final repository = QuizSubmissionRepository();
      final score = await repository.submitQuiz(
        submissionId: widget.submissionId,
        isAutoSubmitted: true,
      );

      if (!mounted) return;

      // Navigate to result screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            submissionId: widget.submissionId,
            score: score,
            courseId: widget.courseId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-submit failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Quiz?'),
        content: const Text('Are you sure you want to submit your answers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      // Get submission to access quizId
      final submissionAsync =
          ref.read(quizSubmissionStreamProvider(widget.submissionId));
      final submission = submissionAsync.value;

      final repository = QuizSubmissionRepository();
      final score = await repository.submitQuiz(
        submissionId: widget.submissionId,
        isAutoSubmitted: false,
      );

      if (!mounted) return;

      // Invalidate attempts provider to refresh lobby screen
      final quizId = submission?.quizId ?? '';
      if (quizId.isNotEmpty) {
        ref.invalidate(studentQuizAttemptsProvider(quizId));
      }

      // Show success and go back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Quiz submitted! Score: ${score.toStringAsFixed(1)} points'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submit failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateAnswer(String questionId, int answerIndex) async {
    try {
      final repository = QuizSubmissionRepository();
      await repository.updateAnswer(
        submissionId: widget.submissionId,
        questionId: questionId,
        answerIndex: answerIndex,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save answer: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionAsync =
        ref.watch(quizSubmissionStreamProvider(widget.submissionId));

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

          // Timer handled by duration from start time
          // Auto-submit will be triggered by timer

          return _buildQuizContent(submission);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizContent(QuizSubmissionModel submission) {
    final questions = submission.questions;

    if (questions.isEmpty) {
      return const Center(
        child: Text('No questions available',
            style: TextStyle(color: Colors.white)),
      );
    }

    return Column(
      children: [
        // Header with timer
        _buildHeader(submission),

        // Question navigator
        _buildQuestionNavigator(questions, submission.answers),

        // Current question
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentQuestionIndex = index);
            },
            itemCount: questions.length,
            itemBuilder: (context, index) {
              return _buildQuestionCard(
                questions[index],
                submission.answers[questions[index].id],
              );
            },
          ),
        ),

        // Navigation buttons
        _buildNavigationButtons(questions.length),
      ],
    );
  }

  Widget _buildHeader(QuizSubmissionModel submission) {
    // Default 45 minutes duration
    final defaultDuration = const Duration(minutes: 45);
    final elapsed = DateTime.now().difference(submission.startedAt);
    final remaining = defaultDuration - elapsed;
    final minutes = remaining.inMinutes.clamp(0, 999);
    final seconds = (remaining.inSeconds % 60).clamp(0, 59);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.withOpacity(0.1),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Exit Quiz?'),
                    content: const Text('Your progress will be saved'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Exit'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Quiz ${submission.quizId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Attempt ${submission.attemptNumber}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: remaining.inMinutes < 5 ? Colors.red : Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$minutes:${seconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionNavigator(
    List<SnapshotQuestionModel> questions,
    Map<String, int> answers,
  ) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final isAnswered = answers.containsKey(questions[index].id);
          final isCurrent = index == _currentQuestionIndex;

          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isCurrent
                    ? Colors.blue
                    : isAnswered
                        ? Colors.green.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrent
                      ? Colors.blue
                      : isAnswered
                          ? Colors.green
                          : Colors.grey,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isCurrent || isAnswered
                        ? Colors.white
                        : Colors.grey[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard(
      SnapshotQuestionModel question, int? selectedAnswer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: const Color(0xFF1E293B),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question number and difficulty
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Question ${_currentQuestionIndex + 1}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(question.difficulty)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      question.difficulty.toUpperCase(),
                      style: TextStyle(
                        color: _getDifficultyColor(question.difficulty),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Question text
              Text(
                question.question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Answer options
              ...List.generate(question.options.length, (index) {
                final isSelected = selectedAnswer == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: _isSubmitting
                        ? null
                        : () => _updateAnswer(question.id, index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? Colors.blue : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.grey,
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
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[300],
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(int totalQuestions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;

            return Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 16,
                          horizontal: isSmallScreen ? 8 : 16,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back,
                            size: isSmallScreen ? 18 : 20,
                          ),
                          if (!isSmallScreen || constraints.maxWidth > 400) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Previous',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                if (_currentQuestionIndex > 0)
                  SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : _currentQuestionIndex < totalQuestions - 1
                            ? () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _currentQuestionIndex < totalQuestions - 1
                              ? Colors.blue
                              : Colors.green,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 12 : 16,
                        horizontal: isSmallScreen ? 8 : 16,
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: isSmallScreen ? 18 : 20,
                            width: isSmallScreen ? 18 : 20,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _currentQuestionIndex < totalQuestions - 1
                                      ? 'Next'
                                      : 'Submit Quiz',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_currentQuestionIndex <
                                  totalQuestions - 1) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  size: isSmallScreen ? 18 : 20,
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
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
