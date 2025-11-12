import 'package:flutter/material.dart';
import 'upcoming_widget.dart';
import 'classwork_tab.dart';
import 'people_tab.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'stream_tab.dart';

class CourseTabsWidget extends StatelessWidget {
  final TabController tabController;
  final CourseModel course;

  const CourseTabsWidget(
      {super.key, required this.tabController, required this.course});

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
              StreamTab(course: course),
              const ClassworkTab(),
              const PeopleTab(),
            ],
          ),
        ),
      ],
    );
  }
}
