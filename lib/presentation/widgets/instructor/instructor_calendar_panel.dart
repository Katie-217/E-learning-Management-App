import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elearning_management_app/application/controllers/instructor/task_provider.dart';
import 'package:elearning_management_app/application/controllers/instructor/instructor_kpi_provider.dart';
import 'package:elearning_management_app/domain/models/task_model.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/calendar_widget.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/semester_switcher.dart';

class InstructorCalendarPanel extends ConsumerStatefulWidget {
  final InstructorSemester? selectedSemester;
  
  const InstructorCalendarPanel({
    super.key,
    this.selectedSemester,
  });

  @override
  ConsumerState<InstructorCalendarPanel> createState() => _InstructorCalendarPanelState();
}

// Global key để đảm bảo chỉ có 1 calendar instance
final _calendarWidgetKey = const ValueKey('instructor_calendar_widget');

class _InstructorCalendarPanelState extends ConsumerState<InstructorCalendarPanel> {
  String? _selectedTaskType; // 'All', 'assignment', 'quiz', 'deadline'

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final monthKey = DateTime(selectedDate.year, selectedDate.month);
    final semesterName = widget.selectedSemester?.name ?? 'All';
    
    // Sử dụng providers từ instructor_kpi_provider (dữ liệu thật từ assignments)
    // Truyền semester vào để filter đúng với KPI stats
    final monthlyTasksAsync = ref.watch(instructorTasksForMonthProvider(
      InstructorTaskMonthKey(monthKey, semesterName)
    ));
    final dailyTasksAsync = ref.watch(instructorTasksForDateProvider(
      InstructorTaskKey(selectedDate, semesterName)
    ));

