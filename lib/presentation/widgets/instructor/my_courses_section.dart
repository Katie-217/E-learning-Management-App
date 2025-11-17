// presentation/widgets/instructor/my_courses_section.dart
import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'course_card.dart';

class MyCoursesSection extends StatelessWidget {
  const MyCoursesSection({super.key});

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
            'My Courses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          CourseCard(
            course: CourseModel(
              id: 'cs450',
              code: 'CS450',
              name: 'Advanced Web Development',
              instructor: 'Dr. Smith',
              semester: 'Fall 2025',
              sessions: 30,
              students: 45,
              progress: 60,
              credits: 3,
              status: 'active',
              imageUrl: 'https://example.com/images/web_dev.jpg',
            ),
            onTap: () {},
          ),
          const SizedBox(height: 8),
          CourseCard(
            course: CourseModel(
              id: 'cs380',
              code: 'CS380',
              name: 'Database Systems',
              instructor: 'Prof. Johnson',
              semester: 'Fall 2025',
              sessions: 28,
              students: 38,
              progress: 45,
              credits: 4,
              status: 'active',
              imageUrl: 'https://example.com/images/database.jpg',
            ),
            onTap: () {},
          ),
          const SizedBox(height: 8),
          CourseCard(
            course: CourseModel(
              id: 'cs420',
              code: 'CS420',
              name: 'Software Engineering',
              instructor: 'Dr. Williams',
              semester: 'Fall 2025',
              sessions: 32,
              students: 32,
              progress: 75,
              credits: 3,
              status: 'active',
              imageUrl: 'https://example.com/images/software_eng.jpg',
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}