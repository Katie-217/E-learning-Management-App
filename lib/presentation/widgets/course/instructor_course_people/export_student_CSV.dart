import 'package:flutter/material.dart';

/// Widget Export Student CSV - Component tách riêng cho hành động Export List
/// Dành cho hành động cấp Khóa học (Course Level Actions)
class ExportStudentCSV extends StatelessWidget {
  final String selectedGroup;
  final VoidCallback onExport;

  const ExportStudentCSV({
    super.key,
    required this.selectedGroup,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.download, color: Colors.blue),
      tooltip: 'Export student list',
      onPressed: () => _showExportDialog(context),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('Export Student List', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export students from: $selectedGroup',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose export format:',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onExport();
              _exportStudentList(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            icon: const Icon(Icons.download),
            label: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }

  void _exportStudentList(BuildContext context) {
    // Logic export CSV
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting students from $selectedGroup'),
        backgroundColor: Colors.blue,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Open file location hoặc download dialog
          },
        ),
      ),
    );
  }
}