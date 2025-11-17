// presentation/widgets/instructor/student_detail_dialog.dart
import 'package:flutter/material.dart';
import '../../../domain/models/student_model.dart';
class StudentDetailDialog extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StudentDetailDialog({
    super.key,
    required this.student,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1F2937),
      title: Text(student.name, style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('📧 Email:', student.email),
            _buildDetailRow('🆔 Student Code:', student.studentCode ?? 'N/A'),
            _buildDetailRow('📱 Phone:', student.phone ?? 'N/A'),
            _buildDetailRow('🏢 Department:', student.department ?? 'N/A'),
            _buildDetailRow(
              '📚 Courses:',
              '${student.courseIds.length} courses',
            ),
            _buildDetailRow(
              '👥 Groups:',
              '${student.groupIds.length} groups',
            ),
            _buildDetailRow(
              '✅ Status:',
              student.isActive ? 'Active' : 'Inactive',
              valueColor: student.isActive ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onEdit();
          },
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Edit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onDelete();
          },
          icon: const Icon(Icons.delete, size: 18),
          label: const Text('Delete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}