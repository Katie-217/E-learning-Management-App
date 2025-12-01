import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/application/controllers/announcement/announcement_provider.dart';
import '../../../screens/instructor/announcement_tab/announcement_detail_screen.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/announcement_tab_widget/announcement_tracking_screen.dart';
import '../../../widgets/course/Instructor_Course/announcement_tab_widget/simple_create_announcement_dialog.dart';
import 'simple_announcement_card.dart';

class InstructorStreamTab extends ConsumerWidget {
  final CourseModel course;

  const InstructorStreamTab({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(
      announcementListProvider(course.id),
    );

    return Column(
      children: [
        // ========================================
        // HEADER - Simple New Announcement Button
        // ========================================
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1720),
          ),
          child: InkWell(
            onTap: () => _showCreateAnnouncementDialog(context, ref),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.indigo[400],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'New Announcement',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share updates with your class',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[600],
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),

        // ========================================
        // ANNOUNCEMENTS LIST
        // ========================================
        Expanded(
          child: announcementsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
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

              // SỬA ĐỔI TẠI ĐÂY: Dùng Column để tách Tiêu đề (Fixed) và List (Scroll)
              return Column(
                children: [
                  // 1. HEADER CỐ ĐỊNH (Đưa ra khỏi ListView)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        const Text(
                          'Announcements',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. DANH SÁCH TRƯỢT (Scrollable)
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(announcementListProvider(course.id));
                      },
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        // Bỏ +1 vì header đã tách ra ngoài
                        itemCount: announcements.length,
                        itemBuilder: (context, index) {
                          // Không cần check index == 0 nữa
                          // Không cần trừ index - 1 nữa
                          final ann = announcements[index];

                          return SimpleAnnouncementCard(
                            announcementId: ann['id'],
                            courseId: course.id,
                            title: ann['title'] ?? 'Untitled',
                            content: ann['content'] ?? '',
                            authorName: ann['authorName'] ?? 'Unknown',
                            authorAvatar: ann['authorAvatar'],
                            createdAt: _parseDateTime(ann['createdAt']),
                            attachments: List<Map<String, dynamic>>.from(
                                ann['attachments'] ?? []),
                            targetGroupIds: List<String>.from(
                                ann['targetGroupIds'] ?? []),
                            viewCount: ann['viewCount'] ?? 0,
                            commentCount: ann['commentCount'] ?? 0,
                            isInstructor: true,
                            onTap: () => _navigateToDetail(context, ann, course.id),
                            onEdit: () =>
                                _showEditAnnouncementDialog(context, ref, ann),
                            onDelete: () =>
                                _handleDelete(context, ref, ann['id'], course.id),
                            onViewTracking: () =>
                                _navigateToTracking(context, ann, course.id),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ========================================
  // HELPER METHODS
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

  // ========================================
  // NAVIGATION METHODS
  // ========================================

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
          attachments: List<Map<String, dynamic>>.from(announcement['attachments'] ?? []),
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
          targetGroupIds: List<String>.from(
              announcement['targetGroupIds'] ?? []),
        ),
      ),
    );
  }

  // ========================================
  // DIALOG METHODS
  // ========================================

  void _showCreateAnnouncementDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SimpleCreateAnnouncementDialog(
        courseId: course.id,
      ),
    );
  }

  void _showEditAnnouncementDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SimpleCreateAnnouncementDialog(
        courseId: course.id,
        announcementId: announcement['id'],
        initialTitle: announcement['title'],
        initialContent: announcement['content'],
        initialAttachments: List<Map<String, dynamic>>.from(
            announcement['attachments'] ?? []),
      ),
    );
  }

  // ========================================
  // ACTION METHODS
  // ========================================

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, String announcementId, String courseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Delete Announcement',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this announcement? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
            ),
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