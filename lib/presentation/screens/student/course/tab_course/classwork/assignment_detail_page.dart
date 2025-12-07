import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/data/repositories/assignment/assignment_repository.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/file_preview_overlay.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/upload_file_assignment.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/add_link_assignments.dart';
import 'package:elearning_management_app/presentation/screens/student/course/tab_course/classwork/submission_work_widget.dart';

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
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, h:mm a').format(dateTime);
  }

  // Get only link attachments
  List<Map<String, dynamic>> _getLinkAttachments(Assignment assignment) {
    return assignment.attachments
        .where((attachment) => attachment['type'] == 'link')
        .toList();
  }

  // Get only file attachments (not links)
  List<Map<String, dynamic>> _getFileAttachments(Assignment assignment) {
    return assignment.attachments
        .where((attachment) => attachment['type'] != 'link')
        .toList();
  }

  List<UploadedFileModel> _convertAttachmentsToFileModels(
      Assignment assignment) {
    final fileAttachments = _getFileAttachments(assignment);
    return fileAttachments.map((attachment) {
      final String fileName =
          attachment['name'] ?? attachment['fileName'] ?? 'Untitled';
      final String fileUrl = attachment['url'] ?? '';
      final int fileSize = attachment['size'] ?? attachment['fileSize'] ?? 0;
      final String fileType = attachment['type'] ?? 'file';

      String fileExtension = '';
      if (fileName.contains('.')) {
        fileExtension = fileName.substring(fileName.lastIndexOf('.'));
      } else {
        fileExtension = '.$fileType';
      }

      return UploadedFileModel(
        fileName: fileName,
        filePath: fileUrl,
        fileSizeBytes: fileSize,
        fileExtension: fileExtension,
        fileBytes: null,
        platformFile: PlatformFile(
          name: fileName,
          size: fileSize,
          path: fileUrl,
        ),
      );
    }).toList();
  }

  String _getFileFormatLabel(String extension) {
    final ext = extension.toLowerCase();
    if (['.pdf'].contains(ext)) return 'PDF';
    if (['.doc', '.docx'].contains(ext)) return 'Word';
    if (['.xls', '.xlsx'].contains(ext)) return 'Excel';
    if (['.ppt', '.pptx'].contains(ext)) return 'PowerPoint';
    if (['.png', '.jpg', '.jpeg'].contains(ext)) return 'Image';
    if (['.txt'].contains(ext)) return 'Text';
    if (['.zip', '.rar'].contains(ext)) return 'Archive';
    return 'File';
  }

  Widget _buildFileCard(
    UploadedFileModel file,
    int index,
    List<UploadedFileModel> allFiles,
  ) {
    final icon = FileUploadService.getFileIcon(file.fileExtension);
    final color = FileUploadService.getFileColor(file.fileExtension);
    final formatLabel = _getFileFormatLabel(file.fileExtension);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: InkWell(
        onTap: () {
          FilePreviewOverlay.show(context, allFiles, initialIndex: index);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // File Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              // File Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            formatLabel,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          file.formattedSize,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.visibility_outlined,
                  size: 18, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Use StreamBuilder to listen for assignment changes in real-time
    return StreamBuilder<Assignment?>(
      stream: AssignmentRepository.listenToAssignment(widget.assignment.id),
      initialData: widget.assignment,
      builder: (context, snapshot) {
        // Use updated assignment or fallback to initial
        final assignment = snapshot.data ?? widget.assignment;

        final linkAttachments = _getLinkAttachments(assignment);
        final fileAttachments = _convertAttachmentsToFileModels(assignment);
        final hasAttachments =
            linkAttachments.isNotEmpty || fileAttachments.isNotEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: widget.onBack,
            ),
            title: const Text(
              'Assignment Details',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;

              if (isDesktop) {
                // Desktop Layout
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Content (70%)
                    Expanded(
                      flex: 7,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildMainContent(assignment, hasAttachments,
                            linkAttachments, fileAttachments),
                      ),
                    ),
                    // Submission Sidebar (30%)
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildSubmissionSidebar(assignment),
                      ),
                    ),
                  ],
                );
              } else {
                // Mobile Layout
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildMainContent(assignment, hasAttachments,
                            linkAttachments, fileAttachments),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildSubmissionSidebar(assignment),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildMainContent(
    Assignment assignment,
    bool hasAttachments,
    List<Map<String, dynamic>> linkAttachments,
    List<UploadedFileModel> fileAttachments,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          assignment.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // Posted and Edit Info (Responsive)
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            // Posted time
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 6),
                Text(
                  'Posted ',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatDateTime(assignment.createdAt),
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // Edited time
            if (assignment.updatedAt != null &&
                assignment.updatedAt != assignment.createdAt)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Text(
                    'Edited ',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _formatDateTime(assignment.updatedAt!),
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 24),

        // Instructions Section
        if (assignment.description.isNotEmpty) ...[
          Text(
            'INSTRUCTIONS',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Text(
              assignment.description,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Assignment Details Section
        Text(
          'ASSIGNMENT DETAILS',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start Date with green color
              Row(
                children: [
                  Icon(Icons.play_circle_outline,
                      size: 16, color: Colors.green[400]),
                  const SizedBox(width: 8),
                  Text(
                    'Start: ',
                    style: TextStyle(
                      color: Colors.green[400],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatDateTime(assignment.startDate),
                      style: TextStyle(
                        color: Colors.green[300],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Due Date with green color
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: Colors.green[400]),
                  const SizedBox(width: 8),
                  Text(
                    'Due: ',
                    style: TextStyle(
                      color: Colors.green[400],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatDateTime(assignment.deadline),
                      style: TextStyle(
                        color: Colors.green[300],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.emoji_events_outlined,
                'Points',
                '${assignment.maxPoints} points',
              ),

              // Your Grade Section removed - now handled by SubmissionWorkWidget

              _buildDetailRow(
                Icons.repeat,
                'Max Attempts',
                '${assignment.maxSubmissionAttempts} submission(s)',
              ),

              // Late Submission with yellow color
              if (assignment.allowLateSubmissions) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 16, color: Colors.yellow[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Late deadline: ',
                      style: TextStyle(
                        color: Colors.yellow[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        assignment.lateDeadline != null
                            ? _formatDateTime(assignment.lateDeadline!)
                            : 'Not specified',
                        style: TextStyle(
                          color: Colors.yellow[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Max File Size
              if (assignment.maxFileSizeMB != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.storage,
                  'Max file size',
                  '${assignment.maxFileSizeMB} MB',
                ),
              ],

              // Allowed File Formats with blue color
              if (assignment.allowedFileFormats != null &&
                  assignment.allowedFileFormats!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.description, size: 16, color: Colors.blue[400]),
                    const SizedBox(width: 8),
                    Text(
                      'Allowed formats: ',
                      style: TextStyle(
                        color: Colors.blue[400],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: assignment.allowedFileFormats!
                            .map((format) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: Colors.blue[300]!),
                                  ),
                                  child: Text(
                                    format,
                                    style: TextStyle(
                                      color: Colors.blue[300],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Attachments Section
        if (hasAttachments) ...[
          Text(
            'ATTACHMENTS',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Link Attachments
          if (linkAttachments.isNotEmpty)
            ...linkAttachments.map((link) {
              final url = link['url'] ?? '';
              final metadata = LinkMetadata(
                url: url,
                domain: Uri.parse(url).host,
                title: link['name'] ?? link['title'] ?? 'Link',
                description: link['description'] ?? '',
                imageUrl: link['imageUrl'],
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LinkPreviewCard(
                  metadata: metadata,
                  onRemove: () {}, // Empty for student view
                ),
              );
            }).toList(),

          // File Attachments
          if (fileAttachments.isNotEmpty)
            ...fileAttachments.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFileCard(file, index, fileAttachments),
              );
            }).toList(),
        ],
      ],
    );
  }

  // ========================================
  // BUILD: Submission Sidebar
  // ========================================
  Widget _buildSubmissionSidebar(Assignment assignment) {
    // Use the dedicated SubmissionWorkWidget for full submission functionality
    return SubmissionWorkWidget(
      assignment: assignment,
      course: widget.course,
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
    return AssignmentDetailView(
      assignment: assignment,
      course: course,
      onBack: () => Navigator.of(context).pop(),
    );
  }
}
