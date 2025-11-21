import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/user_model.dart';
import 'package:elearning_management_app/domain/models/comment_model.dart';
import '../../../../application/controllers/announcement/announcement_provider.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_repository.dart';

class AnnouncementDetailScreen extends ConsumerStatefulWidget {
  final String announcementId;
  final String courseId;
  final String title;
  final String content;
  final String authorName;
  final DateTime createdAt;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcementId,
    required this.courseId,
    required this.title,
    required this.content,
    required this.authorName,
    required this.createdAt,
  });

  @override
  ConsumerState<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends ConsumerState<AnnouncementDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 🚀 AUTO-TRACKING LOGIC
    // Executed once when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackView();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Calls the controller to mark this announcement as viewed
  Future<void> _trackView() async {
    final currentUser = await ref.read(authRepositoryProvider).currentUserModel;
    if (currentUser != null) {
      ref.read(announcementControllerProvider.notifier).markAsViewed(
        announcementId: widget.announcementId,
        courseId: widget.courseId,
        currentUser: currentUser,
        groupId: 'default_group', // Replace with actual group logic if available
      );
    }
  }

  /// Handles sending a new comment
  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUser = await ref.read(authRepositoryProvider).currentUserModel;
    if (currentUser == null) return;

    // Clear input immediately for better UX
    _commentController.clear();
    FocusScope.of(context).unfocus();

    await ref.read(announcementControllerProvider.notifier).sendComment(
      announcementId: widget.announcementId,
      courseId: widget.courseId,
      content: text,
      currentUser: currentUser,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the real-time comment stream
    final commentsAsync = ref.watch(commentListProvider(widget.announcementId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text("Announcement Detail", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 1. CONTENT AREA (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author Info
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Text(widget.authorName[0], style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.authorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(
                            "${widget.createdAt.day}/${widget.createdAt.month} at ${widget.createdAt.hour}:${widget.createdAt.minute}",
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    widget.title,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // Content
                  Text(
                    widget.content,
                    style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.grey),
                  
                  // Comments Header
                  const Text(
                    "Class Comments",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // 2. COMMENT LIST
                  commentsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error loading comments: $err', style: const TextStyle(color: Colors.red)),
                    data: (comments) {
                      if (comments.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: Text("No comments yet.", style: TextStyle(color: Colors.grey))),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _CommentItem(comment: comments[index]);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. COMMENT INPUT AREA (Fixed at bottom)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1F2937),
              border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Add a class comment...",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF111827),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendComment,
                  icon: const Icon(Icons.send, color: Colors.indigo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Private Widget for Individual Comment
class _CommentItem extends StatelessWidget {
  final CommentModel comment;

  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey[700],
          child: Text(
            comment.authorName.isNotEmpty ? comment.authorName[0] : "?",
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.authorName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    comment.timeAgo, // Using the getter from your model
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment.content,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}