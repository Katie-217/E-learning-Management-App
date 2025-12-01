import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:elearning_management_app/domain/models/material_model.dart'
    as model;
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/file_preview_overlay.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/upload_file_assignment.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/add_link_assignments.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/material/create_material_page.dart';
import 'package:elearning_management_app/presentation/screens/instructor/classwork_tab/material/material_detail_page.dart';
import 'package:elearning_management_app/presentation/screens/instructor/classwork_tab/material/manage_material.dart';

class MaterialDetailCard extends ConsumerStatefulWidget {
  final model.MaterialModel material;
  final String courseId;

  const MaterialDetailCard({
    super.key,
    required this.material,
    required this.courseId,
  });

  @override
  ConsumerState<MaterialDetailCard> createState() => _MaterialDetailCardState();
}

class _MaterialDetailCardState extends ConsumerState<MaterialDetailCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • h:mm a').format(dateTime);
  }

  // Icon và màu mặc định cho Material
  IconData _getMaterialIcon() {
    // Material luôn dùng icon description (file document)
    return Icons.description_outlined;
  }

  Color _getMaterialColor() {
    // Luôn màu đỏ để phân biệt với Assignment (màu xanh/indigo)
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final hasAttachment = widget.material.attachment != null;
    final hasUrl =
        widget.material.url != null && widget.material.url!.isNotEmpty;

    return Card(
      color: const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon with colored background
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getMaterialColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getMaterialIcon(),
                      color: _getMaterialColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title and metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.material.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.account_circle,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              widget.material.authorName ?? 'Unknown',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              'Posted ${_formatDateTime(widget.material.createdAt)}',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                        if (widget.material.updatedAt != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                'Edited ${_formatDateTime(widget.material.updatedAt!)}',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // More Menu (Edit/Delete)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                    color: const Color(0xFF1F2937),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[700]!),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 18, color: Colors.blue[400]),
                            const SizedBox(width: 8),
                            const Text('Edit',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: Colors.red[400]),
                            const SizedBox(width: 8),
                            const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          // Navigate to Edit page
                          final course = CourseModel(
                            id: widget.courseId,
                            code: '',
                            name: '',
                            instructor: '',
                            semester: widget.material.courseId,
                            sessions: 0,
                          );

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateMaterialPage(
                                course: course,
                                existingMaterial: widget.material,
                              ),
                            ),
                          );

                          // Refresh if edited successfully
                          if (result == true && mounted) {
                            setState(() {}); // Trigger rebuild
                          }
                          break;

                        case 'delete':
                          // Call delete management
                          await MaterialManagement.handleDelete(
                            context: context,
                            ref: ref,
                            material: widget.material,
                            courseId: widget.courseId,
                            onSuccess: () {
                              // Card will be removed automatically by stream
                            },
                          );
                          break;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                const Divider(color: Color(0xFF334155), height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      if (widget.material.description != null &&
                          widget.material.description!.isNotEmpty) ...[
                        Text(
                          widget.material.description!,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Link section (với LinkPreviewCard như Assignment)
                      if (hasUrl) ...[
                        Row(
                          children: [
                            Icon(Icons.link, size: 18, color: Colors.grey[400]),
                            const SizedBox(width: 8),
                            const Text(
                              'Link',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinkPreviewCard(
                          metadata: widget.material.linkMetadata != null
                              ? LinkMetadata(
                                  url: widget.material.linkMetadata!.url,
                                  title: widget.material.linkMetadata!.title,
                                  imageUrl:
                                      widget.material.linkMetadata!.imageUrl,
                                  description:
                                      widget.material.linkMetadata!.description,
                                  domain: widget.material.linkMetadata!.domain,
                                )
                              : LinkMetadata(
                                  // Fallback nếu không có linkMetadata (material cũ)
                                  url: widget.material.url!,
                                  title: widget.material.title,
                                  imageUrl: null,
                                  description: widget.material.description,
                                  domain: Uri.parse(widget.material.url!).host,
                                ),
                          // onRemove: null → Không hiển thị nút X (view mode)
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Attachment section (với thumbnail đẹp như Assignment)
                      if (hasAttachment) ...[
                        Row(
                          children: [
                            Icon(Icons.attach_file,
                                size: 18, color: Colors.grey[400]),
                            const SizedBox(width: 8),
                            const Text(
                              'File',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildAttachmentCard(widget.material.attachment!),
                        const SizedBox(height: 16),
                      ],

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Navigate to Material Detail Page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MaterialDetailPage(
                                      material: widget.material,
                                      courseId: widget.courseId,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility_outlined,
                                  size: 18),
                              label: const Text('View Detail'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.indigo,
                                side: const BorderSide(color: Colors.indigo),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Navigate to progress tracking
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Progress monitoring coming soon!')),
                                );
                              },
                              icon: const Icon(Icons.analytics_outlined,
                                  size: 18),
                              label: const Text('Monitor'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
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
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Build attachment card với thumbnail đẹp như Assignment
  Widget _buildAttachmentCard(model.AttachmentModel attachment) {
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Thumbnail với màu sắc theo loại file
            _buildFileThumbnail(uploadedFile),

            // Right: File Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File Name
                    Text(
                      uploadedFile.fileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // File Size
                    Text(
                      uploadedFile.formattedSize,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Preview indicator
            Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.open_in_new,
                size: 18,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build file thumbnail với icon và màu sắc
  Widget _buildFileThumbnail(UploadedFileModel file) {
    final icon = FileUploadService.getFileIcon(file.fileExtension);
    final color = FileUploadService.getFileColor(file.fileExtension);

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 32,
      ),
    );
  }
}
