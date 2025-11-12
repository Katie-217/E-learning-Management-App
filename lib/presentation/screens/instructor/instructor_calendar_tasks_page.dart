import 'package:flutter/material.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/calendar_widget.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/task_list_widget.dart';

class InstructorCalendarTasksPage extends StatelessWidget {
  const InstructorCalendarTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Section
            const CalendarWidget(),
            const SizedBox(height: 24),
            // Tasks Section
            const TaskListWidget(),
          ],
        ),
      ),
    );
  }
}

