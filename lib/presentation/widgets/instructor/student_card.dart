// presentation/widgets/instructor/student_card.dart
import 'package:flutter/material.dart';
import '../../../domain/models/student_model.dart';
class StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StudentCard({
    super.key,
    required this.student,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: const Color(0xFF1F2937),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo[600],
          child: Text(
            student.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🆔 ${student.studentCode ?? 'N/A'}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            Text(
              '📧 ${student.email}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            if (student.department != null)
              Text(
                '🏢 ${student.department}',
                style: TextStyle(color: Colors.grey[400]),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          color: const Color(0xFF1F2937),
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: () => Future.delayed(
                Duration.zero,
                onViewDetails,
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text('View Details', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => Future.delayed(
                Duration.zero,
                onEdit,
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Edit', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => Future.delayed(
                Duration.zero,
                onDelete,
              ),
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: onViewDetails,
      ),
    );
  }
}