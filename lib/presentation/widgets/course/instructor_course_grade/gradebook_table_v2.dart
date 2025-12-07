// ========================================
// FILE: gradebook_table_v2.dart
// PURPOSE: Gradebook Table using Assignment Tracker Model
// DESCRIPTION: Simplified table component using real tracker data
// ========================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/domain/models/assignment_tracker_model.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/file_preview_overlay.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/upload_file_assignment.dart';

class GradebookTableV2 extends StatefulWidget {
  final List<AssignmentTrackerModel> trackers;
  final dynamic assignment; // Can be Assignment or Quiz
  final ScrollController horizontalScrollController;
  final Set<String> selectedStudentIds;
  final Function(Set<String>) onSelectionChanged;
  final Function(String trackerId, double grade, String? feedback)?
      onGradeUpdated;

  const GradebookTableV2({
    super.key,
    required this.trackers,
    required this.assignment,
    required this.horizontalScrollController,
    required this.selectedStudentIds,
    required this.onSelectionChanged,
    this.onGradeUpdated,
  });

  @override
  State<GradebookTableV2> createState() => _GradebookTableV2State();
}

class _GradebookTableV2State extends State<GradebookTableV2> {
  final Map<String, TextEditingController> _gradeControllers = {};

  @override
  void dispose() {
    for (final controller in _gradeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Helper to get max attempts (works for both Assignment and Quiz)
  int get _maxAttempts {
    if (widget.assignment is Assignment) {
      return (widget.assignment as Assignment).maxSubmissionAttempts;
    }
    // For Quiz, use structure.maxAttempts
    return 1; // Default for quiz if not specified
  }

  TextEditingController _getController(String trackerId, double? grade) {
    if (!_gradeControllers.containsKey(trackerId)) {
      _gradeControllers[trackerId] = TextEditingController(
        text: grade?.toStringAsFixed(1) ?? '',
      );
    }
    return _gradeControllers[trackerId]!;
  }

  Color _getStatusColor(TrackerStatus status) {
    switch (status) {
      case TrackerStatus.missing:
        return Colors.red;
      case TrackerStatus.submitted:
        return Colors.blue;
      case TrackerStatus.late:
        return Colors.orange;
      case TrackerStatus.graded:
        return Colors.green;
    }
  }

  Color _getGradeColor(double? grade, double maxPoints) {
    if (grade == null) return AppColors.textMuted;
    final percentage = (grade / maxPoints) * 100;
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        if (isMobile) {
          return _buildMobileView();
        } else {
          return _buildDesktopView();
        }
      },
    );
  }

