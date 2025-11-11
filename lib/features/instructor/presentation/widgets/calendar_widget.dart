import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/task_provider.dart';

class CalendarWidget extends ConsumerStatefulWidget {
  const CalendarWidget({super.key});

  @override
  ConsumerState<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends ConsumerState<CalendarWidget> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      // Update selected date to first day of the new month if selected date is not in current month
      if (!_isCurrentMonth(_selectedDate, _currentMonth)) {
        _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
        ref.read(selectedDateProvider.notifier).state = _selectedDate;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      // Update selected date to first day of the new month if selected date is not in current month
      if (!_isCurrentMonth(_selectedDate, _currentMonth)) {
        _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
        ref.read(selectedDateProvider.notifier).state = _selectedDate;
      }
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    ref.read(selectedDateProvider.notifier).state = date;
  }


  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isCurrentMonth(DateTime date, DateTime month) {
    return date.year == month.year && date.month == month.month;
  }

  @override
  Widget build(BuildContext context) {
    // Get the week containing the selected date
    final selectedWeek = _getWeekForDate(_selectedDate);
    final monthName = DateFormat('MMMM yyyy').format(_currentMonth);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calendar Title
        const Text(
          'Calendar',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        // Calendar Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _previousMonth,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Text(
                      monthName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextMonth,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Days of week headers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                      .map((day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                // Week dates
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: selectedWeek.map((date) {
                    final isSelected = _isSameDay(date, _selectedDate);
                    final isToday = _isSameDay(date, today);
                    final isCurrentMonthDay = _isCurrentMonth(date, _currentMonth);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _selectDate(date);
                          // Update current month if clicking on a different month
                          if (!_isCurrentMonth(date, _currentMonth)) {
                            setState(() {
                              _currentMonth = DateTime(date.year, date.month);
                            });
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.purple
                                : Colors.transparent,
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Day letter (first letter of weekday)
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    DateFormat('E').format(date)[0],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                )
                              else if (isToday)
                                Text(
                                  DateFormat('E').format(date)[0],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.purple,
                                  ),
                                )
                              else
                                Text(
                                  DateFormat('E').format(date)[0],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : (isCurrentMonthDay
                                          ? Colors.black87
                                          : Colors.grey.shade400),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<DateTime> _getWeekForDate(DateTime date) {
    // Get the Monday of the week containing the date
    final daysFromMonday = (date.weekday - 1) % 7;
    final monday = date.subtract(Duration(days: daysFromMonday));
    
    // Return 7 days starting from Monday
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }
}

