// ========================================
// FILE: gradebook_export_v2.dart
// PURPOSE: CSV Export using Assignment Tracker Data
// DESCRIPTION: Export real tracker data to CSV
// ========================================

import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:elearning_management_app/domain/models/assignment_tracker_model.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/domain/models/quiz_tracker_model.dart';
import 'package:elearning_management_app/domain/models/quiz_model.dart';

class GradebookExportV2 {
  /// Export Assignment Tracker data to CSV file (download)
  static Future<void> downloadAssignmentCSV({
    required BuildContext context,
    required List<AssignmentTrackerModel> trackers,
    required Assignment assignment,
    required Set<String> selectedStudentIds,
  }) async {
    if (trackers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Filter by selection if any
    final dataToExport = selectedStudentIds.isNotEmpty
        ? trackers
            .where((t) => selectedStudentIds.contains(t.studentId))
            .toList()
        : trackers;

    if (dataToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No selected data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Build CSV
    final List<List<dynamic>> rows = [];

    // Header
    rows.add([
      'Student ID',
      'Student Name',
      'Email',
      'Group',
      'Status',
      'Submitted At',
      'Is Late',
      'Attempts',
      'Grade',
      'Max Points',
      'Percentage',
      'Feedback',
    ]);

    // Data rows
    for (final tracker in dataToExport) {
      rows.add([
        tracker.studentId,
        tracker.studentName,
        tracker.studentEmail,
        tracker.groupName,
        tracker.status.displayName,
        tracker.submittedAt != null
            ? DateFormat('yyyy-MM-dd HH:mm:ss')
                .format(tracker.submittedAt!.toLocal())
            : '',
        tracker.isLate ? 'Yes' : 'No',
        tracker.attemptCount,
        tracker.grade?.toStringAsFixed(2) ?? '',
        tracker.maxPoints.toStringAsFixed(2),
        tracker.gradePercentage != null
            ? '${tracker.gradePercentage!.toStringAsFixed(2)}%'
            : '',
        tracker.feedback ?? '',
      ]);
    }

    // Convert to CSV string
    final String csv = const ListToCsvConverter().convert(rows);

    // Download CSV file (Web)
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName =
        'assignment_${assignment.title.replaceAll(' ', '_')}_$timestamp.csv';

    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '✅ CSV file downloaded!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Exported ${dataToExport.length} assignment records',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Export Quiz Tracker data to CSV file (download)
  static Future<void> downloadQuizCSV({
    required BuildContext context,
    required List<QuizTrackerModel> trackers,
    required Quiz quiz,
    required Set<String> selectedStudentIds,
  }) async {
    if (trackers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Filter by selection if any
    final dataToExport = selectedStudentIds.isNotEmpty
        ? trackers
            .where((t) => selectedStudentIds.contains(t.studentId))
            .toList()
        : trackers;

    if (dataToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No selected data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Build CSV
    final List<List<dynamic>> rows = [];

    // Header
    rows.add([
      'Student ID',
      'Student Name',
      'Email',
      'Group',
      'Status',
      'Attempt Count',
      'Max Attempts',
      'Last Attempt',
      'Score',
      'Total Points',
      'Percentage',
      'Time Spent (min)',
    ]);

    // Data rows
    for (final tracker in dataToExport) {
      final totalPoints = quiz.points ?? 100;
      final percentage = tracker.score != null
          ? (tracker.score! / totalPoints * 100).toStringAsFixed(2)
          : '';

      rows.add([
        tracker.studentId,
        tracker.studentName,
        tracker.studentEmail,
        tracker.groupName,
        tracker.statusDisplay,
        tracker.attemptCount,
        quiz.maxAttempts ?? 1,
        tracker.lastAttemptAt != null
            ? DateFormat('yyyy-MM-dd HH:mm:ss')
                .format(tracker.lastAttemptAt!.toLocal())
            : '',
        tracker.score?.toStringAsFixed(2) ?? '',
        totalPoints.toStringAsFixed(2),
        percentage.isNotEmpty ? '$percentage%' : '',
        '', // Time spent - not available in QuizTrackerModel
      ]);
    }

    // Convert to CSV string
    final String csv = const ListToCsvConverter().convert(rows);

    // Download CSV file (Web)
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'quiz_${quiz.title.replaceAll(' ', '_')}_$timestamp.csv';

    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '✅ CSV file downloaded!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Exported ${dataToExport.length} quiz records',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
