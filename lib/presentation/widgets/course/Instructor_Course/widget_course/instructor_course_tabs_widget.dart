import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import '../instructor_stream_tab.dart';
import '../../../../screens/instructor/classwork_tab/instructor_classwork_tab.dart';
import '../../../../screens/instructor/people_tab/instructor_people_tab.dart';

class InstructorCourseTabsWidget extends StatelessWidget {
  final TabController tabController;
  final CourseModel course;

  const InstructorCourseTabsWidget({
    super.key,
    required this.tabController,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF1F2937),
          child: TabBar(
            controller: tabController,
            labelColor: Colors.indigo[400],
            unselectedLabelColor: Colors.grey[400],
            indicatorColor: Colors.indigo[400],
            tabs: const [
              Tab(text: 'Stream'),
              Tab(text: 'Classwork'),
              Tab(text: 'People'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              InstructorStreamTab(course: course),
              InstructorClassworkTab(course: course),
              InstructorPeopleTab(course: course),
            ],
          ),
        ),
      ],
    );
  }
}
