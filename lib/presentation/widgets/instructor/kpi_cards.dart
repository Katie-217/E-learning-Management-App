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
        final screenWidth = MediaQuery.of(context).size.width;
        final isNarrow = constraints.maxWidth < 600;
        final spacing = screenWidth > 600 ? 12.0 : screenWidth > 400 ? 8.0 : 6.0;
        
        final cards = [
          _InstructorKPICard(
            title: 'Courses',
            value: stats.coursesCount.toString(),
            icon: Icons.menu_book_outlined,
            bgStart: const Color(0xFF6366F1),
            bgEnd: const Color(0xFF8B5CF6),
            iconColor: const Color(0xFFACAFFF),
          ),
          _InstructorKPICard(
            title: 'Groups',
            value: stats.groupsCount.toString(),
            icon: Icons.groups_outlined,
            bgStart: const Color(0xFF10B981),
            bgEnd: const Color(0xFF34D399),
            iconColor: const Color(0xFF6EE7B7),
          ),
          _InstructorKPICard(
            title: 'Students',
            value: stats.studentsCount.toString(),
            icon: Icons.people_outlined,
            bgStart: const Color(0xFFF97316),
            bgEnd: const Color(0xFFFFB347),
            iconColor: const Color(0xFFFFE0B5),
          ),
          _InstructorKPICard(
            title: 'Assignments',
            value: stats.assignmentsCount.toString(),
            icon: Icons.assignment_outlined,
            bgStart: const Color(0xFFFF6B6B),
            bgEnd: const Color(0xFFFF8E72),
            iconColor: const Color(0xFFFFD6D6),
          ),
          _InstructorKPICard(
            title: 'Quizzes',
            value: stats.quizzesCount.toString(),
            icon: Icons.quiz_outlined,
            bgStart: const Color(0xFF0EA5E9),
            bgEnd: const Color(0xFF38BDF8),
            iconColor: const Color(0xFFBEE8FF),
          ),
        ];

        // Trên màn hình nhỏ, hiển thị dạng Column như bên học sinh
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cards
                .map((card) => Padding(
                      padding: EdgeInsets.only(bottom: spacing),
                      child: card,
                    ))
                .toList(),
          );
        }

        // Trên màn hình lớn, dùng GridView
        final crossCount = constraints.maxWidth > 1200
            ? 5
            : constraints.maxWidth > 900
                ? 3
                : 2;
        final childAspectRatio = 1.2;

        return GridView.count(
          crossAxisCount: crossCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }
}

class _InstructorKPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color bgStart;
  final Color bgEnd;
  final Color iconColor;

  const _InstructorKPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.bgStart,
    required this.bgEnd,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;
    final isXSmall = screenWidth < 400;
    
    // Responsive sizing - giống bên học sinh
    final cardHeight = isXSmall
        ? 80.0
        : isSmall
            ? 90.0
            : 120.0;
    final iconBox = isXSmall ? 32.0 : isSmall ? 36.0 : 40.0;
    final titleSize = isXSmall ? 14.0 : isSmall ? 16.0 : 20.0;
    final valueSize = isXSmall ? 24.0 : isSmall ? 28.0 : 32.0;
    final padding = isXSmall ? 12.0 : isSmall ? 14.0 : 16.0;
    final iconSpacing = isXSmall ? 8.0 : isSmall ? 10.0 : 12.0;
    
    final borderColor = bgStart.withValues(alpha: 0.3);
    return SizedBox(
      height: cardHeight,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgStart.withValues(alpha: 0.18), bgEnd.withValues(alpha: 0.18)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: bgStart.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: iconBox * 0.6,
                  ),
                ),
                SizedBox(width: iconSpacing),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: titleSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

