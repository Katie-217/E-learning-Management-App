import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/application/controllers/instructor/task_provider.dart';
import 'package:elearning_management_app/application/controllers/instructor/instructor_kpi_provider.dart';
import 'package:elearning_management_app/domain/models/task_model.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/semester_switcher.dart';

class CalendarWidget extends ConsumerStatefulWidget {
  final InstructorSemester? selectedSemester;
  final Function(DateTime)? onDateSelected;
  final List<TaskModel>? tasksForMonth; // Optional: truyền tasks từ bên ngoài (cho student)
  final bool isStudent; // Flag để biết là student hay instructor
  
  const CalendarWidget({
    super.key,
    this.selectedSemester,
    this.onDateSelected,
    this.tasksForMonth,
    this.isStudent = false,
  });

  @override
  ConsumerState<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends ConsumerState<CalendarWidget> {
  DateTime _currentDate = DateTime.now();
  InstructorSemester? _previousSemester;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    
    // Initialize with current month or semester start date
    if (widget.selectedSemester != null) {
      final semester = widget.selectedSemester!;
      final semesterStartDate = semester.startDate;
      final semesterEndDate = semester.endDate;
      
      // Kiểm tra xem today có nằm trong semester range không
      final todayInRange = (semesterEndDate == null || now.isBefore(semesterEndDate.add(const Duration(days: 1)))) &&
                           now.isAfter(semesterStartDate.subtract(const Duration(days: 1)));
      
      if (todayInRange) {
        // Nếu today nằm trong semester, hiển thị tháng hiện tại và chọn today
        _currentDate = DateTime(now.year, now.month, 1);
        // Delay provider update để tránh modify trong initState
        Future.microtask(() {
          if (mounted) {
            ref.read(selectedDateProvider.notifier).state = now;
          }
        });
      } else {
        // Nếu today ngoài semester, hiển thị tháng bắt đầu của semester
        _currentDate = DateTime(
          semesterStartDate.year,
          semesterStartDate.month,
          1,
        );
        // Chọn semester start date nếu today trước semester, hoặc end date nếu today sau semester
        final selectedDate = now.isBefore(semesterStartDate) 
            ? semesterStartDate 
            : (semesterEndDate ?? semesterStartDate);
        // Delay provider update để tránh modify trong initState
        Future.microtask(() {
          if (mounted) {
            ref.read(selectedDateProvider.notifier).state = selectedDate;
          }
        });
      }
    } else {
      // Không có semester, hiển thị tháng hiện tại và chọn today
      _currentDate = DateTime(now.year, now.month, 1);
      // Delay provider update để tránh modify trong initState
      Future.microtask(() {
        if (mounted) {
          ref.read(selectedDateProvider.notifier).state = now;
        }
      });
    }
    _previousSemester = widget.selectedSemester;
  }

  @override
  void didUpdateWidget(CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When semester changes, auto jump to first month of semester
    // Chỉ update khi semester thực sự thay đổi (so sánh ID)
    final oldSemesterId = oldWidget.selectedSemester?.id;
    final newSemesterId = widget.selectedSemester?.id;
    
    if (oldSemesterId != newSemesterId) {
      if (widget.selectedSemester != null) {
        final semester = widget.selectedSemester!;
        final semesterStartDate = semester.startDate;
        final semesterEndDate = semester.endDate;
        final now = DateTime.now();
        final currentSelectedDate = ref.read(selectedDateProvider);
        
        // Kiểm tra xem today có nằm trong semester range không
        final todayInRange = (semesterEndDate == null || now.isBefore(semesterEndDate.add(const Duration(days: 1)))) &&
                             now.isAfter(semesterStartDate.subtract(const Duration(days: 1)));
        
        DateTime newCurrentDate;
        DateTime newSelectedDate;
        
        if (todayInRange) {
          // Nếu today nằm trong semester, hiển thị tháng hiện tại (tháng của today)
          newCurrentDate = DateTime(now.year, now.month, 1);
          newSelectedDate = now;
        } else {
          // Nếu today ngoài semester, hiển thị tháng bắt đầu/kết thúc của semester
          newCurrentDate = DateTime(
            semesterStartDate.year,
            semesterStartDate.month,
            1,
          );
          // Chọn semester start date nếu today trước semester, hoặc end date nếu today sau semester
          newSelectedDate = now.isBefore(semesterStartDate) 
              ? semesterStartDate 
              : (semesterEndDate ?? semesterStartDate);
        }
        
        if (mounted) {
          // Chỉ setState nếu tháng thực sự thay đổi
          if (_currentDate.year != newCurrentDate.year || 
              _currentDate.month != newCurrentDate.month) {
            setState(() {
              _currentDate = newCurrentDate;
            });
          }
          
          // Update selected date - delay để tránh modify trong didUpdateWidget
          Future.microtask(() {
            if (mounted) {
              ref.read(selectedDateProvider.notifier).state = newSelectedDate;
            }
          });
        }
      } else {
        // If no semester selected, go back to current month
        final now = DateTime.now();
        final newCurrentDate = DateTime(now.year, now.month, 1);
        
        if (mounted) {
          // Chỉ setState nếu tháng thực sự thay đổi
          if (_currentDate.year != newCurrentDate.year || 
              _currentDate.month != newCurrentDate.month) {
            setState(() {
              _currentDate = newCurrentDate;
            });
          }
          // Delay provider update để tránh modify trong didUpdateWidget
          Future.microtask(() {
            if (mounted) {
              ref.read(selectedDateProvider.notifier).state = now;
            }
          });
        }
      }
      _previousSemester = widget.selectedSemester;
    }
  }

