import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../domain/models/assignment_model.dart';
import '../../../../../domain/models/course_model.dart';
import '../../../../../domain/models/submission_model.dart';
import '../../../../../data/repositories/submission/submission_repository.dart';
import '../../../../../core/theme/app_colors.dart';

// Web imports disabled for Windows compatibility
// import 'dart:html' as html;

// View widget for assignment detail (used within same page, no rebuild)
class AssignmentDetailView extends StatefulWidget {
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
  State<AssignmentDetailView> createState() => _AssignmentDetailViewState();
}

class _AssignmentDetailViewState extends State<AssignmentDetailView> {
  List<PlatformFile> _selectedFiles = [];
  bool _isDragging = false;
  bool _isSubmitted = false;
  String? _submittedLink;
  SubmissionModel? _currentSubmission;
  bool _isLoadingSubmission = true;

  @override
  void initState() {
    super.initState();
    _setupDragAndDrop();
    _loadSubmission();
  }

  Future<void> _loadSubmission() async {
    try {
      setState(() {
        _isLoadingSubmission = true;
      });

      print('DEBUG: ========== LOADING SUBMISSION ==========');
      print('DEBUG: Course ID: ${widget.course.id}');
      print('DEBUG: Assignment ID: ${widget.assignment.id}');

      final submission =
          await SubmissionRepository.getUserSubmissionForAssignment(
        widget.course.id,
        widget.assignment.id,
      );

      if (submission != null) {
        print('DEBUG: ✅ Submission loaded: ${submission.id}');
        print('DEBUG: Status: ${submission.status.name}');
        print('DEBUG: Submitted at: ${submission.submittedAt}');
        print('DEBUG: Attachments: ${submission.attachments.length}');

        setState(() {
          _currentSubmission = submission;
          _isSubmitted = submission.status == SubmissionStatus.submitted ||
              submission.status == SubmissionStatus.graded ||
              submission.status == SubmissionStatus.returned;

          // Load submitted link if available
          if (submission.attachments.isNotEmpty) {
            _submittedLink = submission.attachments.first.url;
          } else if (submission.textContent != null &&
              submission.textContent!.isNotEmpty) {
            // Check if textContent is a URL
            final uri = Uri.tryParse(submission.textContent!);
            if (uri != null &&
                (uri.scheme == 'http' || uri.scheme == 'https')) {
              _submittedLink = submission.textContent;
            }
          }
        });
      } else {
        print('DEBUG: ⚠️ No submission found');
        setState(() {
          _currentSubmission = null;
          _isSubmitted = false;
        });
      }
    } catch (e, stackTrace) {
      print('DEBUG: ❌ Error loading submission: $e');
      print('DEBUG: Stack trace: $stackTrace');
    } finally {
      setState(() {
        _isLoadingSubmission = false;
      });
    }
  }

