import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/presentation/widgets/student/course/people/people_tab.dart';

class StudentCoursePeoplePage extends StatelessWidget {
  final CourseModel course;

  const StudentCoursePeoplePage({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'People',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: PeopleTab(course: course),
    );
  }
}