    // Sử dụng một calendar widget duy nhất, không tạo nhiều instance
    final calendarWidget = CalendarWidget(
      key: _calendarWidgetKey,
      selectedSemester: widget.selectedSemester,
      onDateSelected: (date) => _showDateTasksDialog(context, ref, date, semesterName),
    );

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
              calendarWidget,
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
                  final semesterName = widget.selectedSemester?.name ?? 'All';
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Items',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmall ? 13 : 14,
                      color: Colors.white,
                    ),
                  ),
                  _buildTaskTypeFilter(isSmall),
                ],
              ),
              SizedBox(height: isSmall ? 8 : 10),
              monthlyTasksAsync.when(
                data: (allTasks) {
                  // Lấy tất cả upcoming tasks từ tháng hiện tại và các tháng tiếp theo
                  final upcomingTasks = _filterTasks(allTasks);
                  return _buildUpcomingOverview(upcomingTasks, isSmall);
                },
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
              child: calendarWidget,
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
                      final semesterName = widget.selectedSemester?.name ?? 'All';
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upcoming Items',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      _buildTaskTypeFilter(false),
                    ],
                  ),
                  const SizedBox(height: 8),
                  monthlyTasksAsync.when(
                    data: (allTasks) {
                      // Lấy tất cả upcoming tasks từ tháng hiện tại và các tháng tiếp theo
                      final upcomingTasks = _filterTasks(allTasks);
                      return _buildUpcomingOverview(upcomingTasks, false);
                    },
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

  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = now.add(const Duration(days: 1));
    
    // Lọc tasks: chỉ lấy các tasks trong tương lai (upcoming = future only)
    final futureTasks = tasks.where((task) {
      final taskDate = DateTime(task.dateTime.year, task.dateTime.month, task.dateTime.day);
      return taskDate.isAfter(today) || taskDate.isAtSameMomentAs(today);
    }).toList();
    
    // Sau đó filter theo task type nếu có
    if (_selectedTaskType == null || _selectedTaskType == 'All') {
      return futureTasks;
    }
    
    return futureTasks.where((task) {
      switch (_selectedTaskType) {
        case 'assignment':
          return task.type == TaskType.assignment;
        case 'quiz':
          return task.type == TaskType.quiz;
        case 'deadline':
          // Deadline bao gồm:
          // 1. TaskType.deadline
          // 2. Assignments/quizzes sắp hết hạn trong 24 giờ
          if (task.type == TaskType.deadline) {
            return true;
          }
          // Kiểm tra nếu là assignment hoặc quiz sắp hết hạn trong 24h
          if (task.type == TaskType.assignment || task.type == TaskType.quiz) {
            final deadlineDate = task.dateTime;
            final isWithin24Hours = deadlineDate.isAfter(now.subtract(const Duration(seconds: 1))) &&
                                    deadlineDate.isBefore(tomorrow.add(const Duration(seconds: 1)));
            return isWithin24Hours;
          }
          return false;
        default:
          return true;
      }
    }).toList();
  }
  
  Widget _buildTaskTypeFilter(bool isSmall) {
    final fontSize = isSmall ? 10.0 : 11.0;
    final padding = isSmall ? 4.0 : 6.0;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[700]!.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTaskType ?? 'All',
          isDense: true,
          dropdownColor: const Color(0xFF1F2937),
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
          ),
          icon: Icon(Icons.filter_list, color: Colors.white70, size: isSmall ? 14 : 16),
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All')),
            DropdownMenuItem(value: 'assignment', child: Text('Assignments')),
            DropdownMenuItem(value: 'quiz', child: Text('Quizzes')),
            DropdownMenuItem(value: 'deadline', child: Text('Deadlines')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedTaskType = value;
            });
          },
        ),
      ),
    );
  }
  
  Widget _buildUpcomingOverview(List<TaskModel> tasks, bool isSmall) {
    if (tasks.isEmpty) {
      return Text(
        'No upcoming items for this semester.',
        style: TextStyle(color: Colors.white70, fontSize: isSmall ? 11 : 12),
      );
    }

    final sortedTasks = tasks.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Tính chiều cao cố định để hiển thị khoảng 2.5 items (như trong hình)
    // Mỗi item thực tế có chiều cao khoảng 130-140px (màn hình nhỏ) hoặc 150-160px (màn hình lớn)
    // Bao gồm: container padding + icon + text + pills + spacing
    final singleItemHeight = isSmall ? 130.0 : 150.0;
    final paddingBetween = isSmall ? 6.0 : 8.0;
    // Chiều cao cố định = 2.5 items + 2 khoảng cách giữa chúng (để item thứ 3 bị cắt một phần)
    final fixedHeight = (singleItemHeight * 2.5) + (paddingBetween * 2);

    return Container(
      height: fixedHeight,
      decoration: BoxDecoration(
        // Không cần decoration, chỉ để giới hạn chiều cao
      ),
      child: ClipRect(
        clipBehavior: Clip.hardEdge,
        child: SingleChildScrollView(
          clipBehavior: Clip.hardEdge,
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: sortedTasks
                .map(
                  (task) => Padding(
                    padding: EdgeInsets.only(bottom: isSmall ? 6 : 8),
                    child: _InstructorTaskTile(task: task, isSmall: isSmall),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
  
  void _showDateTasksDialog(BuildContext context, WidgetRef ref, DateTime date, String semesterName) {
    final dailyTasksAsync = ref.read(instructorTasksForDateProvider(
      InstructorTaskKey(date, semesterName)
    ));
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: dailyTasksAsync.when(
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No tasks for this date',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      );
                    }
                    
                    final sortedTasks = tasks.toList()
                      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: sortedTasks.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _InstructorTaskTile(task: sortedTasks[index], isSmall: false),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'Error loading tasks: $error',
                        style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    
    // Đếm deadlines sắp hết hạn trong 1 ngày (từ bây giờ đến 24 giờ tới)
    // Bao gồm cả TaskType.deadline, assignments VÀ quizzes sắp hết hạn
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final deadlines = tasks.where((task) {
      // Tính cả assignments, quizzes và deadlines
      if (task.type != TaskType.deadline && 
          task.type != TaskType.assignment && 
          task.type != TaskType.quiz) {
        return false;
      }
      
      // Deadline/Assignment/Quiz phải trong khoảng từ bây giờ đến 24 giờ tới
      final deadlineDate = task.dateTime;
      final isWithin24Hours = deadlineDate.isAfter(now.subtract(const Duration(seconds: 1))) &&
                              deadlineDate.isBefore(tomorrow.add(const Duration(seconds: 1)));
      
      return isWithin24Hours;
    }).length;

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
            description: 'Due within 24 hours',
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

