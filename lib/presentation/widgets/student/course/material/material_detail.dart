import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elearning_management_app/domain/models/material_model.dart'
    as model;
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/file_preview_overlay.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/upload_file_assignment.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/add_link_assignments.dart';
import 'package:elearning_management_app/data/repositories/material/material_tracker_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class StudentMaterialDetail extends StatefulWidget {
  final model.MaterialModel material;

  const StudentMaterialDetail({
    super.key,
    required this.material,
  });

  @override
  State<StudentMaterialDetail> createState() => _StudentMaterialDetailState();
}

class _StudentMaterialDetailState extends State<StudentMaterialDetail> {
  final MaterialTrackerRepository _trackerRepository =
      MaterialTrackerRepository();
  bool _hasMarkedAsViewed = false;

  @override
  void initState() {
    super.initState();
    _markAsViewed();
  }

  // Mark material as viewed when page opens
  Future<void> _markAsViewed() async {
    if (_hasMarkedAsViewed) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _trackerRepository.markAsViewed(
          widget.material.id,
          currentUser.uid,
        );
        _hasMarkedAsViewed = true;
        print('✅ Material marked as viewed');
      }
    } catch (e) {
      print('Error marking as viewed: $e');
    }
  }

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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _downloadFile(model.AttachmentModel attachment) async {
    try {
      // Mark as downloaded in tracker
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _trackerRepository.markAsDownloaded(
          widget.material.id,
          currentUser.uid,
        );
      }

      final url = Uri.parse(attachment.url);

      if (kIsWeb) {
        // Web: Trigger browser download
        html.AnchorElement(href: attachment.url)
          ..setAttribute('download', attachment.name)
          ..click();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloading ${attachment.name}...'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Desktop/Mobile: Open with system default app
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $url';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

                // Right Side - Configuration Sidebar (30%)
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
            _buildLinkPreviewCard(
              LinkMetadata(
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
            _buildLinkPreviewCard(
              LinkMetadata(
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

  Widget _buildLinkPreviewCard(LinkMetadata metadata) {
    return InkWell(
      onTap: () => _openLink(metadata.url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (if available)
            if (metadata.imageUrl != null && metadata.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  metadata.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Domain badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link, size: 12, color: Colors.blue[300]),
                        const SizedBox(width: 4),
                        Text(
                          metadata.domain,
                          style: TextStyle(
                            color: Colors.blue[300],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    metadata.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Description
                  if (metadata.description != null &&
                      metadata.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      metadata.description!,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openLink(metadata.url),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Open Link'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _downloadFile(model.AttachmentModel(
                          id: '',
                          name: metadata.title,
                          url: metadata.url,
                          mimeType: '',
                          sizeInBytes: 0,
                          uploadedAt: DateTime.now(),
                        )),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(model.AttachmentModel attachment) {
    // Extract file extension from name
    final extension = attachment.name.contains('.')
        ? attachment.name.substring(attachment.name.lastIndexOf('.'))
        : '';
    final fileIcon = FileUploadService.getFileIcon(extension);
    final fileColor = FileUploadService.getFileColor(extension);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // File Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: fileColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(fileIcon, color: fileColor, size: 28),
              ),

              const SizedBox(width: 16),

              // File Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: fileColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getFileFormatLabel(extension),
                            style: TextStyle(
                              color: fileColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatFileSize(attachment.sizeInBytes),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    print('DEBUG: Preview material attachment');
                    print('DEBUG: Name: ${attachment.name}');
                    print('DEBUG: URL: ${attachment.url}');
                    print('DEBUG: Extension: $extension');
                    print('DEBUG: Size: ${attachment.sizeInBytes}');

                    // Preview file using file_preview_overlay
                    // Create a dummy PlatformFile for preview
                    final platformFile = PlatformFile(
                      name: attachment.name,
                      size: attachment.sizeInBytes,
                      path: attachment.url,
                    );

                    final uploadedFile = UploadedFileModel(
                      fileName: attachment.name,
                      fileExtension: extension,
                      fileSizeBytes: attachment.sizeInBytes,
                      filePath: attachment.url,
                      platformFile: platformFile,
                    );
                    FilePreviewOverlay.show(context, [uploadedFile]);
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _downloadFile(attachment),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Configuration Header
        Text(
          'Information',
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

        // Timeline
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
      ],
    );
  }

  Widget _buildDateRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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
