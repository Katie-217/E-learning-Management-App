// presentation/widgets/instructor/upcoming_tasks_section.dart
import 'package:flutter/material.dart';
import 'task_item.dart';

class UpcomingTasksSection extends StatelessWidget {
  const UpcomingTasksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Tasks',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TaskItem(title: 'Grade Assignment #5', course: 'CS450', color: Colors.blue, isUrgent: true),
          const SizedBox(height: 8),
          TaskItem(title: 'Prepare Lecture Notes', course: 'CS380', color: Colors.green, isUrgent: false),
          const SizedBox(height: 8),
          TaskItem(title: 'Review Student Submissions', course: 'CS420', color: Colors.purple, isUrgent: false),
        ],
      ),
    );
  }
}