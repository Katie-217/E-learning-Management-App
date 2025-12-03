import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

import 'gradebook_table.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';

/// Simple CSV export helper for the Grade tab.
///
/// Để tránh phụ thuộc vào file hệ thống (nhất là trên Windows),
/// hàm này sẽ generate CSV rồi copy vào clipboard.
/// Người dùng chỉ cần mở Excel/Google Sheets và **Paste**.
class GradebookExport {
  static Future<void> exportToCSV({
    required BuildContext context,
    required List<MockGradeData> gradeData,
    required List<Assignment> assignments,
    required Set<String> selectedStudentIds,
  }) async {
    if (gradeData.isEmpty || assignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final rowsData = (selectedStudentIds.isNotEmpty)
        ? gradeData.where((d) => selectedStudentIds.contains(d.studentId)).toList()
        : gradeData;

    final header = <String>[
      'Student ID',
      'Student Name',
      'Email',
      'Group',
      ...assignments.map((a) => a.title),
    ];

    final rows = <List<String>>[];
    rows.add(header);

    for (final student in rowsData) {
      final row = <String>[
        student.studentId,
        student.studentName,
        student.studentEmail,
        student.groupName,
      ];

      for (final assignment in assignments) {
        final submission = student.submissions[assignment.id];
        final score = submission?.score;
        row.add(score != null ? score.toStringAsFixed(1) : '');
      }

      rows.add(row);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    await Clipboard.setData(ClipboardData(text: csvData));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV copied to clipboard. Paste it into Excel or Google Sheets.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