  void _previousMonth() {
    final newMonth = DateTime(_currentDate.year, _currentDate.month - 1, 1);
    setState(() {
      _currentDate = newMonth;
    });
    _syncSelectedDateWithMonth(newMonth);
  }

  void _nextMonth() {
    final newMonth = DateTime(_currentDate.year, _currentDate.month + 1, 1);
    setState(() {
      _currentDate = newMonth;
    });
    _syncSelectedDateWithMonth(newMonth);
  }

  void _syncSelectedDateWithMonth(DateTime monthDate) {
    final selectedDate = ref.read(selectedDateProvider);
    final desiredDay = selectedDate.day;
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final newSelectedDate = DateTime(
      monthDate.year,
      monthDate.month,
      desiredDay > lastDayOfMonth ? lastDayOfMonth : desiredDay,
    );
    ref.read(selectedDateProvider.notifier).state = newSelectedDate;
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentDate = DateTime(now.year, now.month, 1);
    });
    ref.read(selectedDateProvider.notifier).state = now;
  }

  void _onDateSelected(DateTime date) {
    // Check if date is in semester range (chỉ cho instructor)
    if (!widget.isStudent && widget.selectedSemester != null) {
      final startDate = widget.selectedSemester!.startDate;
      final endDate = widget.selectedSemester!.endDate;
      
      if (endDate != null) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
        final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
        
        if (dateOnly.isBefore(startOnly) || dateOnly.isAfter(endOnly)) {
          // Date is outside semester range, don't allow selection
          return;
        }
      } else if (date.isBefore(startDate)) {
        return;
      }
    }
    
    ref.read(selectedDateProvider.notifier).state = date;
    // Update currentDate if selected date is in a different month
    if (date.year != _currentDate.year || date.month != _currentDate.month) {
      setState(() {
        _currentDate = DateTime(date.year, date.month, 1);
      });
    }
    
    // Không gọi callback để không hiển thị dialog
    // widget.onDateSelected?.call(date);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final semesterName = widget.selectedSemester?.name ?? 'All';
    final monthKey = DateTime(_currentDate.year, _currentDate.month);
    
    // Nếu có tasksForMonth được truyền từ bên ngoài (cho student), dùng nó
    // Nếu không, fetch từ provider (cho instructor)
    List<TaskModel> tasks;
    if (widget.tasksForMonth != null) {
      // Filter tasks theo tháng hiện tại nếu là student
      final monthStart = DateTime(_currentDate.year, _currentDate.month, 1);
      final monthEnd = DateTime(_currentDate.year, _currentDate.month + 1, 0, 23, 59, 59);
      tasks = widget.tasksForMonth!.where((task) {
        final taskDate = task.dateTime;
        return taskDate.isAfter(monthStart.subtract(const Duration(days: 1))) &&
               taskDate.isBefore(monthEnd.add(const Duration(days: 1)));
      }).toList();
    } else {
      // Instructor: fetch từ provider
      final tasksForMonthAsync = ref.watch(instructorTasksForMonthProvider(
        InstructorTaskMonthKey(monthKey, semesterName)
      ));
      tasks = tasksForMonthAsync.value ?? [];
    }
    
    // Debug: Log tasks count - log chi tiết để debug
    print('DEBUG: 📅 Calendar - Month: ${_currentDate.year}-${_currentDate.month}, Semester: $semesterName, Tasks: ${tasks.length}');
    if (tasks.isNotEmpty) {
      // Group tasks by date for better logging
      final tasksByDate = <int, List<String>>{};
      for (final task in tasks) {
        final day = task.dateTime.day;
        if (!tasksByDate.containsKey(day)) {
          tasksByDate[day] = [];
        }
        tasksByDate[day]!.add('${task.type.name}: ${task.title}');
      }
      print('DEBUG: 📅 Tasks by date:');
      tasksByDate.forEach((day, taskList) {
        print('DEBUG: 📅   Day $day: ${taskList.length} tasks - ${taskList.join(", ")}');
      });
    } else {
      print('DEBUG: 📅 No tasks found for this month/semester');
    }

    return SimpleCalendar(
      key: const ValueKey('simple_calendar_widget'),
      currentDate: _currentDate,
      selectedDate: selectedDate,
      tasksForMonth: tasks,
      selectedSemester: widget.selectedSemester,
      onPreviousMonth: _previousMonth,
      onNextMonth: _nextMonth,
      onGoToToday: _goToToday,
      onDateSelected: _onDateSelected,
    );
  }
}

