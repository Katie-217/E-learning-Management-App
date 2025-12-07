import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/application/controllers/announcement/announcement_provider.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/announcement_tab_widget/announcement_tracking_screen.dart';
import '../../../widgets/course/Instructor_Course/announcement_tab_widget/simple_create_announcement_dialog.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../Instructor_Course/announcement_tab_widget/announcement_attachment_display_widget.dart';
import '../Instructor_Course/announcement_tab_widget/announcement_detail_screen_with_attachments.dart';

/// ============================================
/// HYBRID VERSION: Simple Layout + Advanced Features
/// - Giữ layout đơn giản của bản cũ
/// - Thêm features từ bản mới (attachments, tracking, groups)
/// ============================================

class InstructorStreamTab extends ConsumerWidget {
  final CourseModel course;
  const InstructorStreamTab({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementAsync = ref.watch(announcementListProvider(course.id));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========================================
          // COMPOSER (Keep simple design from old version)
          // ========================================
          _InstructorAnnouncementComposer(courseId: course.id),
          
          const SizedBox(height: 20),
          
          // ========================================
          // ANNOUNCEMENTS LIST (Add new features)
          // ========================================
          Expanded(
            child: announcementAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading announcements',
                      style: TextStyle(color: Colors.red[400], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      err.toString(),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              data: (announcements) {
                if (announcements.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined,
                            size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          'No announcements yet',
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first announcement to share with students',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(announcementListProvider(course.id));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final data = announcements[index];
                      return _EnhancedPostItem(
                        courseId: course.id,
                        announcementData: data,
                        onTap: () => _navigateToDetail(context, data, course.id),
                        onEdit: () => _showEditDialog(context, ref, data, course.id),
                        onDelete: () => _handleDelete(context, ref, data['id'], course.id),
                        onViewTracking: () => _navigateToTracking(context, data, course.id),
                      );
                    },
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
  // NAVIGATION METHODS
  // ========================================

  DateTime _parseDateTime(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    if (dateData is DateTime) return dateData;
    try {
      if (dateData is Timestamp) return dateData.toDate();
      return DateTime.parse(dateData.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  void _navigateToDetail(BuildContext context, Map<String, dynamic> announcement, String courseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementDetailScreen(
          announcementId: announcement['id'],
          courseId: courseId,
          title: announcement['title'] ?? 'Untitled',
          content: announcement['content'] ?? '',
          authorName: announcement['authorName'] ?? 'Unknown',
          createdAt: _parseDateTime(announcement['createdAt']),
        ),
      ),
    );
  }

  void _navigateToTracking(BuildContext context, Map<String, dynamic> announcement, String courseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementTrackingScreen(
          announcementId: announcement['id'],
          announcementTitle: announcement['title'] ?? 'Untitled',
          courseId: courseId,
          targetGroupIds: List<String>.from(announcement['targetGroupIds'] ?? []),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> announcement, String courseId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SimpleCreateAnnouncementDialog(
        courseId: courseId,
        announcementId: announcement['id'],
        initialTitle: announcement['title'],
        initialContent: announcement['content'],
        initialAttachments: List<Map<String, dynamic>>.from(announcement['attachments'] ?? []),
        initialTargetGroupIds: List<String>.from(announcement['targetGroupIds'] ?? []),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, String announcementId, String courseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('Delete Announcement', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this announcement? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(announcementControllerProvider.notifier).deleteAnnouncement(
            courseId: courseId,
            announcementId: announcementId,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting announcement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ========================================
// COMPOSER WIDGET (Keep simple design from old version)
// ========================================
class _InstructorAnnouncementComposer extends ConsumerWidget {
  final String courseId;
  const _InstructorAnnouncementComposer({required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => SimpleCreateAnnouncementDialog(courseId: courseId),
          );
        },
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.indigo,
              radius: 20,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  "Announce something to your class...",
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// ENHANCED POST ITEM (Simple layout + New features)
// ========================================
// ========================================
// ENHANCED POST ITEM (Đã cập nhật hiển thị file preview)
// ========================================
class _EnhancedPostItem extends ConsumerWidget {
  final String courseId;
  final Map<String, dynamic> announcementData;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewTracking;

  const _EnhancedPostItem({
    super.key, // Thêm super.key cho chuẩn
    required this.courseId,
    required this.announcementData,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onViewTracking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = announcementData['title'] ?? 'No Title';
    final content = announcementData['content'] ?? '';
    final authorName = announcementData['authorName'] ?? 'Instructor';
    final createdAt = _parseDateTime(announcementData['createdAt']);
    // Lấy danh sách attachments
    final attachments = List<Map<String, dynamic>>.from(announcementData['attachments'] ?? []);
    final targetGroupIds = List<String>.from(announcementData['targetGroupIds'] ?? []);
    final viewCount = announcementData['viewCount'] ?? 0;
    final commentCount = announcementData['commentCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========================================
              // HEADER
              // ========================================
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.indigo,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          timeago.format(createdAt, locale: 'en_short'),
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // Option Menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    color: const Color(0xFF374151),
                    onSelected: (value) {
                      switch (value) {
                        case 'tracking':
                          onViewTracking();
                          break;
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'tracking',
                        child: Row(
                          children: [
                            Icon(Icons.analytics, size: 18, color: Colors.green[400]),
                            const SizedBox(width: 8),
                            const Text('View Tracking', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            const Text('Edit', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),

              // ========================================
              // CONTENT
              // ========================================
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(color: Colors.grey[300]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // ========================================
              // UPDATED: ATTACHMENTS PREVIEW SECTION
              // ========================================
              if (attachments.isNotEmpty)
                // Sử dụng widget AnnouncementAttachmentDisplayWidget tại đây
                // Lưu ý: Widget này đã có sẵn padding top bên trong nó
                AnnouncementAttachmentDisplayWidget(
                  attachments: attachments,
                ),

              // ========================================
              // TARGET GROUPS
              // ========================================
              if (targetGroupIds.isNotEmpty) ...[
                const SizedBox(height: 12), // Tăng khoảng cách một chút nếu có attachments bên trên
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: targetGroupIds.take(3).map((groupId) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.purple.withOpacity(0.5)),
                      ),
                      child: Text(
                        groupId,
                        style: TextStyle(
                          color: Colors.purple[300],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList()
                    ..addAll(
                      targetGroupIds.length > 3
                          ? [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(
                                  '+${targetGroupIds.length - 3} more',
                                  style: TextStyle(color: Colors.purple[300], fontSize: 11),
                                ),
                              ),
                            ]
                          : [],
                    ),
                ),
              ],

              // ========================================
              // FOOTER
              // ========================================
              const SizedBox(height: 12),
              Divider(color: Colors.grey[800]),
              Row(
                children: [
                  Icon(Icons.visibility, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '$viewCount views',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.comment_outlined, size: 18, color: Colors.grey),
                    label: Text(
                      '$commentCount Comments',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _parseDateTime(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    if (dateData is DateTime) return dateData;
    try {
      if (dateData is Timestamp) return dateData.toDate();
      return DateTime.parse(dateData.toString());
    } catch (e) {
      return DateTime.now();
    }
  }
}