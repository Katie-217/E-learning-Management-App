import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elearning_management_app/application/controllers/instructor/task_provider.dart';
import 'package:elearning_management_app/application/controllers/student/student_dashboard_metrics_provider.dart';
import 'package:elearning_management_app/domain/models/task_model.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/calendar_widget.dart';

class StudentCalendarPanel extends ConsumerWidget {
  const StudentCalendarPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final monthKey = DateTime(selectedDate.year, selectedDate.month);
    // Sử dụng providers từ student dashboard metrics provider (dữ liệu thật từ assignments)
    final monthlyTasksAsync = ref.watch(studentTasksForMonthProvider(monthKey));
    final dailyTasksAsync = ref.watch(studentTasksForDateProvider(selectedDate));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 400;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const CalendarWidget(),
            SizedBox(height: isSmall ? 8 : 10),
            Text(
              'Ngày đã chọn: ${DateFormat('EEEE, MMM d').format(selectedDate)}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: isSmall ? 11 : 12,
              ),
            ),
            SizedBox(height: isSmall ? 8 : 10),
            monthlyTasksAsync.when(
              data: (tasks) => TaskSnapshotSummary(
                tasks: tasks,
                selectedDate: selectedDate,
                isSmall: isSmall,
              ),
              loading: () => Center(
                child: SizedBox(
                  height: isSmall ? 20 : 26,
                  width: isSmall ? 20 : 26,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, _) => Text(
                'Không thể tải dữ liệu tháng: $error',
                style: TextStyle(color: Colors.redAccent, fontSize: isSmall ? 11 : 12),
              ),
            ),
            SizedBox(height: isSmall ? 12 : 14),
            Text(
              'Upcoming Deadlines',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isSmall ? 13 : 14,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isSmall ? 8 : 10),
            dailyTasksAsync.when(
              data: (tasks) => _buildDailyTasks(tasks, isSmall),
              loading: () => Center(
                child: SizedBox(
                  height: isSmall ? 20 : 26,
                  width: isSmall ? 20 : 26,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, _) => Text(
                'Không thể tải nhiệm vụ: $error',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: isSmall ? 11 : 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDailyTasks(List<TaskModel> tasks, bool isSmall) {
    if (tasks.isEmpty) {
      return Text(
        'Không có nhiệm vụ nào cho ngày đã chọn.',
        style: TextStyle(color: Colors.white70, fontSize: isSmall ? 11 : 12),
      );
    }

    final sortedTasks = tasks.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Column(
      children: sortedTasks
          .map((task) => Padding(
                padding: EdgeInsets.only(bottom: isSmall ? 6 : 8),
                child: _TaskTile(task: task, isSmall: isSmall),
              ))
          .toList(),
    );
  }
}

class TaskSnapshotSummary extends StatelessWidget {
  final List<TaskModel> tasks;
  final DateTime selectedDate;
  final bool isSmall;

  const TaskSnapshotSummary({
    super.key,
    required this.tasks,
    required this.selectedDate,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    // Filter tasks for the selected date only
    final selectedDateKey = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    
    final dayTasks = tasks.where((task) {
      final taskDateKey = DateTime(
        task.dateTime.year,
        task.dateTime.month,
        task.dateTime.day,
      );
      return taskDateKey == selectedDateKey;
    }).toList();

    // Count tasks by type for the selected day
    final assignmentCount =
        dayTasks.where((task) => task.type == TaskType.assignment).length;
    final quizCount =
        dayTasks.where((task) => task.type == TaskType.quiz).length;
    final examCount =
        dayTasks.where((task) => task.type == TaskType.exam).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day Detail Summary',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isSmall ? 13 : 14,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmall ? 6 : 8),
        Text(
          'Currently you are displaying:',
          style: TextStyle(
            fontSize: isSmall ? 11 : 12,
            color: Colors.white70,
          ),
        ),
        SizedBox(height: isSmall ? 8 : 10),
        Row(
          children: [
            Expanded(
              child: _SnapshotCard(
                label: 'Assignments',
                count: assignmentCount,
                color: Colors.blueAccent,
                icon: Icons.assignment_turned_in_outlined,
                isSmall: isSmall,
              ),
            ),
            SizedBox(width: isSmall ? 6 : 8),
            Expanded(
              child: _SnapshotCard(
                label: 'Quizzes',
                count: quizCount,
                color: Colors.tealAccent.shade200,
                icon: Icons.quiz_outlined,
                isSmall: isSmall,
              ),
            ),
            SizedBox(width: isSmall ? 6 : 8),
            Expanded(
              child: _SnapshotCard(
                label: 'Exams',
                count: examCount,
                color: Colors.purpleAccent.shade200,
                icon: Icons.fact_check_outlined,
                isSmall: isSmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool isSmall;

  const _SnapshotCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 16), // Tăng từ 8-10 lên 12-16
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10), // Tăng từ 8 lên 10
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 20 : 24, color: color), // Tăng từ 16-18 lên 20-24
          SizedBox(height: isSmall ? 8 : 12), // Tăng từ 6-8 lên 8-12
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 12 : 14, // Tăng từ 10-11 lên 12-14
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isSmall ? 4 : 6), // Tăng từ 2-4 lên 4-6
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: isSmall ? 20 : 24, // Tăng từ 16-18 lên 20-24
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  final bool isSmall;
  const _TaskTile({required this.task, this.isSmall = false});

  Color get _primaryColor {
    switch (task.type) {
      case TaskType.assignment:
        return const Color(0xFF60A5FA);
      case TaskType.quiz:
        return const Color(0xFFFBBF24);
      case TaskType.exam:
        return const Color(0xFFF472B6);
      case TaskType.deadline:
        return const Color(0xFF34D399);
      case TaskType.other:
        return const Color(0xFF818CF8);
    }
  }

  IconData get _icon {
    switch (task.type) {
      case TaskType.assignment:
        return Icons.assignment_outlined;
      case TaskType.quiz:
        return Icons.quiz_outlined;
      case TaskType.exam:
        return Icons.fact_check_outlined;
      case TaskType.deadline:
        return Icons.event_note_outlined;
      case TaskType.other:
        return Icons.task_alt_outlined;
    }
  }

  String _getStatusLabel() {
    try {
      final now = DateTime.now();
      final dueDate = task.dateTime;
      final difference = dueDate.difference(now).inDays;

      if (task.isCompleted) {
        if (difference < 0) {
          return 'Submitted • Late';
        } else {
          return 'Submitted';
        }
      } else {
        if (difference < 0) {
          return 'Late';
        } else if (difference == 0) {
          return 'Due today • Pending';
        } else if (difference == 1) {
          return 'Due tomorrow • Pending';
        } else {
          return 'Due in $difference days • Pending';
        }
      }
    } catch (e) {
      return 'Pending';
    }
  }

  Color _getStatusColor() {
    try {
      final now = DateTime.now();
      final dueDate = task.dateTime;
      final difference = dueDate.difference(now).inDays;

      if (task.isCompleted) {
        if (difference < 0) {
          return const Color(0xFFFF6B6B); // Red for late submission
        } else {
          return const Color(0xFF34D399); // Green for on-time submission
        }
      } else {
        if (difference < 0) {
          return const Color(0xFFFF6B6B); // Red for late
        } else if (difference <= 1) {
          return const Color(0xFFFFB347); // Orange for urgent
        } else {
          return const Color(0xFF60A5FA); // Blue for pending
        }
      }
    } catch (e) {
      return const Color(0xFF60A5FA); // Default to blue
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('MMM d • h:mm a').format(task.dateTime);
    final courseLabel = task.courseName ?? 'General';
    final statusLabel = _getStatusLabel();
    final statusColor = _getStatusColor();

    return Container(
      padding: EdgeInsets.all(isSmall ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(isSmall ? 8 : 10),
        border: Border.all(
          color: task.isPriority 
              ? const Color(0xFFFF6B6B).withOpacity(0.8)
              : Colors.white.withOpacity(0.12),
          width: task.isPriority ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isSmall ? 32 : 36,
            height: isSmall ? 32 : 36,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _primaryColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Icon(_icon, color: _primaryColor, size: isSmall ? 18 : 20),
          ),
          SizedBox(width: isSmall ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmall ? 12 : 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmall ? 2 : 4),
                Text(
                  courseLabel,
                  style: TextStyle(color: Colors.white70, fontSize: isSmall ? 11 : 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmall ? 4 : 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      timeLabel,
                      style: TextStyle(color: _primaryColor, fontSize: isSmall ? 10 : 11),
                    ),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.white30, fontSize: isSmall ? 10 : 11),
                    ),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: isSmall ? 10 : 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (task.isPriority)
            Flexible(
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B), // Red background for high priority
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.priority_high,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Priority',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}



