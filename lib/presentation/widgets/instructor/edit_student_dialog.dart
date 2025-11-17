// presentation/widgets/instructor/edit_student_dialog.dart
import 'package:flutter/material.dart';
import '../../../domain/models/student_model.dart';
class EditStudentDialog extends StatelessWidget {
  final StudentModel student;
  final Function(String name, String phone, String department) onSave;

  const EditStudentDialog({
    super.key,
    required this.student,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: student.name);
    final phoneController = TextEditingController(text: student.phone ?? '');
    final departmentController = TextEditingController(text: student.department ?? '');

    return AlertDialog(
      backgroundColor: const Color(0xFF1F2937),
      title: const Text('✏️ Edit Student Information',
          style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '👤 Student Name',
                labelStyle: const TextStyle(color: Colors.grey),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '📱 Phone Number',
                labelStyle: const TextStyle(color: Colors.grey),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: departmentController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '🏢 Department',
                labelStyle: const TextStyle(color: Colors.grey),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('❌ Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onSave(nameController.text, phoneController.text, departmentController.text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('✅ Save'),
        ),
      ],
    );
  }
}