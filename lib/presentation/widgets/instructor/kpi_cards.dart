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

        // Trên màn hình lớn, dùng Row với Expanded giống bên học sinh
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cards.asMap().entries.map((entry) {
            final index = entry.key;
            final card = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < cards.length - 1 ? spacing : 0,
                ),
                child: card,
              ),
            );
          }).toList(),
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
        ? 150.0
        : isSmall
            ? 160.0
            : 170.0;
    final iconBox = isXSmall ? 32.0 : isSmall ? 36.0 : 40.0;
    final titleSize = isXSmall ? 16.0 : isSmall ? 18.0 : 22.0;
    final valueSize = isXSmall ? 26.0 : isSmall ? 28.0 : 30.0;
    final padding = isXSmall ? 12.0 : isSmall ? 16.0 : 20.0;
    final iconSpacing = isXSmall ? 8.0 : isSmall ? 10.0 : 12.0;
    
    final borderColor = bgStart.withOpacity(0.3);
    return SizedBox(
      height: cardHeight,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgStart.withOpacity(0.18), bgEnd.withOpacity(0.18)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: bgStart.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: iconBox * 0.6,
                  ),
                ),
                SizedBox(width: iconSpacing),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: titleSize,
                      height: 1.2,
                    ),
                  ),
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

