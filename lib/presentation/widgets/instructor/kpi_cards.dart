import 'package:flutter/material.dart';
import 'package:elearning_management_app/application/controllers/instructor/instructor_kpi_provider.dart';

class InstructorKPICards extends StatelessWidget {
  final InstructorKPIStats stats;

  const InstructorKPICards({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 1200
            ? 5
            : constraints.maxWidth > 900
                ? 3
                : constraints.maxWidth > 600
                    ? 2
                    : 1;

        return GridView.count(
          crossAxisCount: crossCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _InstructorKPICard(
              title: 'Courses',
              value: stats.coursesCount.toString(),
              description: 'Total number of courses in the selected semester',
              icon: Icons.menu_book_outlined,
              bgStart: const Color(0xFF6366F1),
              bgEnd: const Color(0xFF8B5CF6),
              iconColor: const Color(0xFFACAFFF),
            ),
            _InstructorKPICard(
              title: 'Groups',
              value: stats.groupsCount.toString(),
              description: 'Total groups across all courses this semester',
              icon: Icons.groups_outlined,
              bgStart: const Color(0xFF10B981),
              bgEnd: const Color(0xFF34D399),
              iconColor: const Color(0xFF6EE7B7),
            ),
            _InstructorKPICard(
              title: 'Students',
              value: stats.studentsCount.toString(),
              description: 'Total students managed in the current semester',
              icon: Icons.people_outlined,
              bgStart: const Color(0xFFF97316),
              bgEnd: const Color(0xFFFFB347),
              iconColor: const Color(0xFFFFE0B5),
            ),
            _InstructorKPICard(
              title: 'Assignments',
              value: stats.assignmentsCount.toString(),
              description:
                  'Count of all assignments across courses this semester',
              icon: Icons.assignment_outlined,
              bgStart: const Color(0xFFFF6B6B),
              bgEnd: const Color(0xFFFF8E72),
              iconColor: const Color(0xFFFFD6D6),
            ),
            _InstructorKPICard(
              title: 'Quizzes',
              value: stats.quizzesCount.toString(),
              description: 'Total number of quizzes for this semester',
              icon: Icons.quiz_outlined,
              bgStart: const Color(0xFF0EA5E9),
              bgEnd: const Color(0xFF38BDF8),
              iconColor: const Color(0xFFBEE8FF),
            ),
          ],
        );
      },
    );
  }
}

class _InstructorKPICard extends StatelessWidget {
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color bgStart;
  final Color bgEnd;
  final Color iconColor;

  const _InstructorKPICard({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.bgStart,
    required this.bgEnd,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = bgStart.withValues(alpha: 0.3);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgStart.withValues(alpha: 0.18), bgEnd.withValues(alpha: 0.18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgStart.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey[300], fontSize: 23),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 33, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

