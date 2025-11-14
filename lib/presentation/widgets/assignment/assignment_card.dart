// Assignment card widget
import 'package:flutter/material.dart';
import '../../../domain/models/assignment_model.dart';

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  const AssignmentCard({super.key, required this.assignment});

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
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _statusBg(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.assignment, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assignment.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Deadline: ${_formatDate(assignment.deadline)}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                if (assignment.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    assignment.description.length > 50
                        ? '${assignment.description.substring(0, 50)}...'
                        : assignment.description,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${assignment.maxSubmissionAttempts} attempts',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusBg(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatus(),
                  style: TextStyle(color: _statusText(), fontSize: 12),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
