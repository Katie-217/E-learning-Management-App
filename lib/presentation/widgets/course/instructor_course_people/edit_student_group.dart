import 'package:flutter/material.dart';

/// Widget Edit Student Group - Component tách riêng cho menu hành động sinh viên
/// Dành cho hành động cấp Cá nhân (Individual Student Actions)
class EditStudentGroup extends StatelessWidget {
  final Map<String, dynamic> student;
  final List<String> availableGroups;
  final String currentGroup;
  final Function(Map<String, dynamic> student) onMoveStudent;
  final Function(Map<String, dynamic> student) onRemoveStudent;

  const EditStudentGroup({
    super.key,
    required this.student,
    required this.availableGroups,
    required this.currentGroup,
    required this.onMoveStudent,
    required this.onRemoveStudent,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      color: const Color(0xFF1F2937),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'edit_group',
          child: const Row(
            children: [
              Icon(Icons.group, color: Colors.blue, size: 20),
              SizedBox(width: 12),
              Text('Edit Group', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'remove_student',
          child: const Row(
            children: [
              Icon(Icons.person_remove, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Text('Remove Student', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
      onSelected: (value) => _handleMenuAction(context, value),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit_group':
        _showMoveStudentDialog(context);
        break;
      case 'remove_student':
        _showRemoveStudentDialog(context);
        break;
    }
  }

  void _showMoveStudentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: Text('Move ${student['name']}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableGroups
              .where((g) => g != currentGroup && g != 'All Groups')
              .map((group) => ListTile(
                    leading: const Icon(Icons.group, color: Colors.indigo),
                    title: Text(group, style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      onMoveStudent(student);
                      _showMoveConfirmation(context, group);
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showRemoveStudentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('Remove Student', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove ${student['name']} from this course?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRemoveStudent(student);
              _showRemoveConfirmation(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showMoveConfirmation(BuildContext context, String targetGroup) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Moved ${student['name']} to $targetGroup'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            // Implement undo logic
          },
        ),
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${student['name']} from course'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            // Implement undo logic
          },
        ),
      ),
    );
  }
}