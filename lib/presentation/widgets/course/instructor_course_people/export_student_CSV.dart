import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

/// Widget Export Student CSV - Component tách riêng cho hành động Export List
/// Dành cho hành động cấp Khóa học (Course Level Actions)
class ExportStudentCSV extends StatelessWidget {
  final String courseName;
  final String selectedGroup;
  final Future<List<Map<String, dynamic>>> Function() getStudents;
  final bool isSmallScreen;

  const ExportStudentCSV({
    super.key,
    required this.courseName,
    required this.selectedGroup,
    required this.getStudents,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isSmallScreen ? 18.0 : 24.0;
    final buttonSize = isSmallScreen ? 36.0 : 48.0;

    return IconButton(
      icon: Icon(Icons.download, color: Colors.blue, size: iconSize),
      tooltip: 'Export student list',
      onPressed: () => _showExportDialog(context),
      padding: EdgeInsets.all(isSmallScreen ? 6.0 : 8.0),
      constraints: BoxConstraints(
        minWidth: buttonSize,
        minHeight: buttonSize,
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('Export Student List',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course: $courseName',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Group: $selectedGroup',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'The CSV file will include: Course name, Group name, Student name, and Email.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _exportStudentList(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            icon: const Icon(Icons.download),
            label: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportStudentList(BuildContext context) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing student list...'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.blue,
        ),
      );

      // Get student data
      final students = await getStudents();

      if (students.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No students to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Prepare CSV data
      List<List<dynamic>> rows = [];

      // Header row
      rows.add(['Course Name', 'Group Name', 'Student Name', 'Email']);

      // Data rows
      for (final student in students) {
        rows.add([
          courseName,
          student['group'] ?? 'No Group',
          student['name'] ?? 'Unknown',
          student['email'] ?? 'No Email',
        ]);
      }

      // Convert to CSV
      String csv = const ListToCsvConverter().convert(rows);

      // Create filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final groupSuffix = selectedGroup != 'All Groups'
          ? '_${selectedGroup.replaceAll(' ', '_')}'
          : '_AllGroups';
      final filename =
          'students_${courseName.replaceAll(' ', '_')}$groupSuffix\_$timestamp.csv';

      // Download file (web)
      final bytes = html.Blob([csv], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(bytes);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${students.length} students to $filename'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
