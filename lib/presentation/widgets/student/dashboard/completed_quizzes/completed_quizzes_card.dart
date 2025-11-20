import 'package:flutter/material.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/common/student_dashboard_card.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/common/student_dashboard_models.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/completed_quizzes/components/completed_quiz_tile.dart';

class CompletedQuizzesCard extends StatelessWidget {
  final List<CompletedQuizItem> quizzes;

  const CompletedQuizzesCard({
    super.key,
    required this.quizzes,
  });

  @override
  Widget build(BuildContext context) {
    return StudentDashboardCard(
      title: 'Completed Quizzes with Scores',
      child: quizzes.isEmpty
          ? const _EmptyState(message: 'No completed quizzes available.')
          : Column(
              children: quizzes
                  .map(
                    (quiz) => CompletedQuizTile(item: quiz),
                  )
                  .toList(),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

