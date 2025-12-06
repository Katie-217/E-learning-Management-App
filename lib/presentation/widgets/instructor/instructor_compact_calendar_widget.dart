import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/application/controllers/instructor/task_provider.dart';
import 'package:elearning_management_app/domain/models/task_model.dart';

class InstructorCompactCalendarWidget extends ConsumerStatefulWidget {
  const InstructorCompactCalendarWidget({super.key});

  @override
  ConsumerState<InstructorCompactCalendarWidget> createState() => _InstructorCompactCalendarWidgetState();
}

class _InstructorCompactCalendarWidgetState extends ConsumerState<InstructorCompactCalendarWidget> {
  DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
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
    ref.read(selectedDateProvider.notifier).state = date;
    if (date.year != _currentDate.year || date.month != _currentDate.month) {
      setState(() {
        _currentDate = DateTime(date.year, date.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final tasksForMonth = ref.watch(tasksForMonthProvider(_currentDate));

    return _CompactSimpleCalendar(
      currentDate: _currentDate,
      selectedDate: selectedDate,
      tasksForMonth: tasksForMonth.value ?? [],
      onPreviousMonth: _previousMonth,
      onNextMonth: _nextMonth,
      onGoToToday: _goToToday,
      onDateSelected: _onDateSelected,
    );
  }
}

class _CompactSimpleCalendar extends StatelessWidget {
  final DateTime currentDate;
  final DateTime selectedDate;
  final List<TaskModel> tasksForMonth;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;
  final VoidCallback? onGoToToday;
  final Function(DateTime)? onDateSelected;

  const _CompactSimpleCalendar({
    required this.currentDate,
    required this.selectedDate,
    this.tasksForMonth = const [],
    this.onPreviousMonth,
    this.onNextMonth,
    this.onGoToToday,
    this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(currentDate.year, currentDate.month, 1);
    final lastDay = DateTime(currentDate.year, currentDate.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7;
    final isCurrentMonth = currentDate.year == now.year && currentDate.month == now.month;

    return Container(
      padding: const EdgeInsets.all(8),
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
                icon: const Icon(Icons.chevron_left, size: 16), // Giảm từ 20 xuống 16
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
                      fontSize: 12, // Giảm từ 14 xuống 12
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 16), // Giảm từ 20 xuống 16
                onPressed: onNextMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: Colors.grey[700],
              ),
            ],
          ),
          // Show "Today" button
          if (isCurrentMonth && onGoToToday != null)
            Padding(
              padding: const EdgeInsets.only(top: 1, bottom: 3), // Giảm padding
              child: TextButton(
                onPressed: onGoToToday,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0), // Giảm padding
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(fontSize: 9, color: Colors.blue), // Giảm từ 10 xuống 9
                ),
              ),
            ),
          if (!isCurrentMonth || onGoToToday == null)
            const SizedBox(height: 3), // Giảm từ 4 xuống 3
          // Days of week header
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 9, // Giảm từ 10 xuống 9
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 3), // Giảm từ 4 xuống 3
          // Calendar grid
          ...List.generate(6, (week) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 0.5), // Giảm từ 1 xuống 0.5
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final dayNumber = week * 7 + dayIndex - firstWeekday + 1;
                  final isCurrentMonthDay = dayNumber > 0 && dayNumber <= daysInMonth;
                  
                  if (!isCurrentMonthDay) {
                    return Expanded(
                      child: Container(
                        height: 20, // Giảm từ 22 xuống 20
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      ),
                    );
                  }

                  final date = DateTime(currentDate.year, currentDate.month, dayNumber);
                  final isToday = (currentDate.year == now.year && 
                                   currentDate.month == now.month) &&
                                  (date.year == now.year && 
                                   date.month == now.month && 
                                   date.day == now.day);
                  final isSelected = currentDate.year == selectedDate.year &&
                                    currentDate.month == selectedDate.month &&
                                    date.year == selectedDate.year && 
                                    date.month == selectedDate.month && 
                                    date.day == selectedDate.day;
                  
                  final hasTasks = tasksForMonth.any((task) {
                    final taskDate = DateTime(
                      task.dateTime.year,
                      task.dateTime.month,
                      task.dateTime.day,
                    );
                    return taskDate.year == date.year &&
                           taskDate.month == date.month &&
                           taskDate.day == date.day;
                  });

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onDateSelected?.call(date),
                      child: Container(
                        height: 20, // Giảm từ 22 xuống 20
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(4), // Giảm từ 5 xuống 4
                          border: isToday && !isSelected
                              ? Border.all(color: Colors.blue.withOpacity(0.5), width: 1)
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isSelected)
                              Container(
                                width: 18, // Giảm từ 20 xuống 18
                                height: 18, // Giảm từ 20 xuống 18
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(3), // Giảm từ 4 xuống 3
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            Center(
                              child: Text(
                                dayNumber.toString(),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : isToday
                                          ? Colors.blue
                                          : Colors.black87,
                                  fontSize: 9, // Giảm từ 10 xuống 9
                                  fontWeight: (isSelected || isToday) 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (hasTasks && !isSelected && !isToday)
                              Positioned(
                                bottom: 1,
                                child: Container(
                                  width: 2, // Giảm từ 2.5 xuống 2
                                  height: 2, // Giảm từ 2.5 xuống 2
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

