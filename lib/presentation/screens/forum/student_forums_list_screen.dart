// ========================================
// FILE: course_forums_list_screen.dart (ĐÃ NÂNG CẤP GIAO DIỆN)
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/application/controllers/forum/forum_provider.dart';
import 'package:elearning_management_app/presentation/widgets/forum/Student/forum_topics_screen.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';
import 'package:elearning_management_app/presentation/widgets/common/sidebar_model.dart';

class CourseForumsListScreen extends ConsumerWidget {
  final bool showSidebar;
  const CourseForumsListScreen({super.key, this.showSidebar = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forumsAsync = ref.watch(courseForumsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: showSidebar
          ? AppBar(
              backgroundColor: AppColors.bgAppbar,
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.indigo[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu_book, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'E-Learning',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              actions: [
                // Ô tìm kiếm
                SizedBox(
                  width: 280,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search forums, topics...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: AppColors.bgInput,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                // Thông báo
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                ),
                // Avatar + tên
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.indigo, Colors.purple]),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Jara Khan',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : null,

      // ==================== BODY ====================
      body: Row(
        children: [
          // Sidebar - chỉ hiện khi màn hình rộng và showSidebar = true
          if (showSidebar && MediaQuery.of(context).size.width > 800)
            const SidebarWidget(),

          // Nội dung chính
          Expanded(
            child: forumsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.indigo)),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading forums',
                      style: TextStyle(color: Colors.red[400], fontSize: 16),
                    ),
                  ],
                ),
              ),
              data: (forums) {
                if (forums.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined, size: 80, color: Colors.grey[600]),
                        const SizedBox(height: 24),
                        const Text(
                          'No forums available',
                          style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try again later or contact support',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: forums.length,
                  itemBuilder: (context, index) {
                    final forum = forums[index];
                    return _ForumCard(
                      courseName: forum['name'] ?? 'Unknown Course',
                      courseCode: forum['code'] ?? '',
                      topicCount: forum['topicCount'] ?? 0,
                      replyCount: forum['replyCount'] ?? 0,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForumTopicsScreen(
                              courseId: forum['id'],
                              courseName: forum['name'] ?? 'Unknown Course',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// WIDGET: Forum Card (giữ nguyên logic, chỉ tinh chỉnh màu cho hợp theme)
// ========================================
class _ForumCard extends StatelessWidget {
  final String courseName;
  final String courseCode;
  final int topicCount;
  final int replyCount;
  final VoidCallback onTap;

  const _ForumCard({
    required this.courseName,
    required this.courseCode,
    required this.topicCount,
    required this.replyCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.forum, color: Colors.indigo[400], size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '[$courseCode]',
                            style: TextStyle(color: Colors.indigo[400], fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            courseName,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.grey, height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _StatItem(label: 'topics', value: topicCount, color: Colors.blue[400]!)),
                    Container(width: 1, height: 30, color: Colors.grey[700]),
                    Expanded(child: _StatItem(label: 'replies', value: replyCount, color: Colors.green[400]!)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$value', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      ],
    );
  }
}