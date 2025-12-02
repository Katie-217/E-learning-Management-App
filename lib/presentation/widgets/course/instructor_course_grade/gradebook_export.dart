import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'gradebook_table.dart';

// Conditional import: chỉ import dart:html khi compile cho web
// dart:html là Dart standard library cho web platform
import 'dart:html' as html;

class GradebookExport {
  /// Export gradebook data to CSV file
  /// 
  /// [context] - BuildContext for showing dialogs and snackbars
  /// [gradeData] - List of grade data to export
  /// [assignments] - List of assignments to include in export
  /// [selectedStudentIds] - Set of selected student IDs (empty set means export all)
  /// 
  /// Returns true if export was successful, false otherwise
  static Future<bool> exportToCSV({
    required BuildContext context,
    required List<MockGradeData> gradeData,
    required List<Assignment> assignments,
    required Set<String> selectedStudentIds,
  }) async {
    try {
      // Create CSV data
      final List<List<dynamic>> csvData = [];
      
      // Data rows - chỉ export các dòng đã được chọn
      final dataToExport = selectedStudentIds.isEmpty 
          ? gradeData // Nếu không chọn gì thì export tất cả
          : gradeData.where((data) => selectedStudentIds.contains(data.studentId)).toList();
      
      if (dataToExport.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data selected to export'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return false;
      }
      
      // Header row: Student, Group, and all assignment columns
      final headerRow = ['Student Name', 'Student ID', 'Email', 'Group'];
      for (final assignment in assignments) {
        headerRow.add('${assignment.title} (Score)');
        headerRow.add('${assignment.title} (Status)');
      }
      csvData.add(headerRow);
      
      for (final data in dataToExport) {
        final row = [
          data.studentName,
          data.studentId,
          data.studentEmail,
          data.groupName,
        ];
        
        // Add score and status for each assignment
        for (final assignment in assignments) {
          final submission = data.submissions[assignment.id];
          if (submission != null) {
            row.add(submission.score?.toStringAsFixed(1) ?? '');
            row.add(submission.status);
          } else {
            row.add('');
            row.add('not_submitted');
          }
        }
        
        csvData.add(row);
      }

      // Convert to CSV string
      const converter = ListToCsvConverter();
      final csvString = converter.convert(csvData);

      // Save file - handle web and desktop differently
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'gradebook_$timestamp.csv';
      final csvBytes = utf8.encode(csvString);

      // Web: Use browser download
      try {
        _downloadFileWeb(csvBytes, fileName);
        
        if (context.mounted) {
          final selectedCount = dataToExport.length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'CSV exported successfully!\n'
                'Exported $selectedCount student(s).\n'
                'File: $fileName',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
        return true;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error downloading file: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting CSV: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  /// Web-specific download function
  static void _downloadFileWeb(Uint8List bytes, String fileName) {
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}

