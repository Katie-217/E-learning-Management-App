import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';

class CourseDetailHeader extends StatelessWidget {
  final CourseModel course;
  final VoidCallback? onBack;

  const CourseDetailHeader({super.key, required this.course, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.blue, Colors.cyan]),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nút back
          if (onBack != null)
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Quay lại danh sách',
                ),
                const SizedBox(width: 8),
              ],
            ),
          const SizedBox(height: 12),
          Text(course.name,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text(
              '${course.code} • ${course.semester} • ${course.sessions} Sessions',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _tag(Icons.person, course.instructor),
              // Group info will be loaded separately from GroupRepository
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white24, borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white)),
        ]),
      );
}