  void _setupDragAndDrop() {
    // Drag and drop only supported on web platform
    // Non-web platforms will use file picker instead
    if (!kIsWeb) return;

    // Web-specific drag and drop setup would go here
    // For now, disabled to prevent compilation errors on Windows
    print('Drag and drop setup skipped on non-web platform');
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected ${result.files.length} file(s)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking files: $e'),
          backgroundColor: AppColors.error,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected ${result.files.length} image(s)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: AppColors.error,
        ),
      );
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link added'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child:
                const Text('Add', style: TextStyle(color: AppColors.primary)),
          ),
        ],
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

  Future<void> _handleSubmit() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to submit'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Prepare attachments from selected files
      final attachments = <AttachmentModel>[];
      if (_submittedLink != null && _submittedLink != 'Drive file') {
        // If it's a link, create an attachment for it
        attachments.add(AttachmentModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Link submission',
          url: _submittedLink!,
          mimeType: 'text/plain',
          sizeInBytes: 0,
          uploadedAt: DateTime.now(),
        ));
      }

      // Determine attempt number
      final attemptNumber = _currentSubmission != null
          ? _currentSubmission!.attemptNumber + 1
          : 1;

      // Check if late
      final now = DateTime.now();
      final isLate = now.isAfter(widget.assignment.deadline);

      // Create submission model
      final submission = SubmissionModel(
        id: _currentSubmission?.id ?? '',
        assignmentId: widget.assignment.id,
        studentId: user.uid,
        studentName: user.displayName ?? user.email ?? 'Unknown',
        courseId: widget.course.id,
        submittedAt: DateTime.now(),
        status: SubmissionStatus.submitted,
        attachments: attachments,
        textContent: _submittedLink,
        isLate: isLate,
        attemptNumber: attemptNumber,
        lastModified: DateTime.now(),
      );

      // Submit to Firestore
      bool success;
      if (_currentSubmission != null) {
        // Update existing submission
        success = await SubmissionRepository.updateSubmission(
          widget.course.id,
          _currentSubmission!.id,
          submission,
        );
      } else {
        // Create new submission
        success = await SubmissionRepository.submitAssignment(
          widget.course.id,
          submission,
        );
      }

      if (success) {
        // Reload submission to get updated data
        await _loadSubmission();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error submitting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Get work status based on deadline and submission
  String _getWorkStatus() {
    // If submitted, always show "Turned in"
    if (_isSubmitted) {
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

    // Default: assigned (not yet submitted)
    return 'assigned';
  }

  // Get status display text and color
  Map<String, dynamic> _getWorkStatusDisplay() {
    final status = _getWorkStatus();

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

  @override
  Widget build(BuildContext context) {
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
                          child: _buildMainContent(),
                        ),
                        // Sidebar (Right)
                        SizedBox(
                          width: 360,
                          child: _buildSidebarContent(),
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
                      _buildMainContent(),
                      _buildSidebarContent(),
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

  Widget _buildMainContent() {
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
                        const Text(
                          '•',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
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
              if (_currentSubmission != null && _currentSubmission!.isGraded)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currentSubmission!.maxScore != null
                        ? '${_currentSubmission!.score!.toStringAsFixed(0)}/${_currentSubmission!.maxScore!.toStringAsFixed(0)} points'
                        : '${_currentSubmission!.score!.toStringAsFixed(0)} points',
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
          Center(
            child: Text(
              'No comments yet',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent() {
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${data.length} file(s)'),
                    backgroundColor: AppColors.success,
                  ),
                );
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
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_upload,
                                  color: AppColors.primary),
                              const SizedBox(width: 8),
                              const Text(
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
                      Builder(
                        builder: (context) {
                          final statusDisplay = _getWorkStatusDisplay();
                          return Row(
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
                                    color:
                                        statusDisplay['borderColor'] as Color,
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
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Divider(color: AppColors.border),
                      const SizedBox(height: 16),
                      // Show submitted file/link if submitted
                      if (_isLoadingSubmission)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_isSubmitted && _currentSubmission != null) ...[
                        if (_currentSubmission!.attachments.isNotEmpty)
                          ..._currentSubmission!.attachments
                              .map((attachment) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          attachment.url.contains('drive') ||
                                                  attachment.url
                                                      .contains('google')
                                              ? Icons.drive_file_move
                                              : Icons.link,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                attachment.name,
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w500,
                                                  decoration:
                                                      TextDecoration.underline,
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
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList()
                        else if (_currentSubmission!.textContent != null &&
                            _currentSubmission!.textContent!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.link,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _currentSubmission!.textContent!,
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
                                        'Submitted ${_formatDate(_currentSubmission!.submittedAt)}',
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
                          ),
                        const SizedBox(height: 12),
                      ],
                      // Add or Create Button with Dropdown (only show if not submitted and no files)
                      if (!_isSubmitted &&
                          _selectedFiles.isEmpty &&
                          _submittedLink == null)
                        Center(
                          child: PopupMenuButton<String>(
                            offset: const Offset(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: AppColors.border),
                            ),
                            color: AppColors.surface,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primary),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add,
                                      size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Add or create',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_drop_down,
                                      color: AppColors.primary),
                                ],
                              ),
                            ),
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'file',
                                child: Row(
                                  children: [
                                    const Icon(Icons.insert_drive_file,
                                        size: 20, color: AppColors.textPrimary),
                                    const SizedBox(width: 12),
                                    const Text('File',
                                        style: TextStyle(
                                            color: AppColors.textPrimary)),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'link',
                                child: Row(
                                  children: [
                                    const Icon(Icons.link,
                                        size: 20, color: AppColors.textPrimary),
                                    const SizedBox(width: 12),
                                    const Text('Link',
                                        style: TextStyle(
                                            color: AppColors.textPrimary)),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'image',
                                child: Row(
                                  children: [
                                    const Icon(Icons.image,
                                        size: 20, color: AppColors.textPrimary),
                                    const SizedBox(width: 12),
                                    const Text('Hình',
                                        style: TextStyle(
                                            color: AppColors.textPrimary)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (String value) {
                              if (value == 'file') {
                                _handleFilePick();
                              } else if (value == 'link') {
                                _handleLinkAdd();
                              } else if (value == 'image') {
                                _handleImagePick();
                              }
                            },
                          ),
                        ),
                      // Selected Files Display (only show if not submitted)
                      if (!_isSubmitted && _selectedFiles.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ..._selectedFiles
                            .map((file) => Container(
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                            color: AppColors.textSecondary,
                                            size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _selectedFiles.remove(file);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ],
                      const SizedBox(height: 12),
                      // Submit/Unsubmit Button
                      Center(
                        child: _isSubmitted
                            ? OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _isSubmitted = false;
                                    _submittedLink = null;
                                    _selectedFiles.clear();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Unsubmitted'),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.border),
                                  minimumSize: const Size(double.infinity, 40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text(
                                  'Unsubmit',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: (_selectedFiles.isNotEmpty ||
                                        _submittedLink != null)
                                    ? () => _handleSubmit()
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  disabledBackgroundColor:
                                      AppColors.surfaceVariant,
                                  minimumSize: const Size(double.infinity, 40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: Text(
                                  (_selectedFiles.isNotEmpty ||
                                          _submittedLink != null)
                                      ? 'Submit'
                                      : 'Mark as done',
                                  style: TextStyle(
                                    color: (_selectedFiles.isNotEmpty ||
                                            _submittedLink != null)
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Private Comments Section (separate card)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
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
            ),
            const SizedBox(height: 16),
            // Assignment Details Card
            Container(
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
            ),
          ],
        ),
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

// Full page version (for navigation if needed)
class AssignmentDetailPage extends StatelessWidget {
  final Assignment assignment;
  final CourseModel course;

  const AssignmentDetailPage({
    super.key,
    required this.assignment,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
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
