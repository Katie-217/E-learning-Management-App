import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/data/repositories/course/enrollment_repository.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/file_preview_overlay.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/upload_file_assignment.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/add_link_assignments.dart';
import 'package:elearning_management_app/presentation/screens/instructor/classwork_tab/assignment/assignment_detail_page.dart';
import 'package:elearning_management_app/presentation/screens/instructor/classwork_tab/assignment/manage_assignment.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/create_assignment_page.dart';
import 'package:elearning_management_app/presentation/screens/instructor/classwork_tab/assignment/assignment_tracking_page.dart';

class AssignmentDetailCard extends ConsumerStatefulWidget {
  final Assignment assignment;
  final String courseId; // NEW: Need courseId for edit/delete operations
  final String type;
  final IconData icon;
  final Color color;
  final VoidCallback? onReviewWork; // Keep this for now

  const AssignmentDetailCard({
    super.key,
    required this.assignment,
    required this.courseId,
    this.type = 'Assignment',
    this.icon = Icons.assignment_outlined,
    this.color = Colors.blue,
    this.onReviewWork,
  });

  @override
  ConsumerState<AssignmentDetailCard> createState() =>
      _AssignmentDetailCardState();
}

class _AssignmentDetailCardState extends ConsumerState<AssignmentDetailCard>
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

  // Get total students from assigned groups
  Future<int> _getTotalStudentsInGroups() async {
    try {
      final enrollmentRepo = EnrollmentRepository();
      int totalStudents = 0;

      for (String groupId in widget.assignment.groupIds) {
        final count = await enrollmentRepo.countStudentsInGroup(groupId);
        totalStudents += count.round(); // Convert num to int safely
      }

      return totalStudents;
    } catch (e) {
      print('Error counting students in groups: $e');
      return 0;
    }
  }

  // Get submission count
  Future<int> _getSubmissionCount() async {
    // TODO: Implement logic to count submissions from Firestore
    // Query submissions collection where assignmentId == widget.assignment.id
    return 0; // Placeholder
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

      // Extract file extension from filename or type
      String fileExtension = '';
      if (fileName.contains('.')) {
        fileExtension = fileName.substring(fileName.lastIndexOf('.'));
      } else {
        // Fallback to type if no extension in filename
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleExpanded,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _isExpanded ? widget.color.withOpacity(0.5) : Colors.grey[800]!,
            width: _isExpanded ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // HEADER (Always visible)
            _buildHeader(),

            // EXPANDED BODY (Collapsible)
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: _buildExpandedBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, color: widget.color, size: 24),
          ),
          const SizedBox(width: 12),

          // Title & Metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  widget.assignment.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Type Badge & Date Info
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.type,
                        style: TextStyle(
                          color: widget.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Posted Info
                    Text(
                      'Posted ${_formatDateTime(widget.assignment.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // More Menu
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
                    const Text('Edit', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy_outlined,
                        size: 18, color: Colors.green[400]),
                    const SizedBox(width: 8),
                    const Text('Duplicate',
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
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  // Navigate to Edit page
                  final course = CourseModel(
                    id: widget.assignment.courseId,
                    code: '',
                    name: '',
                    instructor: '',
                    semester: widget.assignment.semesterId,
                    sessions: 0,
                  );

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateAssignmentPage(
                        course: course,
                        existingAssignment: widget.assignment,
                      ),
                    ),
                  );

                  // Refresh if edited successfully
                  if (result == true && mounted) {
                    setState(() {}); // Trigger rebuild
                  }
                  break;

                case 'duplicate':
                  // TODO: Implement duplicate
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Duplicate feature coming soon'),
                    ),
                  );
                  break;

                case 'delete':
                  // Call delete management
                  await AssignmentManagement.handleDelete(
                    context: context,
                    ref: ref,
                    assignment: widget.assignment,
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
    );
  }

  Widget _buildExpandedBody() {
    final attachments = _convertAttachmentsToFileModels();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Dashboard
            _buildStatsSection(),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFF374151), height: 1),
            const SizedBox(height: 16),

            // Links Section
            if (_getLinkAttachments().isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.link, size: 18, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text(
                    'Links (${_getLinkAttachments().length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._getLinkAttachments().map((linkData) {
                final metadata = LinkMetadata(
                  url: linkData['url'] ?? '',
                  title: linkData['title'] ?? linkData['name'] ?? 'Untitled',
                  imageUrl: linkData['imageUrl'],
                  description: linkData['description'],
                  domain: linkData['domain'] ?? '',
                );
                return LinkPreviewCard(
                  metadata: metadata,
                  // onRemove: null → Không hiển thị nút X (view mode)
                );
              }).toList(),
              const SizedBox(height: 16),
            ],

            // Attachments List (Files only) (Files only)
            if (attachments.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.attach_file, size: 18, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text(
                    'Files (${attachments.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...attachments.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAttachmentCard(file, index, attachments),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],

            // Due Date Highlight (Responsive with Late Deadline)
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
                  // Regular Deadline
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 18, color: Colors.orange[400]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Due: ${DateFormat('MMM dd, yyyy • h:mm a').format(widget.assignment.deadline)}',
                          style: TextStyle(
                            color: Colors.orange[300],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  // Late Deadline (if exists)
                  if (widget.assignment.allowLateSubmissions &&
                      widget.assignment.lateDeadline != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 18, color: Colors.red[400]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Late Deadline: ${DateFormat('MMM dd, yyyy • h:mm a').format(widget.assignment.lateDeadline!)}',
                            style: TextStyle(
                              color: Colors.red[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          // Assigned Groups
          Expanded(
            child: _buildStatItem(
              icon: Icons.groups_outlined,
              label: 'Assigned',
              value: '${widget.assignment.groupIds.length}',
              subtitle: 'Groups',
              color: Colors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[800],
          ),
          // Turned In Students
          Expanded(
            child: FutureBuilder<List<int>>(
              future: Future.wait([
                _getTotalStudentsInGroups(),
                _getSubmissionCount(),
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildStatItem(
                    icon: Icons.assignment_turned_in_outlined,
                    label: 'Turned In',
                    value: '...',
                    subtitle: 'Loading',
                    color: Colors.green,
                  );
                }
                final total = snapshot.data![0];
                final submitted = snapshot.data![1];
                return _buildStatItem(
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Turned In',
                  value: '$submitted/$total',
                  subtitle: 'Students',
                  color: Colors.green,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // Custom attachment card without remove button (for instructor view)
  Widget _buildAttachmentCard(
    UploadedFileModel file,
    int index,
    List<UploadedFileModel> allFiles,
  ) {
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Thumbnail
            _buildFileThumbnail(file),

            // Right: File Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File Name
                    Text(
                      file.fileName,
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
                      file.formattedSize,
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        // View Instructions Button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Navigate to full-page Assignment Detail Page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssignmentDetailPage(
                    assignment: widget.assignment,
                    courseId: widget.assignment.courseId,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.grey[700]!),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text(
              'View Details',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Review Work Button (Primary)
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssignmentTrackingPage(
                    assignment: widget.assignment,
                    courseId: widget.courseId,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.rate_review_outlined, size: 18),
            label: const Text(
              'Review Work',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
