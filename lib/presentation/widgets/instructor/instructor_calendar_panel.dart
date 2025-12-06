import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elearning_management_app/application/controllers/instructor/task_provider.dart';
import 'package:elearning_management_app/application/controllers/instructor/instructor_kpi_provider.dart';
import 'package:elearning_management_app/domain/models/task_model.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/calendar_widget.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/instructor_compact_calendar_widget.dart';
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
    final semesterName = selectedSemester?.name ?? 'All';
    
    // Sử dụng providers từ instructor_kpi_provider (dữ liệu thật từ assignments)
    // Truyền semester vào để filter đúng với KPI stats
    final monthlyTasksAsync = ref.watch(instructorTasksForMonthProvider(
      InstructorTaskMonthKey(monthKey, semesterName)
    ));
    final dailyTasksAsync = ref.watch(instructorTasksForDateProvider(
      InstructorTaskKey(selectedDate, semesterName)
    ));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final isSmall = constraints.maxWidth < 400;

        if (!isWide) {
          // Layout dọc cho màn hình hẹp
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const CalendarWidget(),
              SizedBox(height: isSmall ? 8 : 10),
              Text(
                'Selected date: ${DateFormat('EEEE, MMM d').format(selectedDate)}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isSmall ? 11 : 12,
                ),
              ),
              SizedBox(height: isSmall ? 8 : 10),
              monthlyTasksAsync.when(
                data: (tasks) {
                  // Lấy KPI stats để hiển thị tổng số assignments/quizzes trong semester
                  final semesterName = selectedSemester?.name ?? 'All';
                  final kpiStatsAsync = ref.watch(instructorKPIStatsProvider(semesterName));
                  return kpiStatsAsync.when(
                    data: (stats) => InstructorTaskSummary(
                      tasks: tasks,
                      totalAssignments: stats.assignmentsCount,
                      totalQuizzes: stats.quizzesCount,
                    ),
                    loading: () => Center(
                      child: SizedBox(
                        height: isSmall ? 20 : 26,
                        width: isSmall ? 20 : 26,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => InstructorTaskSummary(
                      tasks: tasks,
                      totalAssignments: 0,
                      totalQuizzes: 0,
                    ),
                  );
                },
                loading: () => Center(
                  child: SizedBox(
                    height: isSmall ? 20 : 26,
                    width: isSmall ? 20 : 26,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (error, _) => Text(
                  'Unable to load semester data: $error',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: isSmall ? 11 : 12,
                  ),
                ),
              ),
              SizedBox(height: isSmall ? 12 : 14),
              Text(
                'Upcoming Items',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmall ? 13 : 14,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isSmall ? 8 : 10),
              dailyTasksAsync.when(
                data: (tasks) => _buildUpcomingOverview(tasks, isSmall),
                loading: () => Center(
                  child: SizedBox(
                    height: isSmall ? 20 : 26,
                    width: isSmall ? 20 : 26,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (error, _) => Text(
                  'Unable to load upcoming items: $error',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: isSmall ? 11 : 12,
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
            Flexible(
              flex: 1,
              child: const CalendarWidget(),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selected date: ${DateFormat('EEEE, MMM d').format(selectedDate)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  monthlyTasksAsync.when(
                    data: (tasks) {
                      // Lấy KPI stats để hiển thị tổng số assignments/quizzes trong semester
                      final semesterName = selectedSemester?.name ?? 'All';
                      final kpiStatsAsync = ref.watch(instructorKPIStatsProvider(semesterName));
                      return kpiStatsAsync.when(
                        data: (stats) => InstructorTaskSummary(
                          tasks: tasks,
                          totalAssignments: stats.assignmentsCount,
                          totalQuizzes: stats.quizzesCount,
                        ),
                        loading: () => const Center(
                          child: SizedBox(
                            height: 26,
                            width: 26,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (_, __) => InstructorTaskSummary(
                          tasks: tasks,
                          totalAssignments: 0,
                          totalQuizzes: 0,
                        ),
                      );
                    },
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
                  const SizedBox(height: 12),
                  const Text(
                    'Upcoming Items',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  dailyTasksAsync.when(
                    data: (tasks) => _buildUpcomingOverview(tasks, false),
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

  Widget _buildUpcomingOverview(List<TaskModel> tasks, bool isSmall) {
    if (tasks.isEmpty) {
      return Text(
        'No instructor actions for this date.',
        style: TextStyle(color: Colors.white70, fontSize: isSmall ? 11 : 12),
      );
    }

    final sortedTasks = tasks.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Column(
      children: sortedTasks
          .map(
            (task) => Padding(
              padding: EdgeInsets.only(bottom: isSmall ? 6 : 8),
              child: _InstructorTaskTile(task: task, isSmall: isSmall),
            ),
          )
          .toList(),
    );
  }
}

// Task Summary Widget - Hiển thị tasks từ calendar
class InstructorTaskSummary extends StatelessWidget {
  final List<TaskModel> tasks;
  final int totalAssignments; // Tổng số assignments trong semester
  final int totalQuizzes; // Tổng số quizzes trong semester
  
  const InstructorTaskSummary({
    super.key, 
    required this.tasks,
    required this.totalAssignments,
    required this.totalQuizzes,
  });

  @override
  Widget build(BuildContext context) {
    // Sử dụng tổng số từ KPI stats thay vì đếm từ tasks trong tháng
    final assignments = totalAssignments;
    final quizzes = totalQuizzes;
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11, // Giảm từ 12 xuống 11
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4), // Giảm từ 6 xuống 4
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18, // Giảm từ 22 xuống 18
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2), // Giảm từ 4 xuống 2
            Text(
              description,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10, // Giảm từ 11 xuống 10
              ),
              maxLines: 2, // Cho phép 2 dòng nếu cần
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructorTaskTile extends StatelessWidget {
  final TaskModel task;
  final bool isSmall;

  const _InstructorTaskTile({required this.task, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d • h:mm a').format(task.dateTime);
    final submissionSummary =
        '${task.submittedCount}/${task.totalCount} submissions';
    final pendingCount =
        task.totalCount > 0 ? task.totalCount - task.submittedCount : 0;

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
              color: Colors.blueGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _iconForTask(task.type),
              color: Colors.white,
              size: isSmall ? 18 : 20,
            ),
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
                  task.courseName ?? 'General',
                  style: TextStyle(color: Colors.white70, fontSize: isSmall ? 11 : 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmall ? 4 : 6),
                Text(
                  dateLabel,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: isSmall ? 11 : 12,
                  ),
                ),
                SizedBox(height: isSmall ? 6 : 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
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

