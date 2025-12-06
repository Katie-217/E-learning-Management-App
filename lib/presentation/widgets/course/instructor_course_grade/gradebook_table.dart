import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';
import 'package:elearning_management_app/data/repositories/submission/submission_repository.dart';

// Mock data models for gradebook table
class MockGradeData {
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String groupId;
  final String groupName;
  final Map<String, MockSubmissionData> submissions;

  MockGradeData({
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.groupId,
    required this.groupName,
    required this.submissions,
  });
}

class MockSubmissionData {
  final double? score;
  final double maxScore;
  final String status;
  final int attemptNumber;
  final DateTime? submittedAt;
  final List<String> files;
  final String? feedback;
  final bool isPublished;

  MockSubmissionData({
    this.score,
    required this.maxScore,
    required this.status,
    required this.attemptNumber,
    this.submittedAt,
    required this.files,
    this.feedback,
    this.isPublished = false,
  });
}

class GradebookTable extends StatefulWidget {
  final List<MockGradeData> gradeData;
  final List<Assignment> assignments;
  final ScrollController horizontalScrollController;
  final Set<String> selectedStudentIds;
  final Function(Set<String> selectedIds) onSelectionChanged;
  final Function(String studentId, String assignmentId, double? score, String? feedback)? onGradeUpdated;
  final Function(String studentId, String assignmentId)? onGradeSent;

  const GradebookTable({
    super.key,
    required this.gradeData,
    required this.assignments,
    required this.horizontalScrollController,
    required this.selectedStudentIds,
    required this.onSelectionChanged,
    this.onGradeUpdated,
    this.onGradeSent,
  });

  @override
  State<GradebookTable> createState() => _GradebookTableState();
}

class _GradebookTableState extends State<GradebookTable> {
  late ScrollController _headerScrollController;
  late List<MockGradeData> _localGradeData;
  final Set<String> _editingRows = {};
  final Map<String, TextEditingController> _inlineScoreControllers = {};

  @override
  void initState() {
    super.initState();
    _headerScrollController = ScrollController();
    widget.horizontalScrollController.addListener(_syncHeaderScroll);
    _localGradeData = List.from(widget.gradeData);
  }

  @override
  void didUpdateWidget(GradebookTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gradeData != widget.gradeData) {
      _localGradeData = List.from(widget.gradeData);
    }
    
