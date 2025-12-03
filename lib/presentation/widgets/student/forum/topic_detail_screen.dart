// ========================================
// FILE: topic_detail_screen.dart
// MÔ TẢ: Màn hình chi tiết topic với threaded replies
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/application/controllers/forum/forum_provider.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_repository.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String topicId;
  final String topicTitle;
  final String topicContent;

  const TopicDetailScreen({
    super.key,
    required this.courseId,
    required this.topicId,
    required this.topicTitle,
    required this.topicContent,
  });

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  bool _isSendingReply = false;
  String? _replyingToId;
  String? _replyingToAuthor;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSendingReply) return;

    setState(() => _isSendingReply = true);

    try {
      final currentUser = await ref.read(authRepositoryProvider).currentUserModel;

      if (currentUser == null) {
        _showSnackBar('You must be logged in to reply', isError: true);
        return;
      }

      // Clear input trước khi gửi
      final contentToSend = text;
      _replyController.clear();
      FocusScope.of(context).unfocus();

      // Gọi API với currentUser là UserModel
      final success = await ref.read(forumControllerProvider.notifier).addReply(
            courseId: widget.courseId,
            topicId: widget.topicId,
            content: contentToSend,
            currentUser: currentUser,
            replyToId: _replyingToId,
            replyToAuthor: _replyingToAuthor,
          );

      if (success && mounted) {
        _showSnackBar('Reply posted successfully');
        setState(() {
          _replyingToId = null;
          _replyingToAuthor = null;
        });
      } else if (mounted) {
        _showSnackBar('Failed to post reply', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingReply = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repliesAsync = ref.watch(repliesProvider((
      courseId: widget.courseId,
      topicId: widget.topicId,
    )));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        title: const Text(
          'Topic Discussion',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Topic Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.topic, color: Colors.indigo[400], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.topicTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16), // Khoảng cách
                  Text(
                    widget.topicContent, // Hiển thị nội dung
                    style: const TextStyle(
                      color: Colors.white70, // Màu chữ sáng dịu
                      fontSize: 15,
                      height: 1.5, // Giãn dòng cho dễ đọc
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 20),

                  // Comments Section
                  const Row(
                    children: [
                      Icon(Icons.comment_outlined, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Comments',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  repliesAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, stack) => Text(
                      'Error loading replies: $err',
                      style: const TextStyle(color: Colors.red),
                    ),
                    data: (replies) {
                      if (replies.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 48,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No replies yet',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Be the first to reply!',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final parentReplies = replies.where((r) => 
                            r['replyToId'] == null || r['replyToId'].toString().isEmpty
                        ).toList();

                        // 2. Lọc ra danh sách Con (có replyToId)
                        final childReplies = replies.where((r) => 
                            r['replyToId'] != null && r['replyToId'].toString().isNotEmpty
                        ).toList();

                        // 3. Tạo danh sách hiển thị tuần tự: Cha -> Các con của nó -> Cha tiếp theo
                        List<Map<String, dynamic>> displayList = [];

                        for (var parent in parentReplies) {
                          // Thêm Cha vào list
                          displayList.add({...parent, 'isChild': false});

                          // Tìm tất cả Con của Cha này
                          final myChildren = childReplies.where((child) => 
                              child['replyToId'] == parent['id']
                          ).toList();

                          // Sắp xếp con theo thời gian (cũ nhất lên trước)
                          myChildren.sort((a, b) {
                            final t1 = a['createdAt'] is Timestamp ? (a['createdAt'] as Timestamp).toDate() : DateTime.now();
                            final t2 = b['createdAt'] is Timestamp ? (b['createdAt'] as Timestamp).toDate() : DateTime.now();
                            return t1.compareTo(t2);
                          });

                          // Thêm các Con vào ngay sau Cha
                          for (var child in myChildren) {
                            displayList.add({...child, 'isChild': true});
                          }
                        }

                        // 4. Hiển thị danh sách đã sắp xếp
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final reply = displayList[index];

                            return _ReplyItem( // Gọi Widget đã sửa ở Bước 1
                              authorName: reply['authorName'] ?? 'Unknown',
                              content: reply['content'] ?? '',
                              timeAgo: _formatTimeAgo(_parseDateTime(reply['createdAt'])),
                              isChild: reply['isChild'] ?? false, // Truyền biến này vào
                              onReply: () {
                                setState(() {
                            _replyingToId = reply['id'];  // <--- QUAN TRĐỌNG: luôn lấy ID của chính nó
                                _replyingToAuthor = reply['authorName'];
                                });
                              },
                            );
                          },
                        );
                      },
                    
                  ),
                ],
              ),
            ),
          ),

          // Reply Input (Fixed at bottom)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              border: Border(
                top: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Replying to indicator
                  if (_replyingToAuthor != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.indigo.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.reply, size: 16, color: Colors.indigo[300]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Replying to $_replyingToAuthor',
                              style: TextStyle(
                                color: Colors.indigo[300],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _replyingToId = null;
                                _replyingToAuthor = null;
                              });
                            },
                            icon: Icon(Icons.close, size: 16, color: Colors.indigo[300]),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Reply input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          enabled: !_isSendingReply,
                          style: const TextStyle(color: Colors.white),
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: _replyingToAuthor != null
                                ? 'Write a reply to $_replyingToAuthor...'
                                : 'Add a reply...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF111827),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.indigo, Colors.purple],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: IconButton(
                          onPressed: _isSendingReply ? null : _sendReply,
                          icon: _isSendingReply
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// WIDGET: Reply Item (không hiển thị replyToAuthor vì không lưu trong DB)
// ========================================
class _ReplyItem extends StatelessWidget {
  final String authorName;
  final String content;
  final String timeAgo;
  final VoidCallback onReply;
  final bool isChild;

  const _ReplyItem({
    super.key, // Thêm key để tối ưu render
    required this.authorName,
    required this.content,
    required this.timeAgo,
    required this.onReply,
    required this.isChild,
  });

  @override
    Widget build(BuildContext context) {
      // Nếu là Child, chúng ta sẽ dùng Row để thêm mũi tên chỉ dẫn
      // Nếu là Parent, giữ nguyên khối
      return Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        child: IntrinsicHeight( // Giúp vẽ đường nối dọc nếu muốn (ở đây dùng Row đơn giản)
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PHẦN THỤT VÀO VÀ ICON (CHỈ HIỆN KHI LÀ CHILD)
              if (isChild) ...[
                const SizedBox(width: 16), // Khoảng cách từ lề trái
                Column(
                  children: [
                    // Icon mũi tên rẽ nhánh
                    Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(width: 8), // Khoảng cách giữa mũi tên và nội dung
              ],

              // 2. NỘI DUNG CHÍNH (Chiếm hết chiều ngang còn lại)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    // Màu nền: Child nhạt hơn chút để phân biệt
                    color: isChild 
                        ? const Color(0xFF252F3F) // Màu sáng hơn chút cho child
                        : const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isChild 
                          ? Colors.indigo.withOpacity(0.3) 
                          : Colors.grey[800]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Avatar + Tên + Thời gian
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14, // Nhỏ hơn chút cho tinh tế
                            backgroundColor: Colors.indigo.shade800,
                            child: Text(
                              authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Nút Reply nhỏ gọn
                          InkWell(
                            onTap: onReply,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.reply, color: Colors.indigo[400], size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Reply',
                                    style: TextStyle(
                                      color: Colors.indigo[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Content
                      Text(
                        content,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
