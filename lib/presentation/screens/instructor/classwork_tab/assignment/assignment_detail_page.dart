import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/file_preview_overlay.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/upload_file_assignment.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/add_link_assignments.dart';
import 'package:elearning_management_app/presentation/screens/instructor/classwork_tab/assignment/manage_assignment.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/create_assignment_page.dart';

class AssignmentDetailPage extends ConsumerStatefulWidget {
  final Assignment assignment;
  final String courseId;

  const AssignmentDetailPage({
    super.key,
    required this.assignment,
    required this.courseId,
  });

  @override
  ConsumerState<AssignmentDetailPage> createState() =>
      _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends ConsumerState<AssignmentDetailPage> {
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, h:mm a').format(dateTime);
  }

  // Get only link attachments
  List<Map<String, dynamic>> _getLinkAttachments() {
    return widget.assignment.attachments
        .where((attachment) => attachment['type'] == 'link')
        .toList();
  }

  // Get only file attachments (not links)
  List<Map<String, dynamic>> _getFileAttachments() {
    return widget.assignment.attachments
        .where((attachment) => attachment['type'] != 'link')
        .toList();
  }

  List<UploadedFileModel> _convertAttachmentsToFileModels() {
    final fileAttachments = _getFileAttachments();
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

  @override
  Widget build(BuildContext context) {
    final linkAttachments = _getLinkAttachments();
    final fileAttachments = _convertAttachmentsToFileModels();
    final hasAttachments =
        linkAttachments.isNotEmpty || fileAttachments.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Assignment Details',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          // Edit Button
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
            tooltip: 'Edit Assignment',
            onPressed: () {
              // Create a minimal CourseModel for edit mode
              final course = CourseModel(
                id: widget.assignment.courseId,
                code: '',
                name: '',
                instructor: '',
                semester: widget.assignment.semesterId,
                sessions: 0,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateAssignmentPage(
                    course: course,
                    existingAssignment: widget.assignment, // Pass existing data
                  ),
                ),
              ).then((result) {
                // Refresh if edited successfully
                if (result == true && mounted) {
                  setState(() {}); // Trigger rebuild
                  Navigator.pop(context,
                      true); // Return to previous screen with refresh flag
                }
              });
            },
          ),
          // Delete Button
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: const Color(0xFF1F2937),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey[700]!),
            ),
            onSelected: (value) async {
              if (value == 'delete') {
                await AssignmentManagement.handleDelete(
                  context: context,
                  ref: ref,
                  assignment: widget.assignment,
                  courseId: widget.courseId,
                  onSuccess: () {
                    // Navigate back after successful delete
                  },
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: Colors.red[400]),
                    const SizedBox(width: 8),
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          if (isDesktop) {
            // Desktop Layout: Row with Full-Height Sidebar
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side - Main Content (70%)
                Expanded(
                  flex: 7,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildMainContent(
                        hasAttachments, linkAttachments, fileAttachments),
                  ),
                ),

                // Right Side - Configuration Sidebar (30%) - FULL HEIGHT
                Expanded(
                  flex: 3,
                  child: Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      border: Border(
                        left: BorderSide(color: Colors.grey[800]!, width: 1),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildConfiguration(),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile Layout: Column (Stacked)
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Content
                  _buildMainContent(
                      hasAttachments, linkAttachments, fileAttachments),

                  const SizedBox(height: 24),

                  // Configuration as Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: _buildConfiguration(),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildMainContent(
    bool hasAttachments,
    List<Map<String, dynamic>> linkAttachments,
    List<UploadedFileModel> fileAttachments,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          widget.assignment.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        // Instructions Section
        if (widget.assignment.description.isNotEmpty) ...[
          Text(
            'Instructions',
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
              widget.assignment.description,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Attachments Section
        if (hasAttachments) ...[
          Text(
            'Attachments',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Links
          if (linkAttachments.isNotEmpty) ...[
            ...linkAttachments.map((linkData) {
              final metadata = LinkMetadata(
                url: linkData['url'] ?? '',
                title: linkData['title'] ?? linkData['name'] ?? 'Untitled',
                imageUrl: linkData['imageUrl'],
                description: linkData['description'],
                domain: linkData['domain'] ?? '',
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LinkPreviewCard(
                  metadata: metadata,
                  onRemove: () {},
                ),
              );
            }).toList(),
          ],

          // Files
          if (fileAttachments.isNotEmpty) ...[
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
      ],
    );
  }

  Widget _buildConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Configuration Header
        Text(
          'Configuration',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 24),

        // Points
        Text(
          'Points',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.stars, size: 18, color: Colors.amber[400]),
              const SizedBox(width: 8),
              Text(
                '${widget.assignment.maxPoints}',
                style: TextStyle(
                  color: Colors.amber[300],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Schedule
        Text(
          'Schedule',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Posted
        _buildDateRow(
          icon: Icons.publish,
          iconColor: Colors.green,
          label: 'Posted',
          value: _formatDateTime(widget.assignment.createdAt),
        ),

        const SizedBox(height: 10),

        // Edited (if exists)
        if (widget.assignment.updatedAt != null) ...[
          _buildDateRow(
            icon: Icons.edit,
            iconColor: Colors.blue,
            label: 'Edited',
            value: _formatDateTime(widget.assignment.updatedAt!),
          ),
          const SizedBox(height: 10),
        ],

        // Due Date
        _buildDateRow(
          icon: Icons.event,
          iconColor: Colors.orange,
          label: 'Due',
          value: _formatDateTime(widget.assignment.deadline),
          highlighted: true,
        ),

        // Late Deadline (if late submissions allowed)
        if (widget.assignment.allowLateSubmissions &&
            widget.assignment.lateDeadline != null) ...[
          const SizedBox(height: 10),
          _buildDateRow(
            icon: Icons.schedule,
            iconColor: Colors.red,
            label: 'Late Deadline',
            value: _formatDateTime(widget.assignment.lateDeadline!),
            highlighted: true,
          ),
        ],

        const SizedBox(height: 24),
        Divider(color: Colors.grey[800], height: 1),
        const SizedBox(height: 24),

        // Submission Settings
        Text(
          'Submission Settings',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),

        // Assign to
        _buildSettingRow(
          label: 'Assign to',
          value: '${widget.assignment.groupIds.length} groups',
          icon: Icons.group_outlined,
          iconColor: Colors.blue,
        ),

        const SizedBox(height: 16),

        // Max Attempts
        _buildSettingRow(
          label: 'Max Submission Attempts',
          value: '${widget.assignment.maxSubmissionAttempts}',
          icon: Icons.replay,
          iconColor: Colors.purple,
        ),

        const SizedBox(height: 16),

        // Allowed Formats
        _buildSettingRow(
          label: 'Allowed File Formats',
          value: widget.assignment.allowedFileFormats.isEmpty
              ? 'All formats'
              : widget.assignment.allowedFileFormats.join(', '),
          icon: Icons.insert_drive_file_outlined,
          iconColor: Colors.green,
        ),

        const SizedBox(height: 16),

        // Max Size
        _buildSettingRow(
          label: 'Max File Size',
          value: '${widget.assignment.maxFileSizeMB} MB',
          icon: Icons.storage_outlined,
          iconColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildDateRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool highlighted = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: highlighted ? iconColor : Colors.white,
                    fontSize: 13,
                    fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
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
}
