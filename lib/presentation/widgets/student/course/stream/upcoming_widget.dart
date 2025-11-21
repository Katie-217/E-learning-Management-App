import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/data/repositories/assignment/assignment_repository.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';

class UpcomingWidget extends StatefulWidget {
  final CourseModel course;

  const UpcomingWidget({super.key, required this.course});

  @override
  State<UpcomingWidget> createState() => _UpcomingWidgetState();
}

class _UpcomingWidgetState extends State<UpcomingWidget> {
  List<Assignment> _upcomingAssignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUpcomingAssignments();
  }

  Future<void> _loadUpcomingAssignments() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final allAssignments =
          await AssignmentRepository.getAssignmentsByCourse(widget.course.id);
      final now = DateTime.now();

      // Filter upcoming assignments (not past deadline, limit to 5)
      final upcoming = allAssignments
          .where((assignment) => assignment.deadline.isAfter(now))
          .toList()
        ..sort((a, b) => a.deadline.compareTo(b.deadline));

      setState(() {
        _upcomingAssignments = upcoming.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _getDaysLeft(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    final days = difference.inDays;

    if (days == 0) {
      final hours = difference.inHours;
      if (hours == 0) {
        final minutes = difference.inMinutes;
        return '$minutes min left';
      }
      return '$hours hour${hours > 1 ? 's' : ''} left';
    } else if (days == 1) {
      return '1 day left';
    } else {
      return '$days days left';
    }
  }

  Color _getStatusColor(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    final days = difference.inDays;

    if (days <= 1) {
      return Colors.redAccent;
    } else if (days <= 3) {
      return Colors.orangeAccent;
    } else {
      return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upcoming',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white)),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_upcomingAssignments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'No upcoming assignments',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            )
          else
            ..._upcomingAssignments.map((assignment) {
              final statusColor = _getStatusColor(assignment.deadline);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.assignment_outlined,
                                color: statusColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    assignment.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${_formatDate(assignment.deadline)}, ${_formatTime(assignment.deadline)}',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 13),
                                  ),
                                ]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _getDaysLeft(assignment.deadline),
                      style: TextStyle(color: statusColor, fontSize: 13),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
