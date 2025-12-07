// ========================================
// FILE: quiz_gradebook_table.dart
// PURPOSE: Quiz Gradebook Table for Instructor Grade Tab
// DESCRIPTION: Display quiz trackers in responsive table
// ========================================

import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/quiz_model.dart';
import 'package:elearning_management_app/domain/models/quiz_tracker_model.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class QuizGradebookTable extends StatefulWidget {
  final List<QuizTrackerModel> trackers;
  final Quiz quiz;
  final Set<String> selectedStudentIds;
  final Function(String) onStudentSelected;
  final Function(String, double?, String?) onGradeUpdate;
  final ScrollController horizontalScrollController;

  const QuizGradebookTable({
    super.key,
    required this.trackers,
    required this.quiz,
    required this.selectedStudentIds,
    required this.onStudentSelected,
    required this.onGradeUpdate,
    required this.horizontalScrollController,
  });

  @override
  State<QuizGradebookTable> createState() => _QuizGradebookTableState();
}

class _QuizGradebookTableState extends State<QuizGradebookTable> {
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('MMM dd, HH:mm').format(dateTime.toLocal());
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'not_started':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to get available width, matching GradebookTableV2 pattern
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        print(
            '📱 QuizGradebookTable width: ${constraints.maxWidth}, isMobile: $isMobile');

        if (isMobile) {
          return _buildMobileView();
        } else {
          return _buildDesktopTable();
        }
      },
    );
  }

  // Mobile: Cards layout
  Widget _buildMobileView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.trackers.length,
      itemBuilder: (context, index) {
        return _buildMobileCard(widget.trackers[index]);
      },
    );
  }

  Widget _buildMobileCard(QuizTrackerModel tracker) {
    final isSelected = widget.selectedStudentIds.contains(tracker.studentId);
    final maxAttempts = widget.quiz.maxAttempts ?? 1;
    final totalPoints = widget.quiz.points ?? 100;

    return Card(
      color:
          isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => widget.onStudentSelected(tracker.studentId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name + Status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tracker.studentName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tracker.studentEmail,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(tracker.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(tracker.status),
                      ),
                    ),
                    child: Text(
                      tracker.statusDisplay,
                      style: TextStyle(
                        color: _getStatusColor(tracker.status),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),

              // Details
              _buildInfoRow('Group', tracker.groupName, Icons.group),
              _buildInfoRow(
                'Attempts',
                '${tracker.attemptCount} / $maxAttempts',
                Icons.repeat,
              ),
              _buildInfoRow(
                'Last Attempt',
                _formatDateTime(tracker.lastAttemptAt),
                Icons.access_time,
              ),
              _buildInfoRow(
                'Score',
                tracker.score != null
                    ? '${tracker.score!.toStringAsFixed(1)} / $totalPoints'
                    : '-',
                Icons.grade,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tablet: Horizontal scrollable table
  Widget _buildTabletView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: widget.horizontalScrollController,
      child: Container(
        width: 1200, // Fixed width for tablet horizontal scroll
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            _buildTableHeader(),
            const Divider(height: 1, color: AppColors.border),
            ...widget.trackers.map((tracker) => _buildTableRow(tracker)),
          ],
        ),
      ),
    );
  }

  // Desktop: Table layout
  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(height: 1, color: AppColors.border),
          ...widget.trackers.map((tracker) => _buildTableRow(tracker)),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('Name', flex: 3),
          _buildHeaderCell('Email', flex: 3),
          _buildHeaderCell('Group', flex: 2),
          _buildHeaderCell('Status', flex: 2),
          _buildHeaderCell('Attempts', flex: 2),
          _buildHeaderCell('Last Attempt', flex: 2),
          _buildHeaderCell('Score', flex: 2),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTableRow(QuizTrackerModel tracker) {
    final isSelected = widget.selectedStudentIds.contains(tracker.studentId);
    final maxAttempts = widget.quiz.maxAttempts ?? 1;
    final totalPoints = widget.quiz.points ?? 100;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: InkWell(
        onTap: () => widget.onStudentSelected(tracker.studentId),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildCell(tracker.studentName, flex: 3),
              _buildCell(tracker.studentEmail, flex: 3),
              _buildCell(tracker.groupName, flex: 2),
              _buildStatusCell(tracker.status, flex: 2),
              _buildCell(
                '${tracker.attemptCount} / $maxAttempts',
                flex: 2,
              ),
              _buildCell(_formatDateTime(tracker.lastAttemptAt), flex: 2),
              _buildScoreCell(tracker, totalPoints, flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusCell(String status, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getStatusColor(status)),
          ),
          child: Text(
            status == 'not_started'
                ? 'Not Started'
                : status == 'in_progress'
                    ? 'In Progress'
                    : 'Completed',
            style: TextStyle(
              color: _getStatusColor(status),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCell(QuizTrackerModel tracker, double totalPoints,
      {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: tracker.score != null
          ? Text(
              '${tracker.score!.toStringAsFixed(1)} / $totalPoints',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            )
          : const Text(
              '-',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
    );
  }
}
