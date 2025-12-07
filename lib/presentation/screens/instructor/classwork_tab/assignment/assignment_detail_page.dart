import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/data/repositories/group/group_repository.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/file_preview_overlay.dart';
import 'package:file_picker/file_picker.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/upload_file_assignment.dart';

class AssignmentDetailPage extends StatefulWidget {
  final Assignment assignment;
  final CourseModel course;

  const AssignmentDetailPage({
    super.key,
    required this.assignment,
    required this.course,
  });

  @override
  State<AssignmentDetailPage> createState() => _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends State<AssignmentDetailPage> {
  List<String> _groupNames = [];
  bool _isLoadingGroups = true;

  @override
  void initState() {
    super.initState();
    _loadGroupNames();
  }

  Future<void> _loadGroupNames() async {
    try {
      final groups = await GroupRepository.getGroupsByCourse(widget.course.id);
      setState(() {
        _groupNames = groups
            .where((g) => widget.assignment.groupIds.contains(g.id))
            .map((g) => g.name)
            .toList();
        _isLoadingGroups = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGroups = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - h:mm a').format(dateTime);
  }

  List<Map<String, dynamic>> _getFileAttachments() {
    return widget.assignment.attachments
        .where((attachment) => attachment['type'] != 'link')
        .toList();
  }

  List<Map<String, dynamic>> _getLinkAttachments() {
    return widget.assignment.attachments
        .where((attachment) => attachment['type'] == 'link')
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
    if (['.ppt', '.pptx'].contains(ext)) return 'PowerPoint';
    if (['.xls', '.xlsx'].contains(ext)) return 'Excel';
    if (['.zip', '.rar', '.7z'].contains(ext)) return 'Archive';
    if (['.jpg', '.jpeg', '.png', '.gif'].contains(ext)) return 'Image';
    return extension.toUpperCase().replaceAll('.', '');
  }

  @override
  Widget build(BuildContext context) {
    final fileModels = _convertAttachmentsToFileModels();
    final linkAttachments = _getLinkAttachments();

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
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.indigo),
            onPressed: () {
              // TODO: Navigate to edit page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive breakpoint: if width < 800px, stack vertically
          final isWideScreen = constraints.maxWidth >= 800;

          if (isWideScreen) {
            // Wide screen: 2 columns (70/30 split)
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - Main Content (70%)
                Expanded(
                  flex: 7,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMainContentSection(fileModels, linkAttachments),
                      ],
                    ),
                  ),
                ),

                // Right Column - Configuration (30%)
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      border: Border(
                        left: BorderSide(color: Colors.grey[800]!, width: 1),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildConfigurationSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Narrow screen: Single column layout
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainContentSection(fileModels, linkAttachments),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: _buildConfigurationSection(),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildMainContentSection(
    List<UploadedFileModel> fileModels,
    List<Map<String, dynamic>> linkAttachments,
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
        const SizedBox(height: 16),

        // Dates
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_outline,
                    size: 18, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  'Start: ${_formatDateTime(widget.assignment.startDate)}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event, size: 18, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  'Due: ${_formatDateTime(widget.assignment.deadline)}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Instructions Section
        Text(
          'Instructions',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Text(
            widget.assignment.description.isEmpty
                ? 'No instructions provided'
                : widget.assignment.description,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Attachments Section
        if (fileModels.isNotEmpty || linkAttachments.isNotEmpty) ...[
          Text(
            'Attachments',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildAttachmentsSection(fileModels, linkAttachments),
        ],
      ],
    );
  }

  Widget _buildConfigurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        _buildSettingsSection(),
        const SizedBox(height: 24),
        _buildDateSection(),
        const SizedBox(height: 24),
        _buildGroupsSection(),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Created', _formatDateTime(widget.assignment.createdAt)),
        _buildInfoRow(
            'Start Date', _formatDateTime(widget.assignment.startDate)),
        _buildInfoRow('Due Date', _formatDateTime(widget.assignment.deadline)),
        if (widget.assignment.allowLateSubmissions &&
            widget.assignment.lateDeadline != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Late Submission',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Until: ${_formatDateTime(widget.assignment.lateDeadline!)}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Points', '${widget.assignment.maxPoints}'),
        _buildInfoRow(
            'Max Attempts', '${widget.assignment.maxSubmissionAttempts}'),
        _buildInfoRow(
            'Allowed Formats', widget.assignment.allowedFileFormats.join(', ')),
        _buildInfoRow('Max File Size', '${widget.assignment.maxFileSizeMB} MB'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assigned Groups',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingGroups)
          const Center(
              child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ))
        else if (_groupNames.isEmpty)
          Text(
            'All students',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _groupNames.map((name) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                ),
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAttachmentsSection(
    List<UploadedFileModel> fileModels,
    List<Map<String, dynamic>> linkAttachments,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Files
        if (fileModels.isNotEmpty) ...[
          ...fileModels.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getFileFormatLabel(file.fileExtension),
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(file.fileSizeBytes / 1024 / 1024).toStringAsFixed(2)} MB',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.indigo),
                    onPressed: () async {
                      final url = Uri.parse(file.filePath);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.grey),
                    onPressed: () {
                      FilePreviewOverlay.show(
                        context,
                        fileModels,
                        initialIndex: index,
                      );
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ],
        // Links
        if (linkAttachments.isNotEmpty) ...[
          if (fileModels.isNotEmpty) const SizedBox(height: 8),
          ...linkAttachments.map((link) {
            final hasImage = link['image'] != null && link['image'].isNotEmpty;
            final hasDescription =
                link['description'] != null && link['description'].isNotEmpty;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: InkWell(
                onTap: () async {
                  final url = Uri.parse(link['url']);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image preview if available
                    if (hasImage)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        child: Image.network(
                          link['image'],
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              color: Colors.grey[800],
                              child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.grey, size: 48),
                              ),
                            );
                          },
                        ),
                      ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.link,
                                  color: Colors.grey[400], size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  link['title'] ?? link['url'] ?? 'Link',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.open_in_new,
                                  color: Colors.indigo, size: 18),
                            ],
                          ),
                          if (hasDescription) ...[
                            const SizedBox(height: 8),
                            Text(
                              link['description'],
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            link['url'],
                            style: TextStyle(
                              color: Colors.grey[600],
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
            );
          }).toList(),
        ],
      ],
    );
  }
}
