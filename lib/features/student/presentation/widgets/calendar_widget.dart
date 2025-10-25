import 'package:flutter/material.dart';

class SimpleCalendar extends StatelessWidget {
  const SimpleCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    // Simple calendar implementation
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    return Column(
      children: [
        // Days of week header
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar grid
        ...List.generate(6, (week) {
          return Row(
            children: List.generate(7, (day) {
              final dayNumber = week * 7 + day - firstWeekday + 2;
              final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
              final isToday = isCurrentMonth && dayNumber == now.day;

              return Expanded(
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isToday 
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: Text(
                      isCurrentMonth ? dayNumber.toString() : '',
                      style: TextStyle(
                        color: isToday
                            ? Colors.blue
                            : isCurrentMonth 
                                ? Colors.white 
                                : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,

                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}