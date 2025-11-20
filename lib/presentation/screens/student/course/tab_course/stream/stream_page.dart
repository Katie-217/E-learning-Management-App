import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/presentation/widgets/student/course/stream/stream_tab.dart';

class StudentCourseStreamPage extends StatelessWidget {
  final CourseModel course;

  const StudentCourseStreamPage({
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
          'Stream',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamTab(course: course),
    );
  }
}

