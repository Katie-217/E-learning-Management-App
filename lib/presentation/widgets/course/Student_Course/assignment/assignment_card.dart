// Assignment card widget
import 'package:flutter/material.dart';
import '../../../../../domain/models/assignment_model.dart';

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback? onTap;
  
  const AssignmentCard({
    super.key, 
    required this.assignment,
    this.onTap,
  });

  String _getStatus() {
    final now = DateTime.now();
    if (now.isBefore(assignment.startDate)) {
      return 'upcoming';
    } else if (now.isAfter(assignment.deadline)) {
      return 'overdue';
    } else {
      return 'active';
    }
  }

  Color _statusBg() {
    switch (_getStatus()) {
      case 'overdue':
        return Colors.red.withOpacity(0.12);
      case 'upcoming':
        return Colors.orange.withOpacity(0.12);
      case 'active':
        return Colors.blue.withOpacity(0.12);
      default:
        return Colors.grey.withOpacity(0.12);
    }
  }

  Color _statusText() {
    switch (_getStatus()) {
      case 'overdue':
        return Colors.redAccent;
      case 'upcoming':
        return Colors.orangeAccent;
      case 'active':
        return Colors.lightBlueAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon với màu status
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
            // Nội dung chính
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
                  ),
                  const SizedBox(height: 12),
                  // Deadline
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Due ${_formatDate(assignment.deadline)} at ${_formatTime(assignment.deadline)}',
                        style: TextStyle(
                          color: status == 'overdue' 
                              ? Colors.red[400] 
                              : Colors.grey[400],
                          fontSize: 13,
                          fontWeight: status == 'overdue' 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                status.toUpperCase(),
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
      ),
    );
  }
}