    if (!_areAssignmentsEqual(oldWidget.assignments, widget.assignments)) {
      Future.microtask(() {
        if (!mounted) return;
        try {
          if (widget.horizontalScrollController.hasClients) {
            widget.horizontalScrollController.jumpTo(0);
          }
          Future.microtask(() {
            if (!mounted) return;
            try {
              if (_headerScrollController.hasClients) {
                _headerScrollController.jumpTo(0);
              }
            } catch (e) {
              // Ignore errors
            }
          });
        } catch (e) {
          // Ignore errors
        }
      });
    }
  }

  bool _areAssignmentsEqual(List<Assignment> list1, List<Assignment> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }


  @override
  void dispose() {
    for (final controller in _inlineScoreControllers.values) {
      controller.dispose();
    }
    widget.horizontalScrollController.removeListener(_syncHeaderScroll);
    _headerScrollController.dispose();
    super.dispose();
  }

  void _syncHeaderScroll() {
    if (!mounted) return;
    try {
      if (_headerScrollController.hasClients && 
          widget.horizontalScrollController.hasClients) {
        final bodyOffset = widget.horizontalScrollController.offset;
        if (_headerScrollController.offset != bodyOffset) {
          _headerScrollController.jumpTo(bodyOffset);
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  String _rowKey(String studentId, String assignmentId) =>
      '$studentId|$assignmentId';

  TextEditingController _getInlineScoreController(
    String key,
    double? initialScore,
  ) {
    return _inlineScoreControllers.putIfAbsent(key, () {
      return TextEditingController(
        text: initialScore != null ? initialScore.toStringAsFixed(1) : '',
      );
    });
  }

  void _updateGradeData(String studentId, String assignmentId, double? score, String? feedback) {
    setState(() {
      final studentIndex = _localGradeData.indexWhere((data) => data.studentId == studentId);
      if (studentIndex != -1) {
        final student = _localGradeData[studentIndex];
        final oldSubmission = student.submissions[assignmentId];
        if (oldSubmission != null) {
          final updatedSubmission = MockSubmissionData(
            score: score,
            maxScore: oldSubmission.maxScore,
            status: oldSubmission.status,
            attemptNumber: oldSubmission.attemptNumber,
            submittedAt: oldSubmission.submittedAt,
            files: oldSubmission.files,
            feedback: feedback,
            isPublished: oldSubmission.isPublished,
          );
          
          final updatedSubmissions = Map<String, MockSubmissionData>.from(student.submissions);
          updatedSubmissions[assignmentId] = updatedSubmission;
          
          final updatedStudent = MockGradeData(
            studentId: student.studentId,
            studentName: student.studentName,
            studentEmail: student.studentEmail,
            groupId: student.groupId,
            groupName: student.groupName,
            submissions: updatedSubmissions,
          );
          
          _localGradeData[studentIndex] = updatedStudent;
        }
      }
    });
  }

  void _markGradeAsPublished(String studentId, String assignmentId) {
    setState(() {
      final studentIndex = _localGradeData.indexWhere((data) => data.studentId == studentId);
      if (studentIndex != -1) {
        final student = _localGradeData[studentIndex];
        final oldSubmission = student.submissions[assignmentId];
        if (oldSubmission != null) {
          final updatedSubmission = MockSubmissionData(
            score: oldSubmission.score,
            maxScore: oldSubmission.maxScore,
            status: oldSubmission.status,
            attemptNumber: oldSubmission.attemptNumber,
            submittedAt: oldSubmission.submittedAt,
            files: oldSubmission.files,
            feedback: oldSubmission.feedback,
            isPublished: true,
          );
          
          final updatedSubmissions = Map<String, MockSubmissionData>.from(student.submissions);
          updatedSubmissions[assignmentId] = updatedSubmission;
          
          final updatedStudent = MockGradeData(
            studentId: student.studentId,
            studentName: student.studentName,
            studentEmail: student.studentEmail,
            groupId: student.groupId,
            groupName: student.groupName,
            submissions: updatedSubmissions,
          );
          
          _localGradeData[studentIndex] = updatedStudent;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gradeData = _localGradeData;
    final assignments = widget.assignments;
    final horizontalScrollController = widget.horizontalScrollController;

    if (gradeData.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                'No students found',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (assignments.length == 1) {
      return _buildSingleAssignmentTable(
        context,
        gradeData,
        assignments.first,
        horizontalScrollController,
      );
    }

    if (assignments.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                'No assignments in this course',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    const double headerHeight = 80.0;
    const double rowHeight = 80.0;
    const double dividerHeight = 1.0;
    final bodyHeight = gradeData.length * rowHeight;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        textDirection: TextDirection.ltr,
        children: [
          _buildFixedStudentColumn(gradeData, headerHeight, dividerHeight, bodyHeight),
          _buildFixedGroupColumn(gradeData, headerHeight, dividerHeight, bodyHeight),
          Expanded(
            child: ClipRect(
              clipBehavior: Clip.hardEdge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScrollableHeader(
                    assignments, 
                    _headerScrollController,
                  ),
                  SizedBox(
                    height: dividerHeight,
                    child: const Divider(height: 1, color: AppColors.border),
                  ),
                  SizedBox(
                    height: bodyHeight,
                    child: Scrollbar(
                      controller: horizontalScrollController,
                      thumbVisibility: true,
                      child: _buildScrollableBody(
                        context, 
                        gradeData, 
                        assignments, 
                        horizontalScrollController,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gradebook dạng hàng cho 1 assignment/quiz (giống design bạn gửi)
  Widget _buildSingleAssignmentTable(
    BuildContext context,
    List<MockGradeData> gradeData,
    Assignment assignment,
    ScrollController horizontalScrollController,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;
    final isVerySmall = screenWidth < 400;
    final baseUnitWidth = isVerySmall ? 100.0 : (isSmall ? 120.0 : 160.0);
    final allSelected = gradeData.isNotEmpty &&
        gradeData
            .every((data) => widget.selectedStudentIds.contains(data.studentId));

    return LayoutBuilder(
      builder: (context, constraints) {
        const int totalUnits = 8;

        double effectiveUnitWidth = baseUnitWidth;
        if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
          final double widthPerUnit = constraints.maxWidth / totalUnits;
          effectiveUnitWidth =
              widthPerUnit > baseUnitWidth ? widthPerUnit : baseUnitWidth;
        }

        // Trên màn hình nhỏ, giảm tỷ lệ các cột để vừa màn hình
        final double colStudent = isSmall 
            ? effectiveUnitWidth * 1.8 
            : effectiveUnitWidth * 2; // rộng hơn cho tên/email
        final double colGroup = isSmall ? effectiveUnitWidth * 0.8 : effectiveUnitWidth;
        final double colStatus = isSmall ? effectiveUnitWidth * 0.9 : effectiveUnitWidth;
        final double colSubmissionTime = isSmall ? effectiveUnitWidth * 1.1 : effectiveUnitWidth;
        final double colAttempts = isSmall ? effectiveUnitWidth * 0.7 : effectiveUnitWidth;
        final double colLatestGrade = isSmall ? effectiveUnitWidth * 0.9 : effectiveUnitWidth;
        final double colFiles = isSmall ? effectiveUnitWidth * 0.8 : effectiveUnitWidth;

        final double totalWidth = colStudent +
            colGroup +
            colStatus +
            colSubmissionTime +
            colAttempts +
            colLatestGrade +
            colFiles;

        final double minWidth = constraints.maxWidth.isFinite
            ? (constraints.maxWidth > totalWidth
                ? constraints.maxWidth
                : totalWidth)
            : totalWidth;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: horizontalScrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minWidth),
              child: Column(
                children: [
                  // Header row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildSingleAssignmentHeaderCell(
                          width: colStudent,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Checkbox(
                                value: allSelected,
                                tristate: true,
                                onChanged: (value) {
                                  final newSelection = <String>{};
                                  if (value == true) {
                                    newSelection.addAll(
                                      gradeData.map((d) => d.studentId),
                                    );
                                  }
                                  widget.onSelectionChanged(newSelection);
                                },
                              ),
                              SizedBox(width: isSmall ? 2 : 4),
                              Text(
                                'Student',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmall ? 12 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildSingleAssignmentHeaderCell(
                          width: colGroup,
                          label: 'Group',
                        ),
                        _buildSingleAssignmentHeaderCell(
                          width: colStatus,
                          label: 'Status',
                        ),
                        _buildSingleAssignmentHeaderCell(
                          width: colSubmissionTime,
                          label: 'Submission Time',
                        ),
                        _buildSingleAssignmentHeaderCell(
                          width: colAttempts,
                          label: 'Attempts',
                        ),
                        _buildSingleAssignmentHeaderCell(
                          width: colLatestGrade,
                          label: 'Latest Grade',
                        ),
                        _buildSingleAssignmentHeaderCell(
                          width: colFiles,
                          label: 'Files',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),

                  Column(
                    children: [
                      for (int index = 0;
                          index < gradeData.length;
                          index++) ...[
                        if (index > 0)
                          const Divider(height: 1, color: AppColors.border),
                        _buildSingleAssignmentRow(
                          context,
                          gradeData[index],
                          assignment,
                          colStudent,
                          colGroup,
                          colStatus,
                          colSubmissionTime,
                          colAttempts,
                          colLatestGrade,
                          colFiles,
                          isSmall: isSmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleAssignmentHeaderCell({
    required double width,
    String? label,
    Widget? child,
    bool isLast = false,
    Alignment alignment = Alignment.center,
    bool isSmall = false,
  }) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 4 : 8),
      decoration: BoxDecoration(
        border: Border(
          right: isLast
              ? BorderSide.none
              : const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      alignment: alignment,
      child: child ??
          Text(
            label ?? '',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: isSmall ? 11 : 14,
            ),
          ),
    );
  }

  Widget _buildSingleAssignmentBodyCell({
    required double width,
    required Widget child,
    bool isLast = false,
    Alignment alignment = Alignment.center,
    bool isSmall = false,
  }) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 4 : 8),
      decoration: BoxDecoration(
        border: Border(
          right: isLast
              ? BorderSide.none
              : const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      alignment: alignment,
      child: child,
    );
  }

  Widget _buildSingleAssignmentRow(
    BuildContext context,
    MockGradeData data,
    Assignment assignment,
    double colStudent,
    double colGroup,
    double colStatus,
    double colSubmissionTime,
    double colAttempts,
    double colLatestGrade,
    double colFiles, {
    bool isSmall = false,
  }) {
    final submission = data.submissions[assignment.id];
    final rowKey = _rowKey(data.studentId, assignment.id);
    final isEditingInline = _editingRows.contains(rowKey);

    final statusText = submission != null
        ? _rowStatusText(submission.status)
        : '❌ Not submitted';
    final statusColor = submission != null
        ? _getStatusColor(submission.status)
        : AppColors.textMuted;
    final submissionTime = submission?.submittedAt != null
        ? _rowFormatDateTime(submission!.submittedAt!)
        : '-';
    final attempts = submission?.attemptNumber ?? 0;
    final latestGrade = submission?.score;
    final latestGradeStr =
        latestGrade != null ? latestGrade.toStringAsFixed(1) : '-';
    final latestGradeColor = latestGrade != null
        ? _getGradeColor(latestGrade)
        : AppColors.textMuted;

    final isSelected =
        widget.selectedStudentIds.contains(data.studentId);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 16,
        vertical: isSmall ? 8 : 12,
      ),
      color:
          isSelected ? AppColors.surfaceVariant.withOpacity(0.3) : null,
      child: Row(
        children: [
          _buildSingleAssignmentBodyCell(
            width: colStudent,
            alignment: Alignment.centerLeft,
            isSmall: isSmall,
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    final newSelection =
                        Set<String>.from(widget.selectedStudentIds);
                    if (value == true) {
                      newSelection.add(data.studentId);
                    } else {
                      newSelection.remove(data.studentId);
                    }
                    widget.onSelectionChanged(newSelection);
                  },
                  materialTapTargetSize: isSmall 
                      ? MaterialTapTargetSize.shrinkWrap 
                      : MaterialTapTargetSize.padded,
                ),
                SizedBox(width: isSmall ? 4 : 8),
                Container(
                  width: isSmall ? 28 : 32,
                  height: isSmall ? 28 : 32,
                  decoration: BoxDecoration(
                    color: _getStudentColor(data.studentId),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(data.studentName),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmall ? 10 : 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isSmall ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        data.studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: isSmall ? 12 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        data.studentEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: isSmall ? 10 : 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _buildSingleAssignmentBodyCell(
            width: colGroup,
            isSmall: isSmall,
            child: Text(
              data.groupName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: isSmall ? 11 : 13,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          _buildSingleAssignmentBodyCell(
            width: colStatus,
            isSmall: isSmall,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 4 : 8,
                vertical: isSmall ? 2 : 4,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor, width: 1),
              ),
              child: Text(
                statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: statusColor,
                  fontSize: isSmall ? 10 : 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          _buildSingleAssignmentBodyCell(
            width: colSubmissionTime,
            isSmall: isSmall,
            child: Text(
              submissionTime,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: isSmall ? 10 : 12,
              ),
            ),
          ),

          _buildSingleAssignmentBodyCell(
            width: colAttempts,
            isSmall: isSmall,
            child: Text(
              attempts.toString(),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: isSmall ? 10 : 12,
              ),
            ),
          ),

          _buildSingleAssignmentBodyCell(
            width: colLatestGrade,
            isSmall: isSmall,
            child: _buildLatestGradeCell(
              context,
              data,
              assignment,
              submission,
              rowKey,
              latestGradeStr,
              latestGradeColor,
              isSmall: isSmall,
            ),
          ),

          _buildSingleAssignmentBodyCell(
            width: colFiles,
            isLast: true,
            isSmall: isSmall,
            child: submission == null || submission.files.isEmpty
                ? Text(
                    '-',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: isSmall ? 10 : 12,
                    ),
                  )
                : TextButton.icon(
                    onPressed: () {
                      _showFileListDialog(
                        context,
                        data,
                        assignment,
                        submission,
                      );
                    },
                    icon: Icon(
                      Icons.attach_file,
                      size: isSmall ? 14 : 16,
                      color: AppColors.textSecondary,
                    ),
                    label: Text(
                      '${submission.files.length} file${submission.files.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: isSmall ? 10 : 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 4 : 8,
                        vertical: isSmall ? 2 : 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedStudentColumn(
    List<MockGradeData> gradeData,
    double headerHeight,
    double dividerHeight,
    double bodyHeight,
  ) {
    const double checkboxWidth = 48.0;
    const double studentColumnWidth = 250.0;
    const double rowHeight = 80.0;

    final totalHeight = headerHeight + dividerHeight + bodyHeight;
    final allSelected = gradeData.isNotEmpty && 
        gradeData.every((data) => widget.selectedStudentIds.contains(data.studentId));
    
    return SizedBox(
      width: checkboxWidth + studentColumnWidth,
      height: totalHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed header
          Container(
            height: headerHeight,
            width: double.infinity,
            color: AppColors.surfaceVariant,
            child: Row(
              children: [
                SizedBox(
                  width: checkboxWidth,
                  child: Checkbox(
                    value: allSelected,
                    tristate: true,
                    onChanged: (value) {
                      final newSelection = <String>{};
                      if (value == true) {
                        newSelection.addAll(gradeData.map((data) => data.studentId));
                      }
                      widget.onSelectionChanged(newSelection);
                    },
                  ),
                ),
                Expanded(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Student',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: dividerHeight,
            width: double.infinity,
            child: const Divider(height: 1, color: AppColors.border),
          ),
          SizedBox(
            height: bodyHeight,
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: gradeData.map((data) {
                final isSelected = widget.selectedStudentIds.contains(data.studentId);
                return Container(
                  height: rowHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.border, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: checkboxWidth,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            final newSelection = Set<String>.from(widget.selectedStudentIds);
                            if (value == true) {
                              newSelection.add(data.studentId);
                            } else {
                              newSelection.remove(data.studentId);
                            }
                            widget.onSelectionChanged(newSelection);
                          },
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _getStudentColor(data.studentId),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(data.studentName),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data.studentName,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      data.studentEmail,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedGroupColumn(
    List<MockGradeData> gradeData,
    double headerHeight,
    double dividerHeight,
    double bodyHeight,
  ) {
    const double groupColumnWidth = 100.0;
    const double rowHeight = 80.0;

    final totalHeight = headerHeight + dividerHeight + bodyHeight;
    
    return SizedBox(
      width: groupColumnWidth,
      height: totalHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed header
          Container(
            height: headerHeight,
            width: double.infinity,
            color: AppColors.surfaceVariant,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Group',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: dividerHeight,
            width: double.infinity,
            child: const Divider(height: 1, color: AppColors.border),
          ),
          SizedBox(
            height: bodyHeight,
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: gradeData.map((data) {
                return Container(
                  height: rowHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.border, width: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        data.groupName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableHeader(List<Assignment> assignments, ScrollController horizontalScrollController) {
    const double assignmentColumnWidth = 140.0;
    const double rowHeight = 80.0;

    final totalWidth = assignments.length * assignmentColumnWidth;

    return Container(
      height: rowHeight,
      color: AppColors.surfaceVariant,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: horizontalScrollController,
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          width: totalWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                ...assignments.map((assignment) {
                  return SizedBox(
                    width: assignmentColumnWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            assignment.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Max: 100',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    }

  Widget _buildScrollableBody(
    BuildContext context,
    List<MockGradeData> gradeData,
    List<Assignment> assignments,
    ScrollController horizontalScrollController,
  ) {
    const double assignmentColumnWidth = 140.0;
    const double rowHeight = 80.0;

    final totalWidth = assignments.length * assignmentColumnWidth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: horizontalScrollController,
      child: SizedBox(
        width: totalWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: gradeData.map((data) {
              return Container(
                height: rowHeight,
                width: totalWidth,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...assignments.map((assignment) {
                      final submission = data.submissions[assignment.id];
                      return _buildGradeCell(
                        context,
                        data,
                        assignment,
                        submission,
                        assignmentColumnWidth,
                        rowHeight,
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

  Widget _buildGradeCell(
    BuildContext context,
    MockGradeData data,
    Assignment assignment,
    MockSubmissionData? submission,
    double width,
    double height,
  ) {
    if (submission == null) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Text(
            '—',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ),
      );
    }

    final statusIcon = _getStatusIcon(submission.status);
    final statusColor = _getStatusColor(submission.status);

    return GestureDetector(
      onTap: () => _showSubmissionDetail(context, data, assignment, submission),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status icon and score
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(statusIcon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  submission.score != null
                      ? '${submission.score!.toStringAsFixed(1)}/100'
                      : '—',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Attempt and time
            if (submission.attemptNumber > 0) ...[
              Text(
                'Attempt ${submission.attemptNumber}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              if (submission.submittedAt != null)
                Text(
                  _formatDate(submission.submittedAt!),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
            ] else
              const Text(
                'Not submitted',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'submitted':
        return '✅';
      case 'late':
        return '⚠️';
      case 'not_submitted':
        return '❌';
      default:
        return '—';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'not_submitted':
        return Colors.red;
      default:
        return AppColors.textMuted;
    }
  }

  // Màu điểm cho view dạng hàng (0-100)
  Color _getGradeColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 65) return Colors.orange;
    return Colors.red;
  }

  // Helpers riêng cho view dạng hàng
  String _rowStatusText(String status) {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'late':
        return 'Late';
      case 'not_submitted':
        return 'Not submitted';
      default:
        return status;
    }
  }

  String _rowFormatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Ô Latest Grade: hiển thị điểm + icon edit, click cho phép sửa, mất focus thì lưu nếu hợp lệ
  Widget _buildLatestGradeCell(
    BuildContext context,
    MockGradeData data,
    Assignment assignment,
    MockSubmissionData? submission,
    String rowKey,
    String latestGradeStr,
    Color latestGradeColor, {
    bool isSmall = false,
  }) {
    if (submission == null) {
      return Text(
        '-',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: isSmall ? 10 : 12,
        ),
      );
    }

    final isEditing = _editingRows.contains(rowKey);

    if (!isEditing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            latestGradeStr,
            style: TextStyle(
              color: latestGradeColor,
              fontSize: isSmall ? 11 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: isSmall ? 2 : 4),
          IconButton(
            tooltip: 'Edit grade',
            icon: Icon(
              Icons.edit,
              size: isSmall ? 14 : 16,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _editingRows.add(rowKey);
                _getInlineScoreController(rowKey, submission.score);
              });
            },
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: isSmall ? 24 : 32,
              minHeight: isSmall ? 24 : 32,
            ),
          ),
        ],
      );
    }

    final controller =
        _getInlineScoreController(rowKey, submission.score);

    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus && mounted) {
          _commitInlineGradeEdit(
            context,
            data,
            assignment,
            submission,
            rowKey,
          );
        }
      },
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmall ? 6 : 8,
            vertical: isSmall ? 4 : 6,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          suffixText: '/ ${submission.maxScore.toStringAsFixed(0)}',
        ),
        style: TextStyle(
          fontSize: isSmall ? 11 : 12,
          color: AppColors.textPrimary,
        ),
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        autofocus: true,
      ),
    );
  }

  void _commitInlineGradeEdit(
    BuildContext context,
    MockGradeData data,
    Assignment assignment,
    MockSubmissionData submission,
    String rowKey,
  ) {
    final controller = _inlineScoreControllers[rowKey];
    if (controller == null) {
      setState(() {
        _editingRows.remove(rowKey);
      });
      return;
    }

    final originalScore = submission.score;
    final text = controller.text.trim();

    if (text.isEmpty) {
      // Không nhập gì -> giữ nguyên
      controller.text =
          originalScore != null ? originalScore.toStringAsFixed(1) : '';
      setState(() {
        _editingRows.remove(rowKey);
      });
      return;
    }

    final newScore = double.tryParse(text);
    if (newScore == null ||
        newScore < 0 ||
        newScore > submission.maxScore) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Score must be between 0 and ${submission.maxScore}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      // Revert về điểm cũ
      controller.text =
          originalScore != null ? originalScore.toStringAsFixed(1) : '';
      setState(() {
        _editingRows.remove(rowKey);
      });
      return;
    }

    if (originalScore != null &&
        (newScore - originalScore).abs() < 0.001) {
      // Không thay đổi giá trị
      setState(() {
        _editingRows.remove(rowKey);
      });
      return;
    }

    // Cập nhật local state + callback ra ngoài
    _updateGradeData(data.studentId, assignment.id, newScore, submission.feedback);
    widget.onGradeUpdated?.call(
      data.studentId,
      assignment.id,
      newScore,
      submission.feedback,
    );

    setState(() {
      _editingRows.remove(rowKey);
    });
  }

  /// Dialog danh sách file: xem nhanh + preview / mở ngoài
  void _showFileListDialog(
    BuildContext context,
    MockGradeData data,
    Assignment assignment,
    MockSubmissionData submission,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 480,
              maxHeight: 420,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Files submitted',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.studentName} • ${assignment.title}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (submission.files.isEmpty)
                    const Text(
                      'No files submitted.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: submission.files.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: AppColors.border),
                        itemBuilder: (context, index) {
                          final fileName = submission.files[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.insert_drive_file,
                              color: AppColors.textSecondary,
                            ),
                            title: Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: const Text(
                              'Click Preview to view or Open to download',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'Preview',
                                  icon: const Icon(
                                    Icons.visibility,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _openFileFromTable(
                                      context,
                                      data.studentId,
                                      assignment.id,
                                      fileName,
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Download',
                                  icon: const Icon(
                                    Icons.download,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _openFileFromTable(
                                      context,
                                      data.studentId,
                                      assignment.id,
                                      fileName,
                                      openExternallyOnly: true,
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Mở danh sách file từ ô Files trong bảng (không mở dialog grade)
  Future<void> _openFileFromTable(
    BuildContext context,
    String studentId,
    String assignmentId,
    String fileName, {
    bool openExternallyOnly = false,
  }) async {
    try {
      final allSubmissions =
          await SubmissionRepository.getSubmissionsForAssignment(
        assignmentId,
      );

      final submissions = allSubmissions
          .where((s) => s.studentId == studentId)
          .toList();

      if (submissions.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Submission not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final submission = submissions.reduce(
        (a, b) => (a.attemptNumber > b.attemptNumber) ? a : b,
      );

      final attachment = submission.attachments.firstWhere(
        (att) => att.name == fileName,
        orElse: () => submission.attachments.first,
      );

      if (attachment.url.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File URL not available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final uri = Uri.parse(attachment.url);

      if (openExternallyOnly) {
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot open file URL'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening file: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        return;
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => _FilePreviewDialog(
            fileName: fileName,
            fileUrl: attachment.url,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStudentColor(String userId) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[userId.hashCode % colors.length];
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  void _showSubmissionDetail(
    BuildContext context,
    MockGradeData data,
    Assignment assignment,
    MockSubmissionData submission,
  ) {
    showDialog(
      context: context,
      builder: (context) => _SubmissionDetailDialog(
        studentId: data.studentId,
        studentName: data.studentName,
        assignmentId: assignment.id,
        assignmentTitle: assignment.title,
        submission: submission,
        onGradeUpdated: (studentId, assignmentId, score, feedback) {
          // Cập nhật local gradeData
          _updateGradeData(studentId, assignmentId, score, feedback);
          // Gọi callback để parent widget biết đã cập nhật
          widget.onGradeUpdated?.call(studentId, assignmentId, score, feedback);
        },
        onGradeSent: (studentId, assignmentId) {
          // Cập nhật trạng thái published
          _markGradeAsPublished(studentId, assignmentId);
          // Gọi callback để parent widget biết đã gửi điểm
          widget.onGradeSent?.call(studentId, assignmentId);
        },
      ),
    );
  }
}

class _SubmissionDetailDialog extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String assignmentId;
  final String assignmentTitle;
  final MockSubmissionData submission;
  final Function(String studentId, String assignmentId, double? score, String? feedback)? onGradeUpdated;
  final Function(String studentId, String assignmentId)? onGradeSent;

  const _SubmissionDetailDialog({
    required this.studentId,
    required this.studentName,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.submission,
    this.onGradeUpdated,
    this.onGradeSent,
  });

  @override
  State<_SubmissionDetailDialog> createState() => _SubmissionDetailDialogState();
}

class _SubmissionDetailDialogState extends State<_SubmissionDetailDialog> {
  bool _isEditing = false;
  late MockSubmissionData _currentSubmission;
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _currentSubmission = widget.submission; // Khởi tạo với submission ban đầu
    _scoreController.text = widget.submission.score?.toStringAsFixed(1) ?? '';
    _feedbackController.text = widget.submission.feedback ?? '';
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _saveGrade() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final score = double.tryParse(_scoreController.text.trim());
    if (score == null || score < 0 || score > widget.submission.maxScore) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Score must be between 0 and ${widget.submission.maxScore}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Cập nhật UI ngay lập tức
    setState(() {
      _currentSubmission = MockSubmissionData(
        score: score,
        maxScore: widget.submission.maxScore,
        status: widget.submission.status,
        attemptNumber: widget.submission.attemptNumber,
        submittedAt: widget.submission.submittedAt,
        files: widget.submission.files,
        feedback: _feedbackController.text.trim().isEmpty 
            ? null 
            : _feedbackController.text.trim(),
        isPublished: _currentSubmission.isPublished, // Giữ nguyên trạng thái published
      );
      _isEditing = false;
    });

    // TODO: Lưu vào database sau (tạm thời chỉ cập nhật UI)
    // Sau này sẽ thêm logic lưu vào database ở đây
    
    // Gọi callback với thông tin đã cập nhật
    widget.onGradeUpdated?.call(
      widget.studentId,
      widget.assignmentId,
      score,
      _feedbackController.text.trim().isEmpty ? null : _feedbackController.text.trim(),
    );
  }

  Future<void> _sendGradeToStudent() async {
    if (_currentSubmission.score == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please grade the submission first'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Grade to Student'),
        content: Text(
          'Are you sure you want to send the grade (${_currentSubmission.score!.toStringAsFixed(1)}/${_currentSubmission.maxScore}) '
          'and feedback to ${widget.studentName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // TODO: Gọi API để gửi điểm về cho học sinh
      // Ví dụ: await SubmissionRepository.publishGrade(widget.studentId, widget.assignmentId);
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Cập nhật UI
      setState(() {
        _currentSubmission = MockSubmissionData(
          score: _currentSubmission.score,
          maxScore: _currentSubmission.maxScore,
          status: _currentSubmission.status,
          attemptNumber: _currentSubmission.attemptNumber,
          submittedAt: _currentSubmission.submittedAt,
          files: _currentSubmission.files,
          feedback: _currentSubmission.feedback,
          isPublished: true,
        );
      });

      // Gọi callback để parent widget biết đã gửi điểm
      widget.onGradeSent?.call(widget.studentId, widget.assignmentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Grade sent to ${widget.studentName} successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending grade: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.assignmentTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.studentName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Status
            _buildDetailRow('Status', _getStatusText(_currentSubmission.status)),
            // Published status
            if (_currentSubmission.score != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    _currentSubmission.isPublished ? Icons.check_circle : Icons.pending,
                    size: 16,
                    color: _currentSubmission.isPublished ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentSubmission.isPublished 
                        ? 'Grade published to student' 
                        : 'Grade not yet published',
                    style: TextStyle(
                      color: _currentSubmission.isPublished ? Colors.green : Colors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // Score
            if (!_isEditing) ...[
              _buildDetailRow('Score', _currentSubmission.score != null 
                  ? '${_currentSubmission.score!.toStringAsFixed(1)}/${_currentSubmission.maxScore.toStringAsFixed(0)}'
                  : 'Not graded'),
            ] else ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _scoreController,
                      decoration: InputDecoration(
                        labelText: 'Score',
                        hintText: 'Enter score (0-${_currentSubmission.maxScore})',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixText: '/ ${_currentSubmission.maxScore}',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a score';
                        }
                        final score = double.tryParse(value);
                        if (score == null) {
                          return 'Please enter a valid number';
                        }
                        if (score < 0 || score > _currentSubmission.maxScore) {
                          return 'Score must be between 0 and ${_currentSubmission.maxScore}';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Feedback
            if (!_isEditing && _currentSubmission.feedback != null) ...[
              const Text(
                'Feedback:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentSubmission.feedback!,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ] else if (_isEditing) ...[
              TextFormField(
                controller: _feedbackController,
                decoration: InputDecoration(
                  labelText: 'Feedback',
                  hintText: 'Enter feedback for student',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 4,
                maxLength: 500,
              ),
            ],
            const SizedBox(height: 16),
            // Other details
            if (_currentSubmission.attemptNumber > 0)
              _buildDetailRow('Attempt', 'Attempt ${_currentSubmission.attemptNumber}'),
            if (_currentSubmission.submittedAt != null)
              _buildDetailRow('Submitted At', _formatDateTime(_currentSubmission.submittedAt!)),
            if (_currentSubmission.files.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Files Submitted:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ..._currentSubmission.files.map((file) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 18),
                      onPressed: () => _showFilePreview(context, file),
                      color: AppColors.primary,
                      tooltip: 'Preview file',
                    ),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                  if (_isEditing) ...[
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _scoreController.text = _currentSubmission.score?.toStringAsFixed(1) ?? '';
                        _feedbackController.text = _currentSubmission.feedback ?? '';
                      });
                    },
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveGrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Grade'),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  // Button Edit Grade
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _isEditing = true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Edit Grade'),
                  ),
                  // Button Send Grade to Student (chỉ hiển thị khi đã có điểm và chưa publish)
                  if (_currentSubmission.score != null && !_currentSubmission.isPublished) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _sendGradeToStudent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Send Grade to Student'),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'submitted':
        return '✅ Submitted on time';
      case 'late':
        return '⚠️ Submitted late';
      case 'not_submitted':
        return '❌ Not submitted';
      default:
        return status;
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showFilePreview(BuildContext context, String fileName) async {
    try {
      // Get submission from database to get file URL
      final allSubmissions = await SubmissionRepository.getSubmissionsForAssignment(
        widget.assignmentId,
      );
      
      final submissions = allSubmissions.where((s) => s.studentId == widget.studentId).toList();
      
      if (submissions.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Submission not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final submission = submissions.reduce((a, b) => 
        (a.attemptNumber > b.attemptNumber) ? a : b
      );

      // Find attachment by file name
      final attachment = submission.attachments.firstWhere(
        (att) => att.name == fileName,
        orElse: () => submission.attachments.first,
      );

      if (attachment.url.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File URL not available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show preview dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => _FilePreviewDialog(
            fileName: fileName,
            fileUrl: attachment.url,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _FilePreviewDialog extends StatefulWidget {
  final String fileName;
  final String fileUrl;

  const _FilePreviewDialog({
    required this.fileName,
    required this.fileUrl,
  });

  @override
  State<_FilePreviewDialog> createState() => _FilePreviewDialogState();
}

class _FilePreviewDialogState extends State<_FilePreviewDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.fileName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.insert_drive_file,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'In-app preview is not available.\nYou can open the file in your browser or default app.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final uri = Uri.parse(widget.fileUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error opening file: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    try {
                      final uri = Uri.parse(widget.fileUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error opening file: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: const Text('Open in Browser'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

