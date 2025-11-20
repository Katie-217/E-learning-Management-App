import 'package:flutter/material.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/common/student_dashboard_models.dart';

class CompletedQuizTile extends StatelessWidget {
  final CompletedQuizItem item;
  
  const CompletedQuizTile({
    super.key,
    required this.item,
  });

  Color get _scoreColor {
    final percentage = item.percentage;
    if (percentage >= 90) return const Color(0xFF34D399); // Green
    if (percentage >= 70) return const Color(0xFF60A5FA); // Blue
    if (percentage >= 50) return const Color(0xFFFFB347); // Orange
    return const Color(0xFFFF6B6B); // Red
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
              color: _scoreColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.quiz_outlined,
              color: _scoreColor,
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
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.courseName,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Completed on ${item.completedDate}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _scoreColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _scoreColor.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.score}/${item.maxScore}',
                  style: TextStyle(
                    color: _scoreColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${item.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _scoreColor.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

