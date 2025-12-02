import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:elearning_management_app/domain/models/material_model.dart'
    as model;
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/file_preview_overlay.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/upload_file_assignment.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/add_link_assignments.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/material/create_material_page.dart';

class MaterialDetailPage extends ConsumerStatefulWidget {
  final model.MaterialModel material;
  final String courseId;

  const MaterialDetailPage({
    super.key,
    required this.material,
    required this.courseId,
  });

  @override
  ConsumerState<MaterialDetailPage> createState() => _MaterialDetailPageState();
}

class _MaterialDetailPageState extends ConsumerState<MaterialDetailPage> {
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, h:mm a').format(dateTime);
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
    final hasLink =
        widget.material.url != null && widget.material.url!.isNotEmpty;
    final hasFile = widget.material.attachment != null;
    final hasAttachments = hasLink || hasFile;

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
          'Material Details',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          // Edit Button
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
            tooltip: 'Edit Material',
            onPressed: () {
              // Create a minimal CourseModel for edit mode
              final course = CourseModel(
                id: widget.material.courseId,
                code: '',
                name: '',
                instructor: '',
                semester: '',
                sessions: 0,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateMaterialPage(
                    course: course,
                    existingMaterial: widget.material, // Pass existing data
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
                // TODO: Implement delete functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Delete functionality coming soon')),
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
                    child: _buildMainContent(hasAttachments, hasLink, hasFile),
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
                  _buildMainContent(hasAttachments, hasLink, hasFile),

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
    bool hasLink,
    bool hasFile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          widget.material.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        // Description Section
        if (widget.material.description != null &&
            widget.material.description!.isNotEmpty) ...[
          Text(
            'Description',
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
              widget.material.description!,
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

          // Link
          if (hasLink && widget.material.linkMetadata != null) ...[
            LinkPreviewCard(
              metadata: LinkMetadata(
                url: widget.material.linkMetadata!.url,
                title: widget.material.linkMetadata!.title,
                imageUrl: widget.material.linkMetadata!.imageUrl,
                description: widget.material.linkMetadata!.description,
                domain: widget.material.linkMetadata!.domain,
              ),
            ),
            const SizedBox(height: 12),
          ] else if (hasLink) ...[
            // Fallback for old materials without linkMetadata
            LinkPreviewCard(
              metadata: LinkMetadata(
                url: widget.material.url!,
                title: widget.material.title,
                imageUrl: null,
                description: widget.material.description,
                domain: Uri.parse(widget.material.url!).host,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // File
          if (hasFile) ...[
            _buildFileCard(widget.material.attachment!),
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

        // Author
        Text(
          'Author',
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
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.person, size: 18, color: Colors.blue[400]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.material.authorName ?? 'Unknown',
                  style: TextStyle(
                    color: Colors.blue[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Schedule
        Text(
          'Timeline',
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
          value: _formatDateTime(widget.material.createdAt),
        ),

        // Edited (if exists)
        if (widget.material.updatedAt != null) ...[
          const SizedBox(height: 10),
          _buildDateRow(
            icon: Icons.edit,
            iconColor: Colors.blue,
            label: 'Edited',
            value: _formatDateTime(widget.material.updatedAt!),
          ),
        ],

        const SizedBox(height: 24),
        Divider(color: Colors.grey[800], height: 1),
        const SizedBox(height: 24),

        // Material Info
        Text(
          'Material Information',
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
          label: 'Assigned to',
          value: 'All Groups in Course',
          icon: Icons.groups_outlined,
          iconColor: Colors.blue,
        ),

        const SizedBox(height: 16),

        // Material Type
        _buildSettingRow(
          label: 'Content Type',
          value: widget.material.attachment != null
              ? 'File Attachment'
              : widget.material.url != null
                  ? 'Link/URL'
                  : 'Text Material',
          icon: widget.material.attachment != null
              ? Icons.attach_file
              : widget.material.url != null
                  ? Icons.link
                  : Icons.description_outlined,
          iconColor: Colors.red,
        ),

        if (widget.material.attachment != null) ...[
          const SizedBox(height: 16),
          _buildSettingRow(
            label: 'File Size',
            value: _formatFileSize(widget.material.attachment!.sizeInBytes),
            icon: Icons.storage_outlined,
            iconColor: Colors.orange,
          ),
        ],

        const SizedBox(height: 16),

        // Status
        _buildSettingRow(
          label: 'Status',
          value: widget.material.isPublished ? 'Published' : 'Draft',
          icon: widget.material.isPublished
              ? Icons.check_circle_outline
              : Icons.drafts_outlined,
          iconColor: widget.material.isPublished ? Colors.green : Colors.orange,
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

  Widget _buildFileCard(model.AttachmentModel attachment) {
    final uploadedFile = UploadedFileModel(
      fileName: attachment.name,
      filePath: attachment.url,
      fileSizeBytes: attachment.sizeInBytes,
      fileExtension: attachment.name.contains('.')
          ? attachment.name.substring(attachment.name.lastIndexOf('.'))
          : '',
      fileBytes: null,
      platformFile: PlatformFile(
        name: attachment.name,
        size: attachment.sizeInBytes,
        path: attachment.url,
      ),
    );

    final icon = FileUploadService.getFileIcon(uploadedFile.fileExtension);
    final color = FileUploadService.getFileColor(uploadedFile.fileExtension);
    final formatLabel = _getFileFormatLabel(uploadedFile.fileExtension);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: InkWell(
        onTap: () {
          FilePreviewOverlay.show(context, [uploadedFile], initialIndex: 0);
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
                      uploadedFile.fileName,
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
                          uploadedFile.formattedSize,
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
