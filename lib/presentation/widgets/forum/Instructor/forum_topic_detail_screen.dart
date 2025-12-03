// ========================================
// FILE: forum_topic_detail_screen.dart
// DESCRIPTION: Simplified Forum Detail - Threaded Replies Only
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../application/controllers/forum/forum_provider.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../data/repositories/auth/auth_repository.dart';

class ForumTopicDetailScreen extends ConsumerStatefulWidget {
  final String courseId;
  final Map<String, dynamic> topicData;
  final bool isInstructor;

  const ForumTopicDetailScreen({
    Key? key,
    required this.courseId,
    required this.topicData,
    required this.isInstructor,
  }) : super(key: key);

  @override
  ConsumerState<ForumTopicDetailScreen> createState() => _ForumTopicDetailScreenState();
}

class _ForumTopicDetailScreenState extends ConsumerState<ForumTopicDetailScreen> {
  final TextEditingController _replyCtrl = TextEditingController();
  final fileService = FileUploadService();
  List<PlatformFile> selectedFiles = [];

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Requirement: Threaded Replies
    final repliesAsync = ref.watch(repliesProvider((
      courseId: widget.courseId,
      topicId: widget.topicData['id']
    )));

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết thảo luận")),
      body: Column(
        children: [
          // 1. Topic Content
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.topicData['title'] ?? 'Không tiêu đề',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(
                        (widget.topicData['authorName'] ?? 'U')[0].toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.topicData['authorName'] ?? 'Ẩn danh',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatTimestamp(widget.topicData['createdAt']),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(widget.topicData['content'] ?? ''),
                
                // Requirement: File Attachments
                if (_hasAttachments(widget.topicData['attachments']))
                  _buildAttachments(widget.topicData['attachments']),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Replies List (Threaded Replies)
          Expanded(
            child: repliesAsync.when(
              data: (replies) {
                if (replies.isEmpty) {
                  return const Center(
                    child: Text("Chưa có phản hồi nào", style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: replies.length,
                  itemBuilder: (context, index) {
                    return _buildReplyItem(replies[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text("Lỗi tải bình luận: $err", style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),

          // 3. Reply Input
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildReplyItem(Map<String, dynamic> reply) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      child: Text(
                        (reply['authorName'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reply['authorName'] ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          _formatTimestamp(reply['createdAt']),
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Instructor can delete (Content Administrator)
              if (widget.isInstructor)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  onPressed: () => _confirmDeleteReply(reply['id']),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(reply['content'] ?? ''),
          
          // File Attachments
          if (_hasAttachments(reply['attachments']))
            _buildAttachments(reply['attachments']),
        ],
      ),
    );
  }

  Widget _buildAttachments(dynamic attachments) {
    if (attachments == null) return const SizedBox.shrink();
    
    final files = List<String>.from(attachments);
    if (files.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: files.map((fileUrl) {
          final fileName = _getFileNameFromUrl(fileUrl);
          return InkWell(
            onTap: () => _openFile(fileUrl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.attach_file, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text(
                    fileName,
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (selectedFiles.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 4,
                children: selectedFiles.map((file) {
                  return Chip(
                    label: Text(file.name, style: const TextStyle(fontSize: 11)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      setState(() {
                        selectedFiles.remove(file);
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () async {
                  final files = await fileService.pickFiles();
                  if (files != null) {
                    setState(() {
                      selectedFiles = files;
                    });
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: _replyCtrl,
                  decoration: const InputDecoration(
                    hintText: "Nhập bình luận...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: _submitReply,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitReply() async {
    // Validation
    if (_replyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung phản hồi')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // ✅ FIX: Get real user info from auth provider
      final currentUser = await ref.read(authRepositoryProvider).currentUserModel;
      
      if (currentUser == null) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn chưa đăng nhập')),
        );
        return;
      }

      // Upload files if any
      List<String> fileUrls = [];
      if (selectedFiles.isNotEmpty) {
        fileUrls = await fileService.uploadMultipleFiles(
          files: selectedFiles,
          folder: 'forum_attachments',
        );
      }

      // ✅ FIX: Call with UserModel instead of separate uid/name
      final success = await ref.read(forumControllerProvider.notifier).addReply(
            courseId: widget.courseId,
            topicId: widget.topicData['id'],
            content: _replyCtrl.text,
            currentUser: currentUser, // ✅ Pass UserModel
            attachments: fileUrls,
          );

      Navigator.pop(context); // Close loading

      if (success) {
        _replyCtrl.clear();
        setState(() {
          selectedFiles = [];
        });
        FocusScope.of(context).unfocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể gửi phản hồi')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _confirmDeleteReply(String replyId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa phản hồi?"),
        content: const Text("Hành động này không thể hoàn tác."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              ref.read(forumControllerProvider.notifier).deleteReply(
                    widget.courseId,
                    widget.topicData['id'],
                    replyId,
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa phản hồi')),
              );
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  bool _hasAttachments(dynamic attachments) {
    if (attachments == null) return false;
    if (attachments is! List) return false;
    return attachments.isNotEmpty;
  }

  String _getFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      return segments.last.split('_').skip(1).join('_');
    }
    return 'file';
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is DateTime) {
        dateTime = timestamp;
      } else if (timestamp != null) {
        dateTime = DateTime.parse(timestamp.toString());
      } else {
        return 'Vừa xong';
      }

      final diff = DateTime.now().difference(dateTime);
      if (diff.inDays > 0) return '${diff.inDays} ngày trước';
      if (diff.inHours > 0) return '${diff.inHours} giờ trước';
      if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
      return 'Vừa xong';
    } catch (e) {
      return 'Vừa xong';
    }
  }
}