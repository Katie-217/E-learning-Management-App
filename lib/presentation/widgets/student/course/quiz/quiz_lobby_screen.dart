// ========================================
// FILE: quiz_lobby_screen.dart
// MÔ TẢ: Màn hình sảnh chờ trước khi làm quiz
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/quiz_model.dart';
import 'package:elearning_management_app/domain/models/quiz_submission_model.dart';
import 'package:elearning_management_app/data/repositories/quiz/quiz_submission_repository.dart';
import 'package:elearning_management_app/application/providers/quiz_submission_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'quiz_active_screen.dart';

// Provider to get student's quiz attempts
final studentQuizAttemptsProvider =
    FutureProvider.family<List<QuizSubmissionModel>, String>(
  (ref, quizId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final repository = QuizSubmissionRepository();
    return repository.getStudentAttempts(
      quizId: quizId,
      studentId: currentUser.uid,
    );
  },
);

class QuizLobbyScreen extends ConsumerWidget {
  final Quiz quiz;
  final String courseId;

  const QuizLobbyScreen({
    super.key,
    required this.quiz,
    required this.courseId,
  });

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes minutes';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours hour${hours > 1 ? 's' : ''}';
    return '$hours hour${hours > 1 ? 's' : ''} $mins min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final now = DateTime.now();
    final canStart = quiz.openDate != null &&
        now.isAfter(quiz.openDate!) &&
        (quiz.closeDate == null || now.isBefore(quiz.closeDate!));

    // Get student's attempts
    final attemptsAsync = ref.watch(studentQuizAttemptsProvider(quiz.id));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title:
            const Text('Quiz Details', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: attemptsAsync.when(
        data: (attempts) =>
            _buildContent(context, ref, isDesktop, now, canStart, attempts),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading attempts: $error',
              style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    bool isDesktop,
    DateTime now,
    bool canStart,
    List<QuizSubmissionModel> attempts,
  ) {
    // Calculate attempts info
    final completedAttempts =
        attempts.where((a) => a.status == 'completed').toList();
    final attemptsUsed = completedAttempts.length;
    final maxAttempts = quiz.maxAttempts ?? 1;
    final hasAttemptsLeft = attemptsUsed < maxAttempts;
    final bestScore = completedAttempts.isEmpty
        ? null
        : completedAttempts
            .map((a) => a.score ?? 0)
            .reduce((a, b) => a > b ? a : b);

    return Center(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 32 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Quiz Title Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[700]!, Colors.green[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.quiz_outlined,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quiz.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${quiz.totalQuestions} Questions',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (quiz.description != null &&
                        quiz.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        quiz.description!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Score & Attempts Card (if has attempts)
              if (completedAttempts.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emoji_events,
                              color: Colors.amber, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Your Performance',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _QuizLobbyHelper.buildStatCard(
                              label: 'Best Score',
                              value:
                                  '${bestScore?.toStringAsFixed(1) ?? '0'} / ${quiz.points ?? 100}',
                              icon: Icons.star,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuizLobbyHelper.buildStatCard(
                              label: 'Attempts',
                              value: '$attemptsUsed / $maxAttempts',
                              icon: Icons.repeat,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Quiz Information
              _buildInfoCard(
                icon: Icons.schedule,
                title: 'Time Schedule',
                items: [
                  _InfoItem(
                    label: 'Opens',
                    value: quiz.openDate != null
                        ? _formatDateTime(quiz.openDate!)
                        : 'N/A',
                    icon: Icons.play_circle_outline,
                    color: Colors.blue,
                  ),
                  if (quiz.closeDate != null)
                    _InfoItem(
                      label: 'Closes',
                      value: _formatDateTime(quiz.closeDate!),
                      icon: Icons.stop_circle_outlined,
                      color: Colors.red,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Quiz Settings
              _buildInfoCard(
                icon: Icons.settings_outlined,
                title: 'Quiz Rules',
                items: [
                  _InfoItem(
                    label: 'Duration',
                    value: quiz.durationMinutes != null
                        ? _formatDuration(quiz.durationMinutes!)
                        : 'N/A',
                    icon: Icons.timer_outlined,
                    color: Colors.orange,
                  ),
                  _InfoItem(
                    label: 'Attempts Allowed',
                    value: quiz.maxAttempts.toString(),
                    icon: Icons.repeat,
                    color: Colors.purple,
                  ),
                  _InfoItem(
                    label: 'Total Points',
                    value: '${quiz.points ?? 100}',
                    icon: Icons.grade_outlined,
                    color: Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Status Banner
              if (!canStart || !hasAttemptsLeft) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          !hasAttemptsLeft
                              ? 'You have used all $maxAttempts attempts for this quiz'
                              : quiz.openDate != null &&
                                      now.isBefore(quiz.openDate!)
                                  ? 'Quiz will open on ${_formatDateTime(quiz.openDate!)}'
                                  : quiz.closeDate != null
                                      ? 'Quiz closed on ${_formatDateTime(quiz.closeDate!)}'
                                      : 'Quiz is not available',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Start Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (canStart && hasAttemptsLeft)
                      ? () => _startQuiz(context, ref)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    disabledBackgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: (canStart && hasAttemptsLeft) ? 8 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        (canStart && hasAttemptsLeft)
                            ? Icons.play_arrow
                            : Icons.lock_outline,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        (canStart && hasAttemptsLeft)
                            ? 'START ATTEMPT'
                            : !hasAttemptsLeft
                                ? 'NO ATTEMPTS LEFT'
                                : 'QUIZ NOT AVAILABLE',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: Colors.yellow[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Instructions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstruction('Read each question carefully'),
                    _buildInstruction('Select one answer per question'),
                    _buildInstruction('You can navigate between questions'),
                    _buildInstruction('Submit before time runs out'),
                    _buildInstruction('Timer will auto-submit when expired'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<_InfoItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[400], size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, color: item.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.green[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startQuiz(BuildContext context, WidgetRef ref) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Call Cloud Function to start quiz
      final result = await ref.read(quizSubmissionRepositoryProvider).startQuiz(
            quizId: quiz.id,
            courseId: courseId,
          );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Navigate to quiz taking screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizActiveScreen(
            submissionId: result['submissionId'] as String,
            courseId: courseId,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to start quiz: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _InfoItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _QuizLobbyHelper {
  static Widget buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
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
          ),
        ],
      ),
    );
  }
}
