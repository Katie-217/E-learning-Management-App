// Assignment card widget
import 'package:flutter/material.dart';
import '../../../../../data/models/assignment_model.dart';

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  const AssignmentCard({super.key, required this.assignment});

  Color _statusBg() {
    switch (assignment.status) {
      case 'completed': return Colors.green.withOpacity(0.12);
      case 'upcoming': return Colors.orange.withOpacity(0.12);
      default: return Colors.blue.withOpacity(0.12);
    }
  }
  Color _statusText() {
    switch (assignment.status) {
      case 'completed': return Colors.greenAccent;
      case 'upcoming': return Colors.orangeAccent;
      default: return Colors.lightBlueAccent;
    }
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
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _statusBg(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.file_copy, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assignment.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(assignment.dueDate, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(assignment.grade, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusBg(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  assignment.status,
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
