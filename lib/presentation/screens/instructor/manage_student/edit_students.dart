import 'package:flutter/material.dart';
import '../../../../application/controllers/student/student_controller.dart';
import '../../../../domain/models/user_model.dart';

/// Controller để quản lý logic edit và delete student
class StudentEditController {
  final StudentController _studentController;

  StudentEditController(this._studentController);

  /// Update student profile (phone only)
  Future<bool> updateStudent({
    required String studentUid,
    String? phone,
  }) async {
    try {
      return await _studentController.updateStudentProfile(
        studentUid,
        phone: phone,
      );
    } catch (e) {
      debugPrint('Error updating student: $e');
      rethrow;
    }
  }

  /// Update student email (via Cloud Function)
  /// This updates both Authentication and Firestore
  Future<Map<String, dynamic>> updateStudentEmail({
    required String studentUid,
    required String newEmail,
  }) async {
    try {
      return await _studentController.updateStudentEmail(studentUid, newEmail);
    } catch (e) {
      debugPrint('Error updating student email: $e');
      rethrow;
    }
  }

  /// Delete student (mark as inactive)
  Future<Map<String, dynamic>> deleteStudent(String studentUid) async {
    try {
      return await _studentController.deleteStudent(studentUid);
    } catch (e) {
      debugPrint('Error deleting student: $e');
      rethrow;
    }
  }

  /// Show confirmation dialog for delete action
  Future<bool> showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Confirm Complete Deletion',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to PERMANENTLY delete this student?\n\n'
          '⚠️ This will:\n'
          '• Delete Authentication (logout immediately)\n'
          '• Delete Firestore profile\n'
          '• Delete all enrollments\n\n'
          '❌ This action CANNOT be undone!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

/// Dialog widget mới với inline editing
/// Không cần màn hình Edit riêng, mở lên là sửa được luôn
class StudentEditDialog extends StatefulWidget {
  final UserModel student;
  final StudentEditController controller;
  final VoidCallback onUpdated;

  const StudentEditDialog({
    super.key,
    required this.student,
    required this.controller,
    required this.onUpdated,
  });

  @override
  State<StudentEditDialog> createState() => _StudentEditDialogState();
}

class _StudentEditDialogState extends State<StudentEditDialog> {
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.student.email);
    _phoneController = TextEditingController(
      text: widget.student.phoneNumber ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    try {
      final newEmail = _emailController.text.trim();
      final newPhone = _phoneController.text.trim();
      final oldEmail = widget.student.email;

      bool emailUpdated = false;
      bool phoneUpdated = false;

      // Update email if changed (via Cloud Function)
      if (newEmail != oldEmail) {
        try {
          final result = await widget.controller.updateStudentEmail(
            studentUid: widget.student.uid,
            newEmail: newEmail,
          );

          if (result['success'] == true) {
            emailUpdated = true;
            debugPrint(
              '✅ Email updated: ${result['oldEmail']} → ${result['newEmail']}',
            );
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update email: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSaving = false);
          return; // Stop if email update fails
        }
      }

      // Update phone
      final success = await widget.controller.updateStudent(
        studentUid: widget.student.uid,
        phone: newPhone,
      );

      if (success) {
        phoneUpdated = true;
      }

      if (!mounted) return;

      if (emailUpdated || phoneUpdated) {
        String message = 'Updated successfully';
        if (emailUpdated && phoneUpdated) {
          message = 'Email and phone updated successfully';
        } else if (emailUpdated) {
          message = 'Email updated successfully';
        } else if (phoneUpdated) {
          message = 'Phone updated successfully';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
        widget.onUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes to save'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    // Confirm deletion
    final confirmed = await widget.controller.showDeleteConfirmation(context);
    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);

    try {
      final result = await widget.controller.deleteStudent(widget.student.uid);

      if (!mounted) return;

      if (result['success'] == true) {
        // Show detailed deletion results
        final deletionResults = result['deletionResults'];
        final message =
            '''Student deleted successfully!
• Authentication: ${deletionResults['authDeleted'] ? '✅' : '❌'}
• Profile: ${deletionResults['firestoreDeleted'] ? '✅' : '❌'}
• Enrollments: ${deletionResults['enrollmentsDeleted']} deleted''';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
        widget.onUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete student'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1F2937),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: Row(
        children: [
          // Tên sinh viên (Header)
          Expanded(
            child: Text(
              widget.student.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Nút Delete ở góc trên bên phải
          IconButton(
            onPressed: _isSaving ? null : _handleDelete,
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete Student',
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Email (Editable with warning)
            _buildEditableField(
              label: 'Email (Change with caution)',
              controller: _emailController,
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 16),

            // Phone (Editable)
            _buildEditableField(
              label: 'Phone Number',
              controller: _phoneController,
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 24), // Thêm khoảng cách lớn hơn
          ],
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),

        // Save button
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[500]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[800],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
