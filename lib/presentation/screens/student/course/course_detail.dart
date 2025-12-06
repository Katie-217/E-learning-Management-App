import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';

class CourseDetailHeader extends StatelessWidget {
  final CourseModel course;
  final VoidCallback? onBack;

  const CourseDetailHeader({super.key, required this.course, this.onBack});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmall = screenWidth < 600;
        final padding = isSmall 
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 24);
        final titleSize = isSmall ? 20.0 : 24.0;
        final subtitleSize = isSmall ? 12.0 : 14.0;
        final spacing = isSmall ? 8.0 : 12.0;
        
        return Container(
          padding: padding,
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
                      icon: Icon(
                        Icons.arrow_back, 
                        color: Colors.white,
                        size: isSmall ? 20 : 24,
                      ),
                      tooltip: 'Quay lại danh sách',
                      padding: EdgeInsets.all(isSmall ? 4 : 8),
                      constraints: BoxConstraints(
                        minWidth: isSmall ? 32 : 48,
                        minHeight: isSmall ? 32 : 48,
                      ),
                    ),
                    SizedBox(width: isSmall ? 4 : 8),
                  ],
                ),
              SizedBox(height: spacing),
              Text(
                course.name,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmall ? 4 : 6),
              Text(
                '${course.code} • ${course.semester} • ${course.sessions} Sessions',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: subtitleSize,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmall ? 6 : 8),
              Wrap(
                spacing: isSmall ? 6 : 8,
                runSpacing: isSmall ? 4 : 6,
                children: [
                  _tag(Icons.person, course.instructor, isSmall),
                  // Group info will be loaded separately from GroupRepository
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tag(IconData icon, String label, bool isSmall) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 8 : 10, 
          vertical: isSmall ? 4 : 6,
        ),
        decoration: BoxDecoration(
            color: Colors.white24, borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: isSmall ? 14 : 16),
          SizedBox(width: isSmall ? 3 : 4),
          Text(
            label, 
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmall ? 11 : 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ]),
      );
}