  /// Mobile Card View
  Widget _buildMobileView() {
    final allSelected = widget.trackers.isNotEmpty &&
        widget.trackers.every(
          (t) => widget.selectedStudentIds.contains(t.studentId),
        );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: allSelected,
                  tristate: true,
                  onChanged: (value) {
                    final newSelection = <String>{};
                    if (value == true) {
                      newSelection
                          .addAll(widget.trackers.map((t) => t.studentId));
                    }
                    widget.onSelectionChanged(newSelection);
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.trackers.length} Students',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Cards
          ...widget.trackers.asMap().entries.map((entry) {
            final index = entry.key;
            final tracker = entry.value;
            return Column(
              children: [
                _buildMobileCard(tracker),
                if (index < widget.trackers.length - 1)
                  const Divider(height: 1, color: AppColors.border),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileCard(AssignmentTrackerModel tracker) {
    final isSelected = widget.selectedStudentIds.contains(tracker.studentId);
    final statusColor = _getStatusColor(tracker.status);
    final gradeColor = _getGradeColor(tracker.grade, tracker.maxPoints);

    return Container(
      color: isSelected ? AppColors.surfaceVariant.withOpacity(0.3) : null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student info
          Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  final newSelection =
                      Set<String>.from(widget.selectedStudentIds);
                  if (value == true) {
                    newSelection.add(tracker.studentId);
                  } else {
                    newSelection.remove(tracker.studentId);
                  }
                  widget.onSelectionChanged(newSelection);
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tracker.studentName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      tracker.groupName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor, width: 1),
            ),
            child: Text(
              _getStatusText(tracker.status),
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          if (tracker.submittedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm')
                      .format(tracker.submittedAt!.toLocal()),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Files and Attempts row
          Row(
            children: [
              // Files
              Expanded(
                child: tracker.attachments.isEmpty
                    ? Row(
                        children: [
                          const Icon(Icons.attach_file,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          const Text(
                            'Files: 0',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : InkWell(
                        onTap: () => _showFileListDialog(tracker),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.attach_file,
                                  size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'Files: ${tracker.attachments.length}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Attempts
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.replay,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Attempts: ',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${tracker.attemptCount}/$_maxAttempts',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Grade input
          Row(
            children: [
              const Text(
                'Grade: ',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: gradeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: gradeColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _getController(tracker.id, tracker.grade),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: TextStyle(
                            color: gradeColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onSubmitted: (value) {
                            final score = double.tryParse(value);
                            if (score != null &&
                                widget.onGradeUpdated != null) {
                              widget.onGradeUpdated!(tracker.id, score, null);
                            }
                          },
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '/${tracker.maxPoints.toInt()}',
                          style: TextStyle(
                            color: gradeColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Desktop Table View
  Widget _buildDesktopView() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTableHeader(),
          const Divider(height: 1, color: AppColors.border),
          // Use Column instead of ListView to avoid unbounded height
          ...widget.trackers.asMap().entries.map((entry) {
            final index = entry.key;
            final tracker = entry.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTableRow(tracker),
                if (index < widget.trackers.length - 1)
                  const Divider(height: 1, color: AppColors.border),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    final allSelected = widget.trackers.isNotEmpty &&
        widget.trackers
            .every((t) => widget.selectedStudentIds.contains(t.studentId));
    final allGraded = widget.trackers.isNotEmpty &&
        widget.trackers.every((t) => t.status == TrackerStatus.graded);

    return Container(
      color: AppColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            tristate: true,
            activeColor: allGraded ? Colors.green : AppColors.primary,
            onChanged: (value) {
              final newSelection = <String>{};
              if (value == true) {
                newSelection.addAll(widget.trackers.map((t) => t.studentId));
              }
              widget.onSelectionChanged(newSelection);
            },
          ),
          const SizedBox(width: 12),
          const Expanded(
            flex: 2,
            child: Text(
              'Student',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Group',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const Expanded(
            flex: 3,
            child: Text(
              'Status / Time',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Files',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Expanded(
            child: Text(
              'Attempts',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Expanded(
            child: Text(
              'Grade',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(AssignmentTrackerModel tracker) {
    final isSelected = widget.selectedStudentIds.contains(tracker.studentId);
    final statusColor = _getStatusColor(tracker.status);
    final gradeColor = _getGradeColor(tracker.grade, tracker.maxPoints);

    return Container(
      color: isSelected ? AppColors.surfaceVariant.withOpacity(0.3) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            activeColor: tracker.status == TrackerStatus.graded
                ? Colors.green
                : AppColors.primary,
            onChanged: (value) {
              final newSelection = Set<String>.from(widget.selectedStudentIds);
              if (value == true) {
                newSelection.add(tracker.studentId);
              } else {
                newSelection.remove(tracker.studentId);
              }
              widget.onSelectionChanged(newSelection);
            },
          ),
          const SizedBox(width: 12),

          // Student name
          Expanded(
            flex: 2,
            child: Text(
              tracker.studentName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),

          // Group
          Expanded(
            child: Text(
              tracker.groupName,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),

          // Status / Time column
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    _getStatusText(tracker.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Timestamp
                Text(
                  tracker.submittedAt != null
                      ? DateFormat('MMM dd, HH:mm')
                          .format(tracker.submittedAt!.toLocal())
                      : '-',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Files column
          Expanded(
            child: Center(
              child: tracker.attachments.isEmpty
                  ? const Text(
                      '-',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    )
                  : TextButton.icon(
                      onPressed: () => _showFileListDialog(tracker),
                      icon: const Icon(Icons.attach_file, size: 16),
                      label: Text('${tracker.attachments.length}'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
            ),
          ),

          // Attempts column
          Expanded(
            child: Center(
              child: Text(
                '${tracker.attemptCount}/$_maxAttempts',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // Grade input
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _getController(tracker.id, tracker.grade),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      color: gradeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: gradeColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: gradeColor.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: gradeColor, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onChanged: (value) {
                      // Auto-save on any change (debounce could be added)
                      final score = double.tryParse(value);
                      if (score != null &&
                          score >= 0 &&
                          score <= tracker.maxPoints) {
                        if (widget.onGradeUpdated != null) {
                          widget.onGradeUpdated!(tracker.id, score, null);
                        }
                      }
                    },
                    onSubmitted: (value) {
                      final score = double.tryParse(value);
                      if (score != null && widget.onGradeUpdated != null) {
                        widget.onGradeUpdated!(tracker.id, score, null);
                      }
                    },
                  ),
                ),
                Text(
                  ' /${tracker.maxPoints.toInt()}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(TrackerStatus status) {
    switch (status) {
      case TrackerStatus.missing:
        return 'Not Submitted';
      case TrackerStatus.submitted:
        return 'Submitted';
      case TrackerStatus.late:
        return 'Late';
      case TrackerStatus.graded:
        return 'Graded';
    }
  }

  void _showFileListDialog(AssignmentTrackerModel tracker) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Submitted Files',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: tracker.attachments.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final attachment = tracker.attachments[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(attachment.name),
                      subtitle: Text(
                        '${(attachment.sizeInBytes / 1024).toStringAsFixed(1)} KB',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: 'Preview',
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showFilePreview(tracker.attachments, index);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.download),
                            tooltip: 'Download',
                            onPressed: () async {
                              await launchUrl(
                                Uri.parse(attachment.url),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilePreview(List<TrackerAttachment> attachments, int initialIndex) {
    final files = attachments.map((attachment) {
      // Debug: Print attachment URL
      print('📎 Attachment URL: ${attachment.url}');
      print('📎 File name: ${attachment.name}');
      print('📎 Extension: ${_getFileExtension(attachment.name)}');

      return UploadedFileModel(
        fileName: attachment.name,
        filePath: attachment.url, // This should be Firebase Storage URL
        fileSizeBytes: attachment.sizeInBytes,
        fileExtension: _getFileExtension(attachment.name),
        platformFile: PlatformFile(
          name: attachment.name,
          size: attachment.sizeInBytes,
          path: attachment.url, // Use URL as path for remote files
        ),
      );
    }).toList();

    FilePreviewOverlay.show(
      context,
      files,
      initialIndex: initialIndex,
    );
  }

  String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1 && lastDot < fileName.length - 1) {
      return fileName
          .substring(lastDot)
          .toLowerCase(); // Include the dot: .docx, .pdf, etc.
    }
    return '';
  }
}
