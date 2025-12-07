import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/domain/models/submission_model.dart';
import 'package:elearning_management_app/data/repositories/submission/submission_repository.dart';
import 'package:elearning_management_app/data/repositories/course/enrollment_repository.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';
import 'package:elearning_management_app/presentation/screens/student/course/tab_course/classwork/upload_assignment.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/upload_file_assignment.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/file_preview_overlay.dart';

/// Widget for handling student submission work
/// Separated from assignment detail page for better code organization
class SubmissionWorkWidget extends StatefulWidget {
  final Assignment assignment;
  final CourseModel course;

  const SubmissionWorkWidget({
    super.key,
    required this.assignment,
    required this.course,
  });

  @override
  State<SubmissionWorkWidget> createState() => _SubmissionWorkWidgetState();
}

class _SubmissionWorkWidgetState extends State<SubmissionWorkWidget> {
  List<PlatformFile> _selectedFiles = [];
  List<UploadedFileModel> _uploadedFiles =
      []; // For uploaded files with preview
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  String? _submittedLink;
  SubmissionModel? _currentSubmission;
  bool _isLoadingSubmission = true;
  final EnrollmentRepository _enrollmentRepository = EnrollmentRepository();

  @override
  void initState() {
    super.initState();
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

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final submission =
          await SubmissionRepository.getStudentSubmissionForAssignment(
        widget.assignment.id,
        currentUser.uid,
      );

      if (submission != null) {
        print('DEBUG: Submission loaded: ${submission.id}');
        print('DEBUG: Status: ${submission.status.name}');
        print('DEBUG: Submitted at: ${submission.submittedAt}');
        print('DEBUG: Attachments: ${submission.attachments.length}');
        print('DEBUG: Score: ${submission.score}');
        print('DEBUG: Max Score: ${submission.maxScore}');
        print('DEBUG: Feedback: ${submission.feedback}');
        print('DEBUG: Graded At: ${submission.gradedAt}');
        print('DEBUG: Graded By: ${submission.gradedBy}');

        setState(() {
          _currentSubmission = submission;
          _isSubmitted = submission.status == SubmissionStatus.submitted ||
              submission.status == SubmissionStatus.graded ||
              submission.status == SubmissionStatus.late;

          if (submission.attachments.isNotEmpty) {
            _submittedLink = submission.attachments.first.url;
          } else if (submission.textContent != null &&
              submission.textContent!.isNotEmpty) {
            final uri = Uri.tryParse(submission.textContent!);
            if (uri != null &&
                (uri.scheme == 'http' || uri.scheme == 'https')) {
              _submittedLink = submission.textContent;
            }
          }
        });
      } else {
        print('DEBUG: âš ï¸ No submission found');
        setState(() {
          _currentSubmission = null;
          _isSubmitted = false;
        });
      }
    } catch (e, stackTrace) {
      print('DEBUG: âŒ Error loading submission: $e');
      print('DEBUG: Stack trace: $stackTrace');
    } finally {
      setState(() {
        _isLoadingSubmission = false;
      });
    }
  }

  Future<String?> _getStudentGroupId(String courseId, String userId) async {
    try {
      final groupId =
          await _enrollmentRepository.getStudentCurrentGroup(courseId, userId);
      if (groupId == null || groupId.isEmpty) {
        print(
            'DEBUG: âš ï¸ No groupId found for user $userId in course $courseId');
      } else {
        print('DEBUG: âœ… Found groupId $groupId for user $userId');
      }
      return groupId;
    } catch (e, stackTrace) {
      print('DEBUG: âŒ Error fetching groupId for student: $e');
      print('DEBUG: Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> _handleFilePick() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Use StudentUploadService with format validation
      final files = await StudentUploadService.pickFilesForAssignment(
        assignment: widget.assignment,
        context: context,
      );

      if (files.isEmpty) return;

      // Upload files immediately to Firebase Storage (for preview)
      // But DON'T save submission until user clicks Submit
      await _uploadFilesForPreview(files, user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _uploadFilesForPreview(
      List<UploadedFileModel> files, User user) async {
    final uploadedFiles = <UploadedFileModel>[];

    try {
      // Upload each file to Firebase Storage
      for (final file in files) {
        final progressNotifier = ValueNotifier<double>(0.0);

        if (mounted) {
          UploadProgressDialog.show(
            context,
            fileName: file.fileName,
            progressNotifier: progressNotifier,
          );
        }

        try {
          final uploadedFile = await StudentUploadService.uploadSubmissionFile(
            file: file,
            assignmentId: widget.assignment.id,
            studentId: user.uid,
            onProgress: (progress) {
              progressNotifier.value = progress;
            },
          );

          if (mounted) {
            Navigator.of(context).pop();
          }

          uploadedFiles.add(uploadedFile);
          print('✅ Uploaded to Firebase: ${uploadedFile.fileName}');
        } catch (e) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload ${file.fileName}: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }

          // Cleanup already uploaded files if one fails
          for (final uploaded in uploadedFiles) {
            try {
              await StudentUploadService.deleteFile(uploaded.filePath);
            } catch (e) {
              print('Error cleaning up file: $e');
            }
          }
          return;
        }
      }

      // Add uploaded files to local state (NOT saved to Firestore yet)
      setState(() {
        _uploadedFiles.addAll(uploadedFiles);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Uploaded ${uploadedFiles.length} file(s). Click Submit to save.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading files: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Delete file from Firebase Storage when user clicks X
  Future<void> _handleFileRemove(int index) async {
    try {
      final file = _uploadedFiles[index];

      // Delete from Firebase Storage
      await StudentUploadService.deleteFile(file.filePath);

      setState(() {
        _uploadedFiles.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted ${file.fileName} from storage'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected ${result.files.length} image(s)'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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

  Future<void> _handleSubmit() async {
    try {
      setState(() {
        _isSubmitting = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to submit'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final groupId =
          await _getStudentGroupId(widget.course.id, user.uid) ?? '';
      if (groupId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Không tìm thấy thông tin nhóm. Vui lòng liên hệ giảng viên.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Use attachments from current submission (draft) if available
      // This prevents re-uploading files that were already uploaded
      final uploadedUrls = <AttachmentModel>[
        if (_currentSubmission != null) ..._currentSubmission!.attachments,
      ];

      // Convert _uploadedFiles (already uploaded to Firebase) to AttachmentModel
      if (_uploadedFiles.isNotEmpty) {
        for (final file in _uploadedFiles) {
          uploadedUrls.add(AttachmentModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: file.fileName,
            url: file.filePath, // Already contains Firebase Storage URL
            mimeType: StudentUploadService.getContentType(file.fileExtension),
            sizeInBytes: file.fileSizeBytes,
            uploadedAt: DateTime.now(),
          ));
        }
        print('✅ Added ${_uploadedFiles.length} files from preview');
      }

      // Add link attachment if provided
      if (_submittedLink != null && _submittedLink != 'Drive file') {
        // Check if link is not already in attachments
        final linkExists = uploadedUrls.any((a) => a.url == _submittedLink);
        if (!linkExists) {
          uploadedUrls.add(AttachmentModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'Link submission',
            url: _submittedLink!,
            mimeType: 'text/plain',
            sizeInBytes: 0,
            uploadedAt: DateTime.now(),
          ));
        }
      }

      // Check if there are any attachments
      if (uploadedUrls.isEmpty &&
          (_submittedLink == null || _submittedLink == 'Drive file')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add files or link before submitting'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Calculate attempt number
      final attemptNumber = _currentSubmission != null
          ? _currentSubmission!.attemptNumber + 1
          : 1;

      // Check if max attempts exceeded
      if (widget.assignment.maxSubmissionAttempts > 0 &&
          attemptNumber > widget.assignment.maxSubmissionAttempts) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maximum attempts (${widget.assignment.maxSubmissionAttempts}) reached. Cannot submit again.',
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Determine submission status based on deadline
      final now = DateTime.now();
      final deadline = widget.assignment.deadline;
      final lateDeadline = widget.assignment.lateDeadline;

      SubmissionStatus status;
      bool isLate;

      if (now.isAfter(deadline)) {
        // After main deadline
        if (lateDeadline != null && now.isBefore(lateDeadline)) {
          // Within late submission window
          status = SubmissionStatus.submitted;
          isLate = true;
          print('📅 Submitted LATE (after deadline but before late deadline)');
        } else if (lateDeadline != null && now.isAfter(lateDeadline)) {
          // After late deadline - still mark as submitted but very late
          status = SubmissionStatus.submitted;
          isLate = true;
          print('📅 Submitted VERY LATE (after late deadline)');
        } else {
          // No late deadline, just late
          status = SubmissionStatus.submitted;
          isLate = true;
          print('📅 Submitted LATE (after deadline, no late deadline)');
        }
      } else {
        // Before main deadline - on time
        status = SubmissionStatus.submitted;
        isLate = false;
        print('📅 Submitted ON TIME');
      }

      final submission = SubmissionModel(
        id: _currentSubmission?.id ?? '',
        assignmentId: widget.assignment.id,
        studentId: user.uid,
        studentName: user.displayName ?? user.email ?? 'Unknown',
        courseId: widget.course.id,
        semesterId: widget.assignment.semesterId,
        groupId: groupId,
        submittedAt: DateTime.now(),
        status: status, // Use calculated status
        attachments: uploadedUrls, // Use uploaded file URLs
        textContent: _submittedLink,
        isLate: isLate, // Use calculated isLate
        attemptNumber: attemptNumber,
        lastModified: DateTime.now(),
      );

      bool success;
      if (_currentSubmission != null) {
        await SubmissionRepository.updateSubmission(submission);
        success = true;
      } else {
        final submissionId =
            await SubmissionRepository.createSubmission(submission);
        success = submissionId.isNotEmpty;
      }

      if (success) {
        // Clear uploaded files after successful submission
        setState(() {
          _uploadedFiles.clear();
        });

        await _loadSubmission();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Submitted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Error submitting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleUnsubmit() async {
    try {
      setState(() {
        _isSubmitting = true;
      });

      if (_currentSubmission == null) return;

      // Check if can still resubmit (check attempts remaining)
      if (widget.assignment.maxSubmissionAttempts > 0) {
        final currentAttempt = _currentSubmission!.attemptNumber;
        final maxAttempts = widget.assignment.maxSubmissionAttempts;

        if (currentAttempt >= maxAttempts) {
          // No more attempts left
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Cannot unsubmit: Maximum attempts ($maxAttempts) reached.\n'
                  'You have used all available submission attempts.',
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        // Show warning about remaining attempts
        final remainingAttempts = maxAttempts - currentAttempt;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1F2937),
            title: const Text(
              'Confirm Unsubmit',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to withdraw this submission?\n\n'
              'Current attempt: $currentAttempt of $maxAttempts\n'
              'Remaining attempts after unsubmit: $remainingAttempts\n\n'
              'You can resubmit, but this will count as a new attempt.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Unsubmit',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );

        if (confirmed != true) return;
      }

      // Delete submission completely (since new logic: no submission until submit)
      await SubmissionRepository.deleteSubmission(_currentSubmission!.id);

      // Reset local state to allow re-upload
      setState(() {
        _currentSubmission = null;
        _isSubmitted = false;
        _submittedLink = null;
        _uploadedFiles.clear(); // Clear uploaded files list
      });

      // Note: Files in Firebase Storage are NOT deleted
      // Student can re-upload if needed

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Submission withdrawn. You can upload new files and resubmit.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error unsubmitting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Check if assignment is overdue (past all deadlines)
  bool _isOverdue() {
    final now = DateTime.now();
    final deadline = widget.assignment.deadline;
    final lateDeadline = widget.assignment.lateDeadline;
    final allowLate = widget.assignment.allowLateSubmissions;

    if (allowLate && lateDeadline != null) {
      return now.isAfter(lateDeadline);
    }
    return now.isAfter(deadline);
  }

  // Check if file extension can be previewed
  bool _canPreviewExtension(String extension) {
    final ext = extension.toLowerCase();
    // Images
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return true;
    }
    // PDFs
    if (ext == '.pdf') {
      return true;
    }
    // Text files
    if (['.txt', '.md', '.json', '.xml', '.csv'].contains(ext)) {
      return true;
    }
    // Office files
    if (['.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'].contains(ext)) {
      return true;
    }
    return false;
  }

  String _getWorkStatus() {
    final now = DateTime.now();
    final startDate = widget.assignment.startDate;
    final deadline = widget.assignment.deadline;
    final lateDeadline = widget.assignment.lateDeadline;
    final allowLate = widget.assignment.allowLateSubmissions;

    // Check if submitted first
    if (_isSubmitted && _currentSubmission != null) {
      final submittedAt = _currentSubmission!.submittedAt!;

      // Check if submitted before or at due date
      if (submittedAt.isBefore(deadline) ||
          submittedAt.isAtSameMomentAs(deadline)) {
        return 'turned_in'; // TURNED IN (Green)
      }

      // Check if submitted after due date but before late deadline
      if (allowLate &&
          lateDeadline != null &&
          submittedAt.isAfter(deadline) &&
          (submittedAt.isBefore(lateDeadline) ||
              submittedAt.isAtSameMomentAs(lateDeadline))) {
        return 'late'; // LATE (Orange)
      }

      // Submitted after all deadlines (shouldn't happen but handle it)
      return 'turned_in';
    }

    // Student hasn't submitted yet - check assignment status
    if (now.isBefore(startDate)) {
      return 'upcoming'; // UPCOMING (Blue) - Before start date
    }

    if (now.isAfter(startDate) &&
        (now.isBefore(deadline) || now.isAtSameMomentAs(deadline))) {
      return 'open'; // OPEN (Green) - Between start and due date
    }

    if (allowLate &&
        lateDeadline != null &&
        now.isAfter(deadline) &&
        (now.isBefore(lateDeadline) || now.isAtSameMomentAs(lateDeadline))) {
      return 'late_period'; // LATE PERIOD (Orange) - Between due and late deadline
    }

    return 'overdue'; // OVERDUE (Red) - After all deadlines
  }

  Map<String, dynamic> _getWorkStatusDisplay() {
    final status = _getWorkStatus();

    switch (status) {
      case 'upcoming':
        return {
          'text': 'Upcoming',
          'color': Colors.blue,
          'bgColor': Colors.blue.withOpacity(0.15),
          'borderColor': Colors.blue.withOpacity(0.3),
        };
      case 'open':
        return {
          'text': 'Open',
          'color': Colors.green,
          'bgColor': Colors.green.withOpacity(0.15),
          'borderColor': Colors.green.withOpacity(0.3),
        };
      case 'late_period':
        return {
          'text': 'Late Period',
          'color': Colors.orange,
          'bgColor': Colors.orange.withOpacity(0.15),
          'borderColor': Colors.orange.withOpacity(0.3),
        };
      case 'overdue':
        return {
          'text': 'Overdue',
          'color': Colors.red,
          'bgColor': Colors.red.withOpacity(0.15),
          'borderColor': Colors.red.withOpacity(0.3),
        };
      case 'turned_in':
        return {
          'text': 'Turned In',
          'color': Colors.green,
          'bgColor': Colors.green.withOpacity(0.15),
          'borderColor': Colors.green.withOpacity(0.3),
        };
      case 'late':
        return {
          'text': 'Late',
          'color': Colors.orange,
          'bgColor': Colors.orange.withOpacity(0.15),
          'borderColor': Colors.orange.withOpacity(0.3),
        };
      default:
        return {
          'text': 'Unknown',
          'color': Colors.grey,
          'bgColor': Colors.grey.withOpacity(0.15),
          'borderColor': Colors.grey.withOpacity(0.3),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusDisplay = _getWorkStatusDisplay();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusDisplay['bgColor'] as Color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(
                color: statusDisplay['borderColor'] as Color,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Your work',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusDisplay['color'] as Color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusDisplay['text'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Submission Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoadingSubmission)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_isSubmitted && _currentSubmission != null) ...[
                  // Show submitted files/links with preview
                  if (_currentSubmission!.attachments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Submitted Files:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._currentSubmission!.attachments
                        .asMap()
                        .entries
                        .map((entry) {
                      final index = entry.key;
                      final attachment = entry.value;
                      final isLink = attachment.url.contains('http') &&
                          !attachment.url.contains('firebasestorage');
                      final isFile = !isLink;

                      // Determine file extension from name
                      final extension = attachment.name.contains('.')
                          ? '.${attachment.name.split('.').last}'
                          : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: InkWell(
                          onTap: isFile && _canPreviewExtension(extension)
                              ? () {
                                  // Show preview overlay for previewable files
                                  final files = _currentSubmission!.attachments
                                      .where((a) =>
                                          !a.url.contains('http') ||
                                          a.url.contains('firebasestorage'))
                                      .map((a) {
                                    final ext = a.name.contains('.')
                                        ? '.${a.name.split('.').last}'
                                        : '';
                                    return UploadedFileModel(
                                      fileName: a.name,
                                      filePath: a.url,
                                      fileSizeBytes: a.sizeInBytes,
                                      fileExtension: ext,
                                      platformFile: PlatformFile(
                                        name: a.name,
                                        size: a.sizeInBytes,
                                        path: a.url,
                                      ),
                                    );
                                  }).toList();

                                  final fileIndex = _currentSubmission!
                                      .attachments
                                      .where((a) =>
                                          !a.url.contains('http') ||
                                          a.url.contains('firebasestorage'))
                                      .toList()
                                      .indexWhere(
                                          (a) => a.url == attachment.url);

                                  FilePreviewOverlay.show(
                                    context,
                                    files,
                                    initialIndex:
                                        fileIndex >= 0 ? fileIndex : 0,
                                  );
                                }
                              : () async {
                                  // Open in external browser
                                  final uri = Uri.parse(attachment.url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  }
                                },
                          child: Row(
                            children: [
                              // File icon with color
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      FileUploadService.getFileColor(extension)
                                          .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isLink
                                      ? Icons.link
                                      : FileUploadService.getFileIcon(
                                          extension),
                                  color: isLink
                                      ? Colors.blue
                                      : FileUploadService.getFileColor(
                                          extension),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      attachment.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      attachment.sizeInBytes > 0
                                          ? '${(attachment.sizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB'
                                          : 'Link',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isFile && _canPreviewExtension(extension))
                                IconButton(
                                  icon: Icon(Icons.visibility,
                                      color: Colors.blue[400]),
                                  onPressed: () {
                                    // Show preview
                                    final files = _currentSubmission!
                                        .attachments
                                        .where((a) =>
                                            !a.url.contains('http') ||
                                            a.url.contains('firebasestorage'))
                                        .map((a) {
                                      final ext = a.name.contains('.')
                                          ? '.${a.name.split('.').last}'
                                          : '';
                                      return UploadedFileModel(
                                        fileName: a.name,
                                        filePath: a.url,
                                        fileSizeBytes: a.sizeInBytes,
                                        fileExtension: ext,
                                        platformFile: PlatformFile(
                                          name: a.name,
                                          size: a.sizeInBytes,
                                          path: a.url,
                                        ),
                                      );
                                    }).toList();

                                    final fileIndex = _currentSubmission!
                                        .attachments
                                        .where((a) =>
                                            !a.url.contains('http') ||
                                            a.url.contains('firebasestorage'))
                                        .toList()
                                        .indexWhere(
                                            (a) => a.url == attachment.url);

                                    FilePreviewOverlay.show(
                                      context,
                                      files,
                                      initialIndex:
                                          fileIndex >= 0 ? fileIndex : 0,
                                    );
                                  },
                                  tooltip: 'Preview',
                                )
                              else if (isFile)
                                IconButton(
                                  icon: Icon(Icons.open_in_new,
                                      color: Colors.blue[400]),
                                  onPressed: () async {
                                    final uri = Uri.parse(attachment.url);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  tooltip: 'Open',
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],

                  // ========================================
                  // GRADE DISPLAY SECTION
                  // ========================================
                  if (_currentSubmission!.status == SubmissionStatus.graded &&
                      _currentSubmission!.score != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.grade,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Your Grade',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Score Display
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${_currentSubmission!.score!.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '/ ${_currentSubmission!.maxScore?.toStringAsFixed(0) ?? widget.assignment.maxPoints.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getGradeColor(
                                      _currentSubmission!.score!,
                                      _currentSubmission!.maxScore ??
                                          widget.assignment.maxPoints),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getGradePercentage(
                                      _currentSubmission!.score!,
                                      _currentSubmission!.maxScore ??
                                          widget.assignment.maxPoints),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Feedback Section
                          if (_currentSubmission!.feedback != null &&
                              _currentSubmission!.feedback!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFF374151)),
                            const SizedBox(height: 12),
                            const Text(
                              'Instructor Feedback:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F2937),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _currentSubmission!.feedback!,
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],

                          // Graded At
                          if (_currentSubmission!.gradedAt != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Graded ${_formatTimeAgo(_currentSubmission!.gradedAt!)}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ] else ...[
                  // Add or Create Button (always show unless submitted)
                  if (!_isSubmitted)
                    Center(
                      child: _isOverdue()
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[600]!),
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.grey[800],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add,
                                      size: 18, color: Colors.grey[500]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add or create',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            )
                          : InkWell(
                              onTap: _handleFilePick,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blue),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add,
                                        size: 18, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      'Add or create',
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),

                  // Uploaded Files Display with Preview (Files already on Firebase, ready to submit)
                  if (_uploadedFiles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'New Files (Ready to submit):',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    UploadedFilesList(
                      files: _uploadedFiles,
                      onRemove: (index) async {
                        await _handleFileRemove(index);
                      },
                      showPreview: true,
                    ),
                  ],
                ],

                const SizedBox(height: 16),

                // Submit/Unsubmit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : _isSubmitted
                            ? _handleUnsubmit
                            : (_uploadedFiles.isEmpty && _submittedLink == null)
                                ? null
                                : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSubmitted
                          ? Colors.red[700]
                          : (_uploadedFiles.isEmpty && _submittedLink == null)
                              ? Colors.grey[700]
                              : Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isSubmitted ? 'Unsubmit' : 'Submit Assignment',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // GRADE HELPER METHODS
  // ========================================

  /// Get grade color based on percentage
  Color _getGradeColor(double score, double maxScore) {
    final percentage = (score / maxScore) * 100;
    if (percentage >= 90) {
      return Colors.green; // A
    } else if (percentage >= 80) {
      return Colors.lightGreen; // B
    } else if (percentage >= 70) {
      return Colors.orange; // C
    } else if (percentage >= 60) {
      return Colors.deepOrange; // D
    } else {
      return Colors.red; // F
    }
  }

  /// Get grade percentage string
  String _getGradePercentage(double score, double maxScore) {
    final percentage = (score / maxScore) * 100;
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Format time ago
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final localDateTime = dateTime.toLocal();
    final difference = now.difference(localDateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }
}
