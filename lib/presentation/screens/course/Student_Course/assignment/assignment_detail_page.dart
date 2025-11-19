// ========================================
// FILE: assignment_detail_page.dart - REFACTORED
// MÔ TẢ: UI Component cho Assignment Detail với proper architecture
// ARCHITECTURE: Presentation Layer - chỉ UI logic, không có business logic
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../domain/models/assignment_model.dart';
import '../../../../../domain/models/course_model.dart';
import '../../../../../domain/models/submission_model.dart';
import '../../../../../application/controllers/submission/submission_controller.dart';
import '../../../../../application/controllers/assignment/assignment_controller.dart';
import '../../../../../core/theme/app_colors.dart';

// ========================================
// ASSIGNMENT DETAIL VIEW WIDGET
// ========================================

class AssignmentDetailView extends ConsumerStatefulWidget {
  final Assignment assignment;
  final CourseModel course;
  final VoidCallback onBack;

  const AssignmentDetailView({
    super.key,
    required this.assignment,
    required this.course,
    required this.onBack,
  });

  @override
  ConsumerState<AssignmentDetailView> createState() =>
      _AssignmentDetailViewState();
}

class _AssignmentDetailViewState extends ConsumerState<AssignmentDetailView> {
  // ========================================
  // UI STATE (Only UI-related state, no business logic)
  // ========================================
  List<PlatformFile> _selectedFiles = [];
  bool _isDragging = false;
  String? _submittedLink;

  @override
  void initState() {
    super.initState();
    _setupDragAndDrop();
    _loadSubmissionData();
  }

  // ========================================
  // INITIALIZATION METHODS
  // ========================================