class SimpleCalendar extends StatelessWidget {
  final DateTime currentDate;
  final DateTime selectedDate;
  final List<TaskModel> tasksForMonth;
  final InstructorSemester? selectedSemester;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;
  final VoidCallback? onGoToToday;
  final Function(DateTime)? onDateSelected;

  const SimpleCalendar({
    super.key,
    required this.currentDate,
    required this.selectedDate,
    this.tasksForMonth = const [],
    this.selectedSemester,
    this.onPreviousMonth,
    this.onNextMonth,
    this.onGoToToday,
    this.onDateSelected,
  });
  
  bool _isDateInSemesterRange(DateTime date) {
    if (selectedSemester == null) return true;
    final startDate = selectedSemester!.startDate;
    final endDate = selectedSemester!.endDate;
    
    if (endDate == null) {
      return date.isAfter(startDate.subtract(const Duration(days: 1)));
    }
    
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    
    return dateOnly.isAfter(startOnly.subtract(const Duration(days: 1))) &&
           dateOnly.isBefore(endOnly.add(const Duration(days: 1)));
  }
  
  Color? _getTaskColor(TaskModel task) {
    switch (task.type) {
      case TaskType.quiz:
        return Colors.blue; // Quiz - Blue
      case TaskType.assignment:
        return Colors.green; // Assignment - Green
      case TaskType.deadline:
        return Colors.orange; // Deadline - Orange
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(currentDate.year, currentDate.month, 1);
    final lastDay = DateTime(currentDate.year, currentDate.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7; // Convert to 0-6 (Sunday = 0)
    // Check if currentDate is the current month (year and month match)
    final isCurrentMonth = currentDate.year == now.year && currentDate.month == now.month;
    
    // Kiểm tra xem semester hiện tại có chứa today không
    // Nếu không chứa today → không đánh dấu selected date
    final isCurrentSemester = selectedSemester == null || 
        (selectedSemester!.endDate == null || now.isBefore(selectedSemester!.endDate!.add(const Duration(days: 1)))) &&
        now.isAfter(selectedSemester!.startDate.subtract(const Duration(days: 1)));

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 300.0;
        return SizedBox(
          width: width,
          child: AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        padding: const EdgeInsets.only(top: 14, left: 8, right: 8, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Month and Year Header with Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 16),
                  onPressed: onPreviousMonth,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.grey[700],
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_getMonthName(currentDate.month)} ${currentDate.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 16),
                  onPressed: onNextMonth,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.grey[700],
                ),
              ],
            ),
            // Show "Today" button only when IN the current month
            // (when viewing the month that contains today's date)
            if (isCurrentMonth && onGoToToday != null)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: TextButton(
                  onPressed: onGoToToday,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(fontSize: 9, color: Colors.blue),
                  ),
                ),
              ),
            if (!isCurrentMonth || onGoToToday == null)
              const SizedBox(height: 4),
            // Days of week header
            Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),
            // Calendar grid
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(6, (week) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0.5),
                      child: Row(
                        children: List.generate(7, (dayIndex) {
                          final dayNumber = week * 7 + dayIndex - firstWeekday + 1;
                          final isCurrentMonthDay = dayNumber > 0 && dayNumber <= daysInMonth;
                          
                          if (!isCurrentMonthDay) {
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                              ),
                            );
                          }

                          final date = DateTime(currentDate.year, currentDate.month, dayNumber);
                          
                          // Khai báo now trước khi sử dụng
                          final now = DateTime.now();
                          
                          // Check if date is in semester range (chỉ cho instructor)
                          final isInSemesterRange = selectedSemester == null || _isDateInSemesterRange(date);
                          
                          // Check if this date is today - CHỈ đánh dấu "Today" khi đang xem tháng hiện tại
                          final isViewingCurrentMonth = currentDate.year == now.year && 
                                                         currentDate.month == now.month;
                          final isToday = isViewingCurrentMonth &&
                                          date.year == now.year && 
                                          date.month == now.month && 
                                          date.day == now.day;
                          
                          // Đánh dấu selected date
                          // Instructor: CHỈ đánh dấu khi đang xem học kì hiện tại (chứa today)
                          // Student: luôn đánh dấu khi selected
                          final isSelected = (selectedSemester == null || isCurrentSemester) &&
                                            currentDate.year == selectedDate.year &&
                                            currentDate.month == selectedDate.month &&
                                            date.year == selectedDate.year && 
                                            date.month == selectedDate.month && 
                                            date.day == selectedDate.day;
                          
                          // Get tasks for this date and group by type
                          final tasksForDate = tasksForMonth.where((task) {
                            final taskDate = DateTime(
                              task.dateTime.year,
                              task.dateTime.month,
                              task.dateTime.day,
                            );
                            final dateOnly = DateTime(date.year, date.month, date.day);
                            final taskDateOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);
                            final isMatch = taskDateOnly.isAtSameMomentAs(dateOnly);
                            
                            // Debug: Log để kiểm tra matching
                            if (isMatch && dayNumber <= 5) {
                              print('DEBUG: 📅 Task matched for day $dayNumber: ${task.title} (${task.type.name}) on ${taskDateOnly.toString()}');
                            }
                            
                            return isMatch;
                          }).toList();
                          
                          final hasTasks = tasksForDate.isNotEmpty;
                          
                          // Phân loại tasks: deadline sắp hết hạn và tasks thường
                          final tomorrow = now.add(const Duration(days: 1));
                          
                          // Phân loại tasks: deadline sắp hết hạn và tasks thường
                          // 1. Deadline: assignments/quizzes sắp hết hạn trong 24h
                          final urgentDeadlineTasks = tasksForDate.where((t) {
                            final deadlineDate = t.dateTime;
                            final isWithin24Hours = deadlineDate.isAfter(now.subtract(const Duration(seconds: 1))) &&
                                                    deadlineDate.isBefore(tomorrow.add(const Duration(seconds: 1)));
                            // Assignment hoặc Quiz sắp hết hạn trong 24h được coi là deadline
                            return isWithin24Hours && (t.type == TaskType.assignment || t.type == TaskType.quiz);
                          }).toList();
                          
                          final hasUrgentDeadline = urgentDeadlineTasks.isNotEmpty;
                          
                          // 2. Regular tasks: assignments/quizzes/deadlines KHÔNG sắp hết hạn trong 24h
                          // QUAN TRỌNG: Nếu cùng 1 ngày có cả task sắp hết hạn và task không sắp hết hạn, 
                          // thì cần hiển thị cả 2 dots
                          final regularTasks = tasksForDate.where((t) {
                            final deadlineDate = t.dateTime;
                            final isWithin24Hours = deadlineDate.isAfter(now.subtract(const Duration(seconds: 1))) &&
                                                    deadlineDate.isBefore(tomorrow.add(const Duration(seconds: 1)));
                            
                            // Deadline type → luôn là regular task (không tính là urgent deadline)
                            if (t.type == TaskType.deadline) return true;
                            
                            // Assignment/quiz KHÔNG sắp hết hạn trong 24h → là regular task
                            // QUAN TRỌNG: Nếu có nhiều assignments/quizzes trong cùng 1 ngày,
                            // một số sắp hết hạn (deadline) và một số không sắp hết hạn (regular),
                            // thì cần hiển thị cả 2 dots
                            if ((t.type == TaskType.assignment || t.type == TaskType.quiz) && !isWithin24Hours) {
                              return true;
                            }
                            
                            return false;
                          }).toList();
                          
                          final hasRegularTasks = regularTasks.isNotEmpty;
                          
                          // Xác định màu cho task thường (nếu có)
                          Color? regularTaskColor;
                          if (hasRegularTasks && regularTasks.isNotEmpty) {
                            // Tìm task thường đầu tiên để xác định màu (ưu tiên quiz > assignment > deadline)
                            TaskModel? regularTask;
                            if (regularTasks.any((t) => t.type == TaskType.quiz)) {
                              regularTask = regularTasks.firstWhere((t) => t.type == TaskType.quiz);
                            } else if (regularTasks.any((t) => t.type == TaskType.assignment)) {
                              regularTask = regularTasks.firstWhere((t) => t.type == TaskType.assignment);
                            } else if (regularTasks.any((t) => t.type == TaskType.deadline)) {
                              regularTask = regularTasks.firstWhere((t) => t.type == TaskType.deadline);
                            } else {
                              regularTask = regularTasks.first;
                            }
                            
                            // Xác định màu dựa trên type của task thường
                            if (regularTask != null) {
                              if (regularTask.type == TaskType.quiz) {
                                regularTaskColor = Colors.blue;
                              } else if (regularTask.type == TaskType.assignment) {
                                regularTaskColor = Colors.green;
                              } else if (regularTask.type == TaskType.deadline) {
                                regularTaskColor = Colors.orange;
                              }
                            }
                          }
                          
                          // Debug: Log tasks for debugging - log tất cả ngày có tasks
                          if (hasTasks) {
                            final deadlineInfo = hasUrgentDeadline ? ' (DEADLINE - sẽ hiển thị dot CAM)' : '';
                            final regularInfo = hasRegularTasks && regularTaskColor != null 
                                ? ' (Regular: ${regularTaskColor == Colors.blue ? "blue" : regularTaskColor == Colors.green ? "green" : "orange"} - sẽ hiển thị dot ${regularTaskColor == Colors.blue ? "XANH DƯƠNG" : regularTaskColor == Colors.green ? "XANH LÁ" : "CAM"})' 
                                : '';
                            print('DEBUG: 📅 ✅ Day $dayNumber (${date.year}-${date.month}-${date.day}) has ${tasksForDate.length} tasks: ${tasksForDate.map((t) => '${t.type.name}').join(", ")}$deadlineInfo$regularInfo');
                            print('DEBUG: 📅 🎯 Dots sẽ hiển thị: hasUrgentDeadline=$hasUrgentDeadline, hasRegularTasks=$hasRegularTasks, regularTaskColor=$regularTaskColor');
                            print('DEBUG: 📅 📊 urgentDeadlineTasks count: ${urgentDeadlineTasks.length}, regularTasks count: ${regularTasks.length}');
                            print('DEBUG: 📅 🎨 Will render dots: ${hasUrgentDeadline || (hasRegularTasks && regularTaskColor != null)}');
                          }

                          return Expanded(
                            child: Tooltip(
                              message: hasTasks ? _buildTooltipMessage(tasksForDate) : '',
                              preferBelow: false,
                              waitDuration: const Duration(milliseconds: 300),
                              showDuration: const Duration(seconds: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F2937),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[700]!, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: isInSemesterRange ? () => onDateSelected?.call(date) : null,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                  // Thêm padding top để có không gian cho dots ở trên
                                  padding: const EdgeInsets.only(top: 4),
                                  decoration: const BoxDecoration(
                                    // Không có background cho container bên ngoài
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.all(Radius.circular(4)),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Today indicator - ô vuông nhỏ giống selected nhưng màu khác
                                      if (isToday && isViewingCurrentMonth && !isSelected)
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100, // Màu xanh nhạt cho today
                                            borderRadius: BorderRadius.circular(3),
                                            border: Border.all(
                                              color: Colors.blue.shade400,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      // Selected indicator - chỉ hiển thị ô nhỏ bên trong, không có shadow
                                      if (isSelected)
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: (isToday && isViewingCurrentMonth)
                                                ? Colors.blue.shade600 // Darker blue if also today
                                                : const Color(0xFF3B82F6), // Blue-500
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                      Center(
                                        child: Text(
                                          dayNumber.toString(),
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : (isToday && isViewingCurrentMonth)
                                                    ? Colors.blue.shade800 // Darker blue for better visibility - chỉ khi xem tháng hiện tại
                                                    : Colors.black87, // Tất cả các ngày đều hiển thị rõ ràng
                                            fontSize: 10,
                                            fontWeight: (isSelected || (isToday && isViewingCurrentMonth)) 
                                                ? FontWeight.w700 
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      // Task dots - HIỂN THỊ 2 DOTS: deadline (cam) và tasks thường (xanh)
                                      // Dots nằm ở TRÊN ngày, chỉ là hình tròn màu đậm
                                      if (hasUrgentDeadline || (hasRegularTasks && regularTaskColor != null))
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          right: 0,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // Dot deadline (cam) - sắp hết hạn trong 24h
                                              if (hasUrgentDeadline)
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  margin: const EdgeInsets.only(right: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.shade700,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.orange.withOpacity(0.5),
                                                        blurRadius: 2,
                                                        spreadRadius: 0.5,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              // Dot tasks thường (xanh lá/xanh dương) - không sắp hết hạn
                                              if (hasRegularTasks && regularTaskColor != null)
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: regularTaskColor == Colors.blue
                                                        ? Colors.blue.shade700
                                                        : regularTaskColor == Colors.green
                                                            ? Colors.green.shade700
                                                            : Colors.orange.shade700,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: (regularTaskColor == Colors.blue
                                                                ? Colors.blue
                                                                : regularTaskColor == Colors.green
                                                                    ? Colors.green
                                                                    : Colors.orange)
                                                            .withOpacity(0.5),
                                                        blurRadius: 2,
                                                        spreadRadius: 0.5,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          
                        );
                      }),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
  
  String _buildTooltipMessage(List<TaskModel> tasks) {
    if (tasks.isEmpty) return '';
    
    // Sắp xếp tasks theo thứ tự: Quiz > Assignment > Deadline
    final sortedTasks = tasks.toList()
      ..sort((a, b) {
        if (a.type == TaskType.quiz && b.type != TaskType.quiz) return -1;
        if (a.type != TaskType.quiz && b.type == TaskType.quiz) return 1;
        if (a.type == TaskType.assignment && b.type == TaskType.deadline) return -1;
        if (a.type == TaskType.deadline && b.type == TaskType.assignment) return 1;
        return 0;
      });
    
    final parts = <String>[];
    
    // Hiển thị tên bài tập cụ thể (tối đa 3 bài đầu tiên)
    final displayTasks = sortedTasks.take(3).toList();
    
    for (final task in displayTasks) {
      String typeIcon = '';
      String typeLabel = '';
      switch (task.type) {
        case TaskType.quiz:
          typeIcon = '📝';
          typeLabel = 'Quiz';
          break;
        case TaskType.assignment:
          typeIcon = '📄';
          typeLabel = 'Assignment';
          break;
        case TaskType.deadline:
          typeIcon = '⏰';
          typeLabel = 'Deadline';
          break;
        default:
          typeIcon = '📋';
          typeLabel = 'Task';
      }
      
      // Rút ngắn tên nếu quá dài
      String taskTitle = task.title;
      if (taskTitle.length > 30) {
        taskTitle = '${taskTitle.substring(0, 27)}...';
      }
      
      parts.add('$typeIcon $typeLabel: $taskTitle');
      
      // Thêm thông tin submission nếu là assignment hoặc quiz
      if (task.type == TaskType.assignment || task.type == TaskType.quiz) {
        final pending = task.totalCount - task.submittedCount;
        parts.add('   ${task.submittedCount}/${task.totalCount} submitted');
        if (pending > 0) {
          parts.add('   $pending pending');
        }
      }
    }
    
    // Nếu có nhiều hơn 3 tasks, thêm thông tin tổng
    if (sortedTasks.length > 3) {
      final remaining = sortedTasks.length - 3;
      parts.add('\n... và $remaining bài tập khác');
    }
    
    return parts.join('\n');
  }
}
