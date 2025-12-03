import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = error.description;
            });
          },
        ),
      );

    // Xác định loại file và load tương ứng
    final fileExtension = widget.fileName.split('.').last.toLowerCase();
    final url = widget.fileUrl;

    if (_isImageFile(fileExtension)) {
      // Hiển thị hình ảnh trực tiếp
      _controller.loadRequest(Uri.parse(url));
    } else if (_isPdfFile(fileExtension)) {
      // Sử dụng Google Docs Viewer hoặc PDF.js để preview PDF
      final pdfViewerUrl = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}&embedded=true';
      _controller.loadRequest(Uri.parse(pdfViewerUrl));
    } else if (_isOfficeFile(fileExtension)) {
      // Sử dụng Office Online Viewer
      final officeViewerUrl = 'https://view.officeapps.live.com/op/embed.aspx?src=${Uri.encodeComponent(url)}';
      _controller.loadRequest(Uri.parse(officeViewerUrl));
    } else {
      // Thử load trực tiếp, nếu không được thì mở trong browser
      _controller.loadRequest(Uri.parse(url));
    }
  }

  bool _isImageFile(String extension) {
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'].contains(extension);
  }

  bool _isPdfFile(String extension) {
    return extension == 'pdf';
  }

  bool _isOfficeFile(String extension) {
    return ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'].contains(extension);
  }

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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      WebViewWidget(controller: _controller),
                      if (_isLoading)
                        Container(
                          color: AppColors.surfaceVariant,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Loading file...',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_errorMessage != null)
                        Container(
                          color: AppColors.surfaceVariant,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading file',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      final uri = Uri.parse(widget.fileUrl);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
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
                                  icon: const Icon(Icons.open_in_browser),
                                  label: const Text('Open in Browser'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
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

