import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import '../../../../application/controllers/announcement/announcement_provider.dart';
import 'create_announcement_dialog.dart';
import '../../../screens/announcement/instructor/announcement_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InstructorStreamTab extends ConsumerWidget {
  final CourseModel course;
  const InstructorStreamTab({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementAsync = ref.watch(announcementListProvider(course.id));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Composer: Create announcement section
            _InstructorAnnouncementComposer(courseId: course.id),
            
            const SizedBox(height: 20),
            
            // List of announcements
            announcementAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              data: (announcements) {
                if (announcements.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("No announcements yet.", style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final data = announcements[index];
                    final announcementId = data['id'] ?? '';
                    final title = data['title'] ?? 'No Title';
                    final content = data['content'] ?? '';
                    final authorName = data['authorName'] ?? 'Instructor';
                    final createdAt = data['createdAt'] != null 
                        ? (data['createdAt'] as Timestamp).toDate() 
                        : DateTime.now();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnnouncementDetailScreen(
                                announcementId: announcementId,
                                courseId: course.id,
                                title: title,
                                content: content,
                                authorName: authorName,
                                createdAt: createdAt,
                              ),
                            ),
                          );
                        },
                        child: _PostItem(
                          courseId: course.id,
                          announcementId: announcementId,
                          title: title,
                          content: content,
                          authorName: authorName,
                          createdAt: "${createdAt.day}/${createdAt.month} ${createdAt.hour}:${createdAt.minute}",
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Composer widget
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
            builder: (context) => CreateAnnouncementDialog(courseId: courseId),
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

// Updated Post Item with Edit/Delete menu
class _PostItem extends ConsumerWidget {
  final String courseId;
  final String announcementId;
  final String title;
  final String content;
  final String authorName;
  final String createdAt;
  final bool isAuthor;

  const _PostItem({
    required this.courseId,
    required this.announcementId,
    required this.title,
    required this.content,
    required this.authorName,
    required this.createdAt,
    this.isAuthor = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(authorName, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    Text(createdAt, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),

              // More options menu (Edit/Delete)
              if (isAuthor)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  color: const Color(0xFF374151),
                  onSelected: (value) {
                    if (value == 'edit') {
                      showDialog(
                        context: context,
                        builder: (context) => CreateAnnouncementDialog(
                          courseId: courseId,
                          announcementId: announcementId,
                          initialTitle: title,
                          initialContent: content,
                        ),
                      );
                    } else if (value == 'delete') {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1F2937),
                          title: const Text('Delete Announcement?', style: TextStyle(color: Colors.white)),
                          content: const Text('This action cannot be undone.', style: TextStyle(color: Colors.grey)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                ref.read(announcementControllerProvider.notifier).deleteAnnouncement(
                                      courseId: courseId,
                                      announcementId: announcementId,
                                    );
                              },
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
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
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(color: Colors.grey[300])),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[800]),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.comment_outlined, size: 18, color: Colors.grey),
                label: const Text("Comments", style: TextStyle(color: Colors.grey)),
              ),
            ],
          )
        ],
      ),
    );
  }
}