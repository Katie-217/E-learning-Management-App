import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elearning_management_app/application/controllers/instructor/task_provider.dart';
import 'package:elearning_management_app/domain/models/task_model.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/calendar_widget.dart';

class StudentCalendarPanel extends ConsumerWidget {
  const StudentCalendarPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final monthKey = DateTime(selectedDate.year, selectedDate.month);
    final monthlyTasksAsync = ref.watch(tasksForMonthProvider(monthKey));
    final dailyTasksAsync = ref.watch(tasksProvider(selectedDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CalendarWidget(),
        const SizedBox(height: 12),
        Text(
          'Ngày đã chọn: ${DateFormat('EEEE, MMM d').format(selectedDate)}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        monthlyTasksAsync.when(
          data: (tasks) => TaskSnapshotSummary(
            tasks: tasks,
            selectedDate: selectedDate,
          ),
          loading: () => const Center(
            child: SizedBox(
              height: 26,
              width: 26,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, _) => Text(
            'Không thể tải dữ liệu tháng: $error',
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Upcoming Deadlines',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        dailyTasksAsync.when(
          data: (tasks) => _buildDailyTasks(tasks),
          loading: () => const Center(
            child: SizedBox(
              height: 26,
              width: 26,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, _) => Text(
            'Không thể tải nhiệm vụ: $error',
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTasks(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return const Text(
        'Không có nhiệm vụ nào cho ngày đã chọn.',
        style: TextStyle(color: Colors.white70, fontSize: 12),
      );
    }

    final sortedTasks = tasks.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Column(
      children: sortedTasks
          .map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TaskTile(task: task),
              ))
          .toList(),
    );
  }
}

class TaskSnapshotSummary extends StatelessWidget {
  final List<TaskModel> tasks;
  final DateTime selectedDate;

  const TaskSnapshotSummary({
    super.key,
    required this.tasks,
    required this.selectedDate,
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
        const Text(
          'Day Detail Summary',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Currently you are displaying:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SnapshotCard(
                label: 'Assignments',
                count: assignmentCount,
                color: Colors.blueAccent,
                icon: Icons.assignment_turned_in_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SnapshotCard(
                label: 'Quizzes',
                count: quizCount,
                color: Colors.tealAccent.shade200,
                icon: Icons.quiz_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SnapshotCard(
                label: 'Exams',
                count: examCount,
                color: Colors.purpleAccent.shade200,
                icon: Icons.fact_check_outlined,
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

  const _SnapshotCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 20,
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
  const _TaskTile({required this.task});

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _primaryColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Icon(_icon, color: _primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  courseLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      timeLabel,
                      style: TextStyle(color: _primaryColor, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (task.isPriority)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                children: [
                  const Icon(
                    Icons.priority_high,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Priority',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}



