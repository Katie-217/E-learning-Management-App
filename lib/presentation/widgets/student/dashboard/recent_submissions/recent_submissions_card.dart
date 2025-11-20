import 'package:flutter/material.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/common/student_dashboard_card.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/common/student_dashboard_models.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/recent_submissions/components/recent_submission_tile.dart';

class RecentSubmissionsCard extends StatelessWidget {
  final List<SubmissionItem> submissions;

  const RecentSubmissionsCard({
    super.key,
    required this.submissions,
  });

  @override
  Widget build(BuildContext context) {
    return StudentDashboardCard(
      title: 'Recent Submissions',
      child: submissions.isEmpty
          ? const _EmptyState(message: 'No recent submissions available.')
          : Column(
              children: submissions
                  .map(
                    (submission) => RecentSubmissionTile(item: submission),
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

