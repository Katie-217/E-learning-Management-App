import 'package:flutter/material.dart';

class UpcomingEventsWidget extends StatelessWidget {
  const UpcomingEventsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu tĩnh (bạn có thể load từ Firestore sau)
    final events = [
      {
        'day': 'MON',
        'color': const Color(0xFFEF4444), // red
        'items': [
          {'title': 'Team Meetup', 'time': '9:30 - 10:30'}
        ]
      },
      {
        'day': 'TUE',
        'color': const Color(0xFF8B5CF6), // purple
        'items': [
          {'title': 'Illustration', 'time': '9:30 - 11:30'}
        ]
      },
      {
        'day': 'WED',
        'color': const Color(0xFF3B82F6), // blue
        'items': [
          {'title': 'Research', 'time': '8:30 - 10:30'}
        ]
      },
      {
        'day': 'THU',
        'color': const Color(0xFFF97316), // orange
        'items': [
          {'title': 'Presentation', 'time': '1:00 - 3:00'}
        ]
      },
      {
        'day': 'SAT',
        'color': const Color(0xFF10B981), // green
        'items': [
          {'title': 'Report', 'time': '10:00 - 12:00'}
        ]
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Upcoming Events",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 16),
          // Render từng ngày
          Column(
            children: events.map((dayData) {
              final Color color = dayData['color'] as Color;
              final List<Map<String, dynamic>> items = (dayData['items'] as List).cast<Map<String, dynamic>>();
              return Padding(
                padding: const EdgeInsets.only(bottom: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day label
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        dayData["day"] as String,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // Timeline + event cards
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vertical gradient bar
                        Container(
                          width: 4,
                          height: items.length * 60.0,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withOpacity(0.0)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Events list
                        Expanded(
                          child: Column(
                            children: items.map((item) {
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: color.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['time'],
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
