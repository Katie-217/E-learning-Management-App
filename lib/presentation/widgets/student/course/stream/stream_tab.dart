import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/application/controllers/announcement/announcement_provider.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_repository.dart';
import 'package:elearning_management_app/presentation/widgets/student/course/stream/upcoming_widget.dart';
import 'package:elearning_management_app/presentation/screens/instructor/announcement_tab/announcement_detail_screen.dart';

class StreamTab extends ConsumerStatefulWidget {
  final CourseModel course;

  const StreamTab({super.key, required this.course});

  @override
  ConsumerState<StreamTab> createState() => _StreamTabState();
}

class _StreamTabState extends ConsumerState<StreamTab> {
  String? _studentGroupId;
  bool _isLoadingGroup = true;

  @override
  void initState() {
    super.initState();
    _loadStudentGroup();
  }

  /// ✅ SỬA: Load Group ID sử dụng currentUserProvider
  Future<void> _loadStudentGroup() async {
    try {
      // 1. Thử lấy user từ cache của Provider (nhanh)
      var userModel = ref.read(currentUserProvider).value;

      // 2. Nếu cache chưa có, gọi Async từ Repository (fallback)
      if (userModel == null) {
        userModel = await ref.read(authRepositoryProvider).currentUserModel;
      }

      // 3. Nếu vẫn không có user => Dừng
      if (userModel == null) {
        if (mounted) setState(() => _isLoadingGroup = false);
        return;
      }

      // 4. Query student-group assignment từ Firestore
      final doc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.course.id)
          .collection('students')
          .doc(userModel.uid) // Dùng uid từ userModel
          .get();

      if (mounted) {
        if (doc.exists) {
          setState(() {
            _studentGroupId = doc.data()?['groupId'] as String?;
            _isLoadingGroup = false;
          });
        } else {
          setState(() => _isLoadingGroup = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading student group: $e');
      if (mounted) {
        setState(() => _isLoadingGroup = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingGroup) {
      return const Center(child: CircularProgressIndicator());
    }

    final announcementsAsync = ref.watch(announcementListProvider(widget.course.id));
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 1000;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildAnnouncementList(context, announcementsAsync),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 320,
                  child: UpcomingWidget(course: widget.course),
                ),
              ],
            )
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    UpcomingWidget(course: widget.course),
                    const SizedBox(height: 16),
                    _buildAnnouncementList(context, announcementsAsync),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAnnouncementList(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> announcementsAsync,
  ) {
    return announcementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text(
          'Error loading announcements: $err',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (announcements) {
        // 🔥 Filter announcements based on student's group
        final filtered = announcements.where((ann) {
          final targetGroups = List<String>.from(ann['targetGroupIds'] ?? []);
          
          // Show if: sent to all groups OR student's group is in target list
          return targetGroups.isEmpty || 
                 (_studentGroupId != null && targetGroups.contains(_studentGroupId));
        }).toList();

        // Sort by pinned first, then by date
        filtered.sort((a, b) {
          final aPinned = a['isPinned'] ?? false;
          final bPinned = b['isPinned'] ?? false;
          
          if (aPinned && !bPinned) return -1;
          if (!aPinned && bPinned) return 1;
          
          final aDate = _parseDateTime(a['createdAt']);
          final bDate = _parseDateTime(b['createdAt']);
          return bDate.compareTo(aDate);
        });

        if (filtered.isEmpty) {
          // 1. Dùng Center để căn giữa toàn bộ khối
          return Center(
            // 2. [QUAN TRỌNG] Thêm SingleChildScrollView để tránh lỗi Overflow theo đúng hướng dẫn DevTools
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(), // Giúp cuộn mượt ngay cả khi nội dung ít
              child: Padding(
                // 3. SỬA: Bỏ 'top: 32', chỉ giữ padding ngang để tiết kiệm chiều cao
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Co cột lại vừa khít nội dung
                  children: [
                    // 4. SỬA: Giảm size icon từ 64 -> 48
                    Icon(Icons.campaign_outlined, size: 40, color: Colors.grey[600]),
                    
                    // 5. SỬA: Giảm khoảng cách từ 16 -> 8
                    const SizedBox(height: 4),
                    
                    Text(
                      "No announcements yet",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _studentGroupId == null
                          ? "You are not assigned to any group"
                          : "Your instructor hasn't posted anything",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ann = filtered[index];
            return _AnnouncementCard(
              announcementId: ann['id'],
              courseId: widget.course.id,
              title: ann['title'] ?? 'Untitled',
              content: ann['content'] ?? '',
              authorName: ann['authorName'] ?? 'Unknown',
              authorAvatar: ann['authorAvatar'],
              createdAt: _parseDateTime(ann['createdAt']),
              attachments: List<Map<String, dynamic>>.from(ann['attachments'] ?? []),
              isPinned: ann['isPinned'] ?? false,
              commentCount: ann['commentCount'] ?? 0,
            );
          },
        );
      },
    );
  }

  DateTime _parseDateTime(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    if (dateData is Timestamp) return dateData.toDate();
    if (dateData is DateTime) return dateData;
    try {
      return DateTime.parse(dateData.toString());
    } catch (_) {
      return DateTime.now();
    }
  }
}

/// Student-optimized announcement card
class _AnnouncementCard extends StatelessWidget {
  final String announcementId;
  final String courseId;
  final String title;
  final String content;
  final String authorName;
  final String? authorAvatar;
  final DateTime createdAt;
  final List<Map<String, dynamic>> attachments;
  final bool isPinned;
  final int commentCount;

  const _AnnouncementCard({
    required this.announcementId,
    required this.courseId,
    required this.title,
    required this.content,
    required this.authorName,
    this.authorAvatar,
    required this.createdAt,
    required this.attachments,
    required this.isPinned,
    required this.commentCount,
  });

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} min ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnnouncementDetailScreen(
              announcementId: announcementId,
              courseId: courseId,
              title: title,
              content: content,
              authorName: authorName,
              createdAt: createdAt,
              attachments: attachments,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPinned ? Colors.amber.withOpacity(0.5) : Colors.grey[800]!,
            width: isPinned ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with author info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.indigo,
                    backgroundImage: authorAvatar != null 
                        ? NetworkImage(authorAvatar!) 
                        : null,
                    child: authorAvatar == null
                        ? Text(
                            authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                authorName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isPinned) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.push_pin, color: Colors.amber, size: 16),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getTimeAgo(createdAt),
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Colors.grey),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: TextStyle(color: Colors.grey[300], height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Attachments preview
            if (attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Icon(Icons.attach_file, size: 18, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(
                      '${attachments.length} file${attachments.length > 1 ? 's' : ''} attached',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              ),

            // Footer with comment count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.comment_outlined, size: 18, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Text(
                    '$commentCount comment${commentCount != 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}