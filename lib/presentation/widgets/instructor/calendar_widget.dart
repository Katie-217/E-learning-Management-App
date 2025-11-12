import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/application/controllers/instructor/task_provider.dart';
import 'package:elearning_management_app/domain/models/task_model.dart';

class CalendarWidget extends ConsumerStatefulWidget {
  const CalendarWidget({super.key});

  @override
  ConsumerState<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends ConsumerState<CalendarWidget> {
  DateTime _currentDate = DateTime.now();

  void _previousMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
    });
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
    // Update currentDate if selected date is in a different month
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

    return SimpleCalendar(
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

class SimpleCalendar extends StatelessWidget {
  final DateTime currentDate;
  final DateTime selectedDate;
  final List<TaskModel> tasksForMonth;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;
  final VoidCallback? onGoToToday;
  final Function(DateTime)? onDateSelected;

  const SimpleCalendar({
    super.key,
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
    final firstWeekday = firstDay.weekday % 7; // Convert to 0-6 (Sunday = 0)
    final isCurrentMonth = currentDate.year == now.year && currentDate.month == now.month;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month and Year Header with Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 24),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 24),
                onPressed: onNextMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: Colors.grey[700],
              ),
            ],
          ),
          if (!isCurrentMonth && onGoToToday != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton(
                onPressed: onGoToToday,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ),
          // Days of week header
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Calendar grid
          ...List.generate(6, (week) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final dayNumber = week * 7 + dayIndex - firstWeekday + 1;
                  final isCurrentMonthDay = dayNumber > 0 && dayNumber <= daysInMonth;
                  
                  if (!isCurrentMonthDay) {
                    return Expanded(
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                    );
                  }

                  final date = DateTime(currentDate.year, currentDate.month, dayNumber);
                  final isToday = date.year == now.year && 
                                  date.month == now.month && 
                                  date.day == now.day;
                  final isSelected = date.year == selectedDate.year && 
                                    date.month == selectedDate.month && 
                                    date.day == selectedDate.day;
                  
                  // Check if this date has tasks
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
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.2)
                              : isToday 
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: Colors.blue, width: 2)
                              : isToday
                                  ? Border.all(color: Colors.blue, width: 1.5)
                                  : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Center(
                              child: Text(
                                dayNumber.toString(),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.blue
                                      : isToday
                                          ? Colors.blue
                                          : Colors.black87,
                                  fontSize: 14,
                                  fontWeight: (isSelected || isToday) 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            // Indicator for days with tasks
                            if (hasTasks && !isSelected && !isToday)
                              Positioned(
                                bottom: 4,
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
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