  void _loadSubmissionData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Use controller to load submission data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(submissionControllerProvider.notifier)
            .loadSubmissionForAssignment(widget.assignment.id, user.uid);
      });
    }
  }

  void _setupDragAndDrop() {
    // Drag and drop only supported on web platform
    if (!kIsWeb) return;
    print('Drag and drop setup skipped on non-web platform');
  }

  // ========================================
  // UI EVENT HANDLERS (Delegate to Controllers)
  // ========================================

  Future<void> _handleFilePick() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
        _showSuccessMessage('Selected ${result.files.length} file(s)');
      }
    } catch (e) {
      _showErrorMessage('Error picking files: $e');
    }
  }

  Future<void> _handleImagePick() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
        _showSuccessMessage('Selected ${result.files.length} image(s)');
      }
    } catch (e) {
      _showErrorMessage('Error picking images: $e');
    }
  }

  void _handleLinkAdd() {
    final TextEditingController linkController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Add Link',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: linkController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter URL',
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final link = linkController.text.trim();
              if (link.isNotEmpty) {
                setState(() {
                  _submittedLink = link;
                });
                Navigator.pop(context);
                _showSuccessMessage('Link added');
              }
            },
            child:
                const Text('Add', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // ========================================
  // SUBMISSION HANDLERS (Use Controllers)
  // ========================================

  Future<void> _handleSubmit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorMessage('Please login to submit');
      return;
    }

    final currentSubmission = ref.read(currentSubmissionProvider);
    final submissionController =
        ref.read(submissionControllerProvider.notifier);

    // Prepare attachments from selected files
    final attachments = <AttachmentModel>[];
    if (_submittedLink != null && _submittedLink != 'Drive file') {
      attachments.add(AttachmentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Link submission',
        url: _submittedLink!,
        mimeType: 'text/plain',
        sizeInBytes: 0,
        uploadedAt: DateTime.now(),
      ));
    }

    bool success;
    if (currentSubmission != null) {
      // Update existing submission
      success = await submissionController.updateSubmission(
        assignmentId: widget.assignment.id,
        studentId: user.uid,
        attachments: attachments,
        linkContent: _submittedLink,
      );
    } else {
      // Create new submission
      success = await submissionController.createSubmission(
        assignment: widget.assignment,
        course: widget.course,
        studentId: user.uid,
        studentName: user.displayName ?? user.email ?? 'Unknown',
        attachments: attachments,
        linkContent: _submittedLink,
      );
    }

    if (success) {
      _showSuccessMessage('Submitted successfully');
      // Clear UI state
      setState(() {
        _selectedFiles.clear();
        _submittedLink = null;
      });
    } else {
      final error = ref.read(submissionsErrorProvider);
      _showErrorMessage(error ?? 'Failed to submit. Please try again.');
    }
  }

  Future<void> _handleUnsubmit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final submissionController =
        ref.read(submissionControllerProvider.notifier);
    final success = await submissionController.unsubmitAssignment(
      widget.assignment.id,
      user.uid,
    );

    if (success) {
      _showSuccessMessage('Unsubmitted');
      setState(() {
        _selectedFiles.clear();
        _submittedLink = null;
      });
    } else {
      final error = ref.read(submissionsErrorProvider);
      _showErrorMessage(error ?? 'Failed to unsubmit');
    }
  }

  // ========================================
  // UI HELPER METHODS
  // ========================================

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  // Get work status based on deadline and submission (moved from business logic)
  String _getWorkStatus(SubmissionModel? submission) {
    // If submitted, always show "Turned in"
    if (submission != null &&
        (submission.status == SubmissionStatus.submitted ||
            submission.status == SubmissionStatus.graded ||
            submission.status == SubmissionStatus.returned)) {
      return 'turned_in';
    }

    final now = DateTime.now();

    // Check if deadline has passed
    if (now.isAfter(widget.assignment.deadline)) {
      return 'missing';
    }

    // Check if due soon (within 24 hours)
    final hoursUntilDeadline =
        widget.assignment.deadline.difference(now).inHours;
    if (hoursUntilDeadline <= 24 && hoursUntilDeadline > 0) {
      return 'due_soon';
    }

    // Check if assignment has started
    if (now.isBefore(widget.assignment.startDate)) {
      return 'assigned';
    }

    return 'assigned';
  }

  // Get status display text and color
  Map<String, dynamic> _getWorkStatusDisplay(String status) {
    switch (status) {
      case 'missing':
        return {
          'text': 'Missing',
          'color': AppColors.error,
          'bgColor': AppColors.error.withOpacity(0.15),
          'borderColor': AppColors.error.withOpacity(0.3),
        };
      case 'due_soon':
        return {
          'text': 'Due soon',
          'color': AppColors.warning,
          'bgColor': AppColors.warning.withOpacity(0.15),
          'borderColor': AppColors.warning.withOpacity(0.3),
        };
      case 'assigned':
        return {
          'text': 'Assigned',
          'color': AppColors.textSecondary,
          'bgColor': AppColors.surfaceVariant,
          'borderColor': AppColors.border,
        };
      case 'turned_in':
        return {
          'text': 'Turned in',
          'color': AppColors.success,
          'bgColor': AppColors.success.withOpacity(0.15),
          'borderColor': AppColors.success.withOpacity(0.3),
        };
      default:
        return {
          'text': 'Assigned',
          'color': AppColors.textSecondary,
          'bgColor': AppColors.surfaceVariant,
          'borderColor': AppColors.border,
        };
    }
  }

  // ========================================
  // BUILD METHOD (Pure UI)
  // ========================================

  @override
  Widget build(BuildContext context) {
    // Watch providers for reactive updates
    final isLoading = ref.watch(submissionsLoadingProvider);
    final isSubmitting = ref.watch(submissionSubmittingProvider);
    final currentSubmission = ref.watch(currentSubmissionProvider);
    final error = ref.watch(submissionsErrorProvider);

    // Show error if exists
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorMessage(error);
        ref.read(submissionControllerProvider.notifier).clearError();
      });
    }

    final isSubmitted = currentSubmission != null &&
        (currentSubmission.status == SubmissionStatus.submitted ||
            currentSubmission.status == SubmissionStatus.graded ||
            currentSubmission.status == SubmissionStatus.returned);

    final status = _getWorkStatus(currentSubmission);
    final statusDisplay = _getWorkStatusDisplay(status);

    return Container(
      color: AppColors.bgDark,
      child: Column(
        children: [
          // Back button header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.textPrimary),
                  onPressed: widget.onBack,
                  tooltip: 'Back to assignments',
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // For wide screens, use horizontal layout
                if (constraints.maxWidth > 1200) {
                  return SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Content Area (Left)
                        Expanded(
                          flex: 3,
                          child: _buildMainContent(currentSubmission),
                        ),
                        // Sidebar (Right)
                        SizedBox(
                          width: 360,
                          child: _buildSidebarContent(
                            isLoading,
                            isSubmitting,
                            currentSubmission,
                            isSubmitted,
                            statusDisplay,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                // For narrow screens, use vertical layout
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainContent(currentSubmission),
                      _buildSidebarContent(
                        isLoading,
                        isSubmitting,
                        currentSubmission,
                        isSubmitted,
                        statusDisplay,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // UI COMPONENT BUILDERS
  // ========================================

  Widget _buildMainContent(SubmissionModel? currentSubmission) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.assignment.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          widget.course.instructor,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('•',
                            style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(widget.assignment.startDate),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Points badge - only show when graded
              if (currentSubmission != null && currentSubmission.isGraded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentSubmission.maxScore != null
                        ? '${currentSubmission.score!.toStringAsFixed(0)}/${currentSubmission.maxScore!.toStringAsFixed(0)} points'
                        : '${currentSubmission.score!.toStringAsFixed(0)} points',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          Divider(height: 32, color: AppColors.border),

          // Instructions Section
          if (widget.assignment.description.isNotEmpty) ...[
            Text(
              widget.assignment.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Attachments Section
          if (widget.assignment.attachments.isNotEmpty) ...[
            const Text(
              'Attachments',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.assignment.attachments.asMap().entries.map((entry) {
              final index = entry.key;
              final attachment = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                  color: AppColors.surfaceVariant,
                ),
                child: Row(
                  children: [
                    // Thumbnail placeholder
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.image,
                        color: AppColors.textMuted,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attachment['fileName'] ?? 'IMAGE ${index + 1}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Image',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new,
                          size: 20, color: AppColors.textPrimary),
                      onPressed: () {
                        // TODO: Open attachment
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Class Comments Section
          Divider(height: 32, color: AppColors.border),
          Row(
            children: [
              const Text(
                'Class comments',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Add comment
                },
                child: const Text(
                  'Add comment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'No comments yet',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(
    bool isLoading,
    bool isSubmitting,
    SubmissionModel? currentSubmission,
    bool isSubmitted,
    Map<String, dynamic> statusDisplay,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Your Work Section
            DragTarget<List<PlatformFile>>(
              onWillAccept: (data) {
                setState(() {
                  _isDragging = true;
                });
                return true;
              },
              onLeave: (data) {
                setState(() {
                  _isDragging = false;
                });
              },
              onAccept: (data) {
                setState(() {
                  _isDragging = false;
                  _selectedFiles.addAll(data);
                });
                _showSuccessMessage('Added ${data.length} file(s)');
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isDragging
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isDragging ? AppColors.primary : AppColors.border,
                      width: _isDragging ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isDragging)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.cloud_upload,
                                  color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'Drop files here',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Header with status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your work',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusDisplay['bgColor'] as Color,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: statusDisplay['borderColor'] as Color,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              statusDisplay['text'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusDisplay['color'] as Color,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: AppColors.border),
                      const SizedBox(height: 16),

                      // Loading indicator
                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      // Show submitted content if submitted
                      else if (isSubmitted && currentSubmission != null) ...[
                        _buildSubmittedContent(currentSubmission),
                        const SizedBox(height: 12),
                      ],

                      // Add or Create Button with Dropdown (only show if not submitted)
                      if (!isSubmitted &&
                          !isLoading &&
                          _selectedFiles.isEmpty &&
                          _submittedLink == null)
                        _buildAddCreateButton(),

                      // Selected Files Display (only show if not submitted)
                      if (!isSubmitted && _selectedFiles.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ..._selectedFiles.map((file) => _buildFileItem(file)),
                      ],

                      const SizedBox(height: 12),

                      // Submit/Unsubmit Button
                      _buildSubmitButton(isSubmitted, isSubmitting),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildPrivateCommentsSection(),
            const SizedBox(height: 16),
            _buildDetailsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittedContent(SubmissionModel submission) {
    if (submission.attachments.isNotEmpty) {
      return Column(
        children: submission.attachments
            .map((attachment) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        attachment.url.contains('drive') ||
                                attachment.url.contains('google')
                            ? Icons.drive_file_move
                            : Icons.link,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attachment.name,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              attachment.sizeInBytes > 0
                                  ? '${(attachment.sizeInBytes / 1024).toStringAsFixed(1)} KB'
                                  : 'Link',
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
                ))
            .toList(),
      );
    } else if (submission.textContent != null &&
        submission.textContent!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    submission.textContent!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted ${_formatDate(submission.submittedAt)}',
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
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAddCreateButton() {
    return Center(
      child: PopupMenuButton<String>(
        offset: const Offset(0, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.border),
        ),
        color: AppColors.surface,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Add or create', style: TextStyle(color: AppColors.primary)),
              SizedBox(width: 8),
              Icon(Icons.arrow_drop_down, color: AppColors.primary),
            ],
          ),
        ),
        itemBuilder: (BuildContext context) => [
          const PopupMenuItem<String>(
            value: 'file',
            child: Row(
              children: [
                Icon(Icons.insert_drive_file,
                    size: 20, color: AppColors.textPrimary),
                SizedBox(width: 12),
                Text('File', style: TextStyle(color: AppColors.textPrimary)),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'link',
            child: Row(
              children: [
                Icon(Icons.link, size: 20, color: AppColors.textPrimary),
                SizedBox(width: 12),
                Text('Link', style: TextStyle(color: AppColors.textPrimary)),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'image',
            child: Row(
              children: [
                Icon(Icons.image, size: 20, color: AppColors.textPrimary),
                SizedBox(width: 12),
                Text('Hình', style: TextStyle(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
        onSelected: (String value) {
          switch (value) {
            case 'file':
              _handleFilePick();
              break;
            case 'link':
              _handleLinkAdd();
              break;
            case 'image':
              _handleImagePick();
              break;
          }
        },
      ),
    );
  }

  Widget _buildFileItem(PlatformFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file,
              color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${(file.size / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close,
                color: AppColors.textSecondary, size: 20),
            onPressed: () {
              setState(() {
                _selectedFiles.remove(file);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isSubmitted, bool isSubmitting) {
    return Center(
      child: isSubmitted
          ? OutlinedButton(
              onPressed: isSubmitting ? null : _handleUnsubmit,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.border),
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                isSubmitting ? 'Processing...' : 'Unsubmit',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : (_selectedFiles.isNotEmpty || _submittedLink != null)
                      ? _handleSubmit
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.surfaceVariant,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                isSubmitting
                    ? 'Submitting...'
                    : (_selectedFiles.isNotEmpty || _submittedLink != null)
                        ? 'Submit'
                        : 'Mark as done',
                style: TextStyle(
                  color: (_selectedFiles.isNotEmpty || _submittedLink != null)
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
    );
  }

  Widget _buildPrivateCommentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline,
                  size: 18, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text(
                'Private comments',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.border),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // TODO: Add private comment
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Add comment to ${widget.course.instructor}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailItem(
            'Due',
            '${_formatDate(widget.assignment.deadline)} at ${_formatTime(widget.assignment.deadline)}',
            Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _buildDetailItem(
            'Attempts',
            '${widget.assignment.maxSubmissionAttempts}',
            Icons.repeat,
          ),
          if (widget.assignment.allowLateSubmissions) ...[
            const SizedBox(height: 12),
            _buildDetailItem(
              'Late submission',
              'Allowed',
              Icons.schedule,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ========================================
// FULL PAGE VERSION (for navigation)
// ========================================

class AssignmentDetailPage extends ConsumerWidget {
  final Assignment assignment;
  final CourseModel course;

  const AssignmentDetailPage({
    super.key,
    required this.assignment,
    required this.course,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgAppbar,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          course.code,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: AssignmentDetailView(
        assignment: assignment,
        course: course,
        onBack: () => Navigator.pop(context),
      ),
    );
  }
}
