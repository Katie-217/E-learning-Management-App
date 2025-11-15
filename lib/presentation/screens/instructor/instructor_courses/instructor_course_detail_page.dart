import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/presentation/screens/course/Student_Course/detail/course_detail.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/instructor_course_tabs_widget.dart';

class InstructorCourseDetailPage extends ConsumerStatefulWidget {
  final String courseId;

  const InstructorCourseDetailPage({
    super.key,
    required this.courseId,
  });

  @override
  ConsumerState<InstructorCourseDetailPage> createState() =>
      _InstructorCourseDetailPageState();
}

class _InstructorCourseDetailPageState
    extends ConsumerState<InstructorCourseDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock course data - replace with actual data from provider
  late final CourseModel _course = CourseModel(
    id: widget.courseId,
    name: 'Lập trình Flutter',
    code: 'IT001',
    instructor: 'Dr. Johnson',
    semester: 'HK1/24-25',
    sessions: 0,
    progress: 0,
    description: 'Cross-platform mobile development with Flutter',
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      body: Column(
        children: [
          // Course Header
          CourseDetailHeader(
            course: _course,
            onBack: () => Navigator.pop(context),
          ),

          // Course Tabs (Stream, Classwork, People)
          Expanded(
            child: InstructorCourseTabsWidget(
              tabController: _tabController,
              course: _course,
            ),
          ),
        ],
      ),
    );
  }
}
