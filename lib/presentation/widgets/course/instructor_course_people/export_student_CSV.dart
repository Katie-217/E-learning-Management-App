import 'package:flutter/material.dart';

/// Widget Export Student CSV - Component tách riêng cho hành động Export List
/// Dành cho hành động cấp Khóa học (Course Level Actions)
class ExportStudentCSV extends StatelessWidget {
  final String selectedGroup;
  final VoidCallback onExport;
  final bool isSmallScreen;

  const ExportStudentCSV({
    super.key,
    required this.selectedGroup,
    required this.onExport,
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