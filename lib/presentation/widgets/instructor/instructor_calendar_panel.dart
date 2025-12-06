import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elearning_management_app/application/controllers/instructor/task_provider.dart';
import 'package:elearning_management_app/domain/models/task_model.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/calendar_widget.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/semester_switcher.dart';

class InstructorCalendarPanel extends ConsumerWidget {
  final InstructorSemester? selectedSemester;
  
  const InstructorCalendarPanel({
    super.key,
    this.selectedSemester,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final monthKey = DateTime(selectedDate.year, selectedDate.month);
    final monthlyTasksAsync = ref.watch(tasksForMonthProvider(monthKey));
    final dailyTasksAsync = ref.watch(tasksProvider(selectedDate));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        if (!isWide) {
          // Giữ layout dọc cho màn hình hẹp
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CalendarWidget(),
              const SizedBox(height: 12),
              Text(
                'Selected date: ${DateFormat('EEEE, MMM d').format(selectedDate)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              monthlyTasksAsync.when(
                data: (tasks) => InstructorTaskSummary(tasks: tasks),
                loading: () => const Center(
                  child: SizedBox(
                    height: 26,
                    width: 26,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (error, _) => Text(
                  'Unable to load semester data: $error',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upcoming Items',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              dailyTasksAsync.when(
                data: (tasks) => _buildUpcomingOverview(tasks),
                loading: () => const Center(
                  child: SizedBox(
                    height: 26,
                    width: 26,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (error, _) => Text(
                  'Unable to load upcoming items: $error',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        }

        // Layout ngang cho màn hình rộng: Calendar bên trái, Summary + Upcoming bên phải
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: const CalendarWidget(),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected date: ${DateFormat('EEEE, MMM d').format(selectedDate)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  monthlyTasksAsync.when(
                    data: (tasks) => InstructorTaskSummary(tasks: tasks),
                    loading: () => const Center(
                      child: SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (error, _) => Text(
                      'Unable to load semester data: $error',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Upcoming Items',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  dailyTasksAsync.when(
                    data: (tasks) => _buildUpcomingOverview(tasks),
                    loading: () => const Center(
                      child: SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (error, _) => Text(
                      'Unable to load upcoming items: $error',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingOverview(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return const Text(
        'No instructor actions for this date.',
        style: TextStyle(color: Colors.white70, fontSize: 12),
      );
    }

    final sortedTasks = tasks.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Column(
      children: sortedTasks
          .map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InstructorTaskTile(task: task),
            ),
          )
          .toList(),
    );
  }
}

// Task Summary Widget - Hiển thị tasks từ calendar
class InstructorTaskSummary extends StatelessWidget {
  final List<TaskModel> tasks;
  const InstructorTaskSummary({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final assignments =
        tasks.where((task) => task.type == TaskType.assignment).length;
    final quizzes =
        tasks.where((task) => task.type == TaskType.quiz).length;
    final deadlines =
        tasks.where((task) => task.type == TaskType.deadline).length;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryCard(
            label: 'Assignments',
            value: assignments.toString(),
            description: 'Total tasks created this semester',
            color: const Color(0xFF60A5FA),
          ),
          const SizedBox(width: 8),
          _SummaryCard(
            label: 'Quizzes',
            value: quizzes.toString(),
            description: 'Quizzes to monitor',
            color: const Color(0xFF34D399),
          ),
          const SizedBox(width: 8),
          _SummaryCard(
            label: 'Deadlines',
            value: deadlines.toString(),
            description: 'Other academic events',
            color: const Color(0xFFFBBF24),
          ),
        ],
      ),
    );
  }
}

// Summary Card Widget - Cho task summary
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String description;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructorTaskTile extends StatelessWidget {
  final TaskModel task;

  const _InstructorTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d • h:mm a').format(task.dateTime);
    final submissionSummary =
        '${task.submittedCount}/${task.totalCount} submissions';
    final pendingCount =
        task.totalCount > 0 ? task.totalCount - task.submittedCount : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isPriority
              ? const Color(0xFFFF6B6B).withOpacity(0.8)
              : Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconForTask(task.type),
              color: Colors.white,
            ),
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
                  task.courseName ?? 'General',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _InfoPill(
                      icon: Icons.groups_outlined,
                      label: task.groupsApplied.isEmpty
                          ? 'All groups'
                          : task.groupsApplied.join(', '),
                    ),
                    _InfoPill(
                      icon: Icons.fact_check_outlined,
                      label: submissionSummary,
                    ),
                    if (task.lateCount > 0)
                      _InfoPill(
                        icon: Icons.timer_off_outlined,
                        label: '${task.lateCount} late',
                        color: const Color(0xFFFFA8A8),
                      ),
                    if (pendingCount > 0)
                      _InfoPill(
                        icon: Icons.pending_actions_outlined,
                        label: '$pendingCount pending',
                        color: const Color(0xFFFFD68A),
                      ),
                    if (task.notSubmittedCount > 0)
                      _InfoPill(
                        icon: Icons.report_problem_outlined,
                        label: '${task.notSubmittedCount} not submitted',
                        color: const Color(0xFFFF8A8A),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForTask(TaskType type) {
    switch (type) {
      case TaskType.assignment:
        return Icons.assignment;
      case TaskType.quiz:
        return Icons.quiz_outlined;
      case TaskType.exam:
        return Icons.fact_check_outlined;
      case TaskType.deadline:
        return Icons.event_note_outlined;
      default:
        return Icons.task_alt_outlined;
    }
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoPill({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.white24).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? Colors.white12).withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.white60),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color ?? Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

