import 'package:flutter/material.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/common/student_dashboard_models.dart';

class RecentSubmissionTile extends StatelessWidget {
  final SubmissionItem item;
  
  const RecentSubmissionTile({
    super.key,
    required this.item,
  });

  Color get _statusColor {
    switch (item.status) {
      case DashboardSubmissionStatus.onTime:
        return const Color(0xFF34D399); // Green
      case DashboardSubmissionStatus.early:
        return const Color(0xFFFFB347); // Orange
      case DashboardSubmissionStatus.late:
        return const Color(0xFFFF6B6B); // Red
    }
  }

  String get _statusLabel {
    switch (item.status) {
      case DashboardSubmissionStatus.onTime:
        return 'On time';
      case DashboardSubmissionStatus.early:
        return 'Early';
      case DashboardSubmissionStatus.late:
        return 'Late';
    }
  }

  IconData get _icon {
    switch (item.type) {
      case DashboardSubmissionType.assignment:
        return Icons.assignment_outlined;
      case DashboardSubmissionType.quiz:
        return Icons.quiz_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _icon,
              color: _statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item.timeLabel,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chevron_right),
            color: Colors.white54,
          ),
        ],
      ),
    );
  }
}

