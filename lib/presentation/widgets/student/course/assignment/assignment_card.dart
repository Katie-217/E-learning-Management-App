// Assignment card widget
import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback? onTap;
  final bool? isSubmitted;
  final DateTime? submittedAt;

  const AssignmentCard({
    super.key,
    required this.assignment,
    this.onTap,
    this.isSubmitted,
    this.submittedAt,
  });

  String _getStatus() {
    final now = DateTime.now();

    // If submitted, check submission time
    if (isSubmitted == true && submittedAt != null) {
      if (submittedAt!.isBefore(assignment.deadline) ||
          submittedAt!.isAtSameMomentAs(assignment.deadline)) {
        return 'turned_in'; // Turned In (Green)
      } else if (assignment.allowLateSubmissions &&
              assignment.lateDeadline != null &&
              submittedAt!.isBefore(assignment.lateDeadline!) ||
          submittedAt!.isAtSameMomentAs(assignment.lateDeadline!)) {
        return 'late'; // Late (Orange)
      }
    }

    // If not submitted, check deadline status
    if (now.isBefore(assignment.startDate)) {
      return 'upcoming'; // Upcoming (Blue)
    } else if (now.isAfter(assignment.startDate) &&
        now.isBefore(assignment.deadline)) {
      return 'open'; // Open (Green)
    } else if (assignment.allowLateSubmissions &&
        assignment.lateDeadline != null &&
        now.isAfter(assignment.deadline) &&
        now.isBefore(assignment.lateDeadline!)) {
      return 'late_period'; // Late Period (Orange)
    } else {
      return 'overdue'; // Overdue (Red)
    }
  }

  Color _statusBg() {
    switch (_getStatus()) {
      case 'upcoming':
        return Colors.blue.withOpacity(0.15);
      case 'open':
        return Colors.green.withOpacity(0.15);
      case 'late_period':
      case 'late':
        return Colors.orange.withOpacity(0.15);
      case 'overdue':
        return Colors.red.withOpacity(0.15);
      case 'turned_in':
        return Colors.green.withOpacity(0.15);
      default:
        return Colors.grey.withOpacity(0.12);
    }
  }

  Color _statusText() {
    switch (_getStatus()) {
      case 'upcoming':
        return Colors.blue;
      case 'open':
        return Colors.green;
      case 'late_period':
      case 'late':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'turned_in':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (_getStatus()) {
      case 'upcoming':
        return 'UPCOMING';
      case 'open':
        return 'OPEN';
      case 'late_period':
        return 'LATE PERIOD';
      case 'overdue':
        return 'OVERDUE';
      case 'turned_in':
        return 'TURNED IN';
      case 'late':
        return 'LATE';
      default:
        return 'UNKNOWN';
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final status = _getStatus();
    final statusColor = _statusText();
    final statusBg = _statusBg();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon vá»›i mÃ u status
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Ná»™i dung chÃ­nh (flexible)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        assignment.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Posted and Edited time (responsive)
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                // Posted time
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Posted ${_formatDate(assignment.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                // Edited time
                if (assignment.updatedAt != null &&
                    assignment.updatedAt != assignment.createdAt)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_note,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Edited ${_formatDate(assignment.updatedAt!)}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Deadline and status badge
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Due ${_formatDate(assignment.deadline)} at ${_formatTime(assignment.deadline)}',
                    style: TextStyle(
                      color: (status == 'overdue' || status == 'late_period')
                          ? Colors.red[400]
                          : Colors.grey[400],
                      fontSize: 13,
                      fontWeight:
                          (status == 'overdue' || status == 'late_period')
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusLabel(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
