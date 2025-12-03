// ========================================
// FILE: instructor_topic_detail_screen.dart
// MÔ TẢ: Màn hình chi tiết topic cho giáo viên với quyền Content Administrator
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/application/controllers/forum/forum_provider.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_repository.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/services/file_upload_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../Student/create_topic_dialog.dart';

class InstructorTopicDetailScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String topicId;
  final Map<String, dynamic> topicData;

  const InstructorTopicDetailScreen({
    super.key,
    required this.courseId,
    required this.topicId,
    required this.topicData,
  });

  @override
  ConsumerState<InstructorTopicDetailScreen> createState() => _InstructorTopicDetailScreenState();
}

class _InstructorTopicDetailScreenState extends ConsumerState<InstructorTopicDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  bool _isSendingReply = false;
  String? _replyingToId;
  String? _replyingToAuthor;
  List<PlatformFile> _replyFiles = [];

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

  Future<void> _pickReplyFiles() async {
    final uploadService = ref.read(fileUploadServiceProvider);
    final files = await uploadService.pickFiles(allowMultiple: true);
    if (files != null) {
      setState(() => _replyFiles.addAll(files));
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if ((text.isEmpty && _replyFiles.isEmpty) || _isSendingReply) return;

    setState(() => _isSendingReply = true);

    try {
      final currentUser = await ref.read(authRepositoryProvider).currentUserModel;
      if (currentUser == null) return;

      List<String> attachmentUrls = [];
      if (_replyFiles.isNotEmpty) {
        final uploadService = ref.read(fileUploadServiceProvider);
        attachmentUrls = await uploadService.uploadMultipleFiles(
          files: _replyFiles,
          folder: 'forum_replies/${widget.courseId}',
        );
      }

      final success = await ref.read(forumControllerProvider.notifier).addReply(
            courseId: widget.courseId,
            topicId: widget.topicId,
            content: text.isEmpty ? '[Attachment]' : text,
            currentUser: currentUser,
            replyToId: _replyingToId,
            replyToAuthor: _replyingToAuthor,
            attachments: attachmentUrls,
          );

      if (success && mounted) {
        _replyController.clear();
        setState(() {
          _replyingToId = null;
          _replyingToAuthor = null;
          _replyFiles.clear();
        });
        FocusScope.of(context).unfocus();
        _showSnackBar('Reply posted successfully');
      }
    } catch (e) {
      _showSnackBar('Error posting reply: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSendingReply = false);
    }
  }

  // Content Administrator: Delete Topic
  void _confirmDeleteTopic() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('Delete Topic?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete the topic and all its replies. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(forumControllerProvider.notifier).deleteTopic(
                      widget.courseId,
                      widget.topicId,
                    );
                if (mounted) {
                  Navigator.pop(context); // Go back to topics list
                  _showSnackBar('Topic deleted successfully');
                }
              } catch (e) {
                _showSnackBar('Error deleting topic: $e', isError: true);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Content Administrator: Edit Topic
  void _showEditTopicDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateTopicDialog(
        courseId: widget.courseId,
        topicId: widget.topicId,
        initialTitle: widget.topicData['title'],
        initialContent: widget.topicData['content'],
      ),
    );
  }

  // Content Administrator: Delete Reply
  void _confirmDeleteReply(String replyId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('Delete Reply?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(forumControllerProvider.notifier).deleteReply(
                      widget.courseId,
                      widget.topicId,
                      replyId,
                    );
                _showSnackBar('Reply deleted successfully');
              } catch (e) {
                _showSnackBar('Error deleting reply: $e', isError: true);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
        actions: [
          // Content Administrator actions
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            tooltip: 'Edit Topic',
            onPressed: _showEditTopicDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Topic',
            onPressed: _confirmDeleteTopic,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
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
                                widget.topicData['title'] ?? 'Untitled',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.indigo.shade800,
                              child: Text(
                                (widget.topicData['authorName'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.topicData['authorName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _formatTimeAgo(_parseDateTime(widget.topicData['createdAt'])),
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.topicData['content'] ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  _AttachmentDisplayWidget(attachments: widget.topicData['attachments']),

                  const SizedBox(height: 24),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 20),

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
                              ],
                            ),
                          ),
                        );
                      }

                      // Build threaded reply list (same logic as student version)
                      List<Map<String, dynamic>> getDescendants(
                        String parentId,
                        String parentName,
                        List<Map<String, dynamic>> allReplies,
                      ) {
                        List<Map<String, dynamic>> result = [];
                        var children = allReplies.where((r) => r['replyToId'] == parentId).toList();
                        children.sort((a, b) {
                          final t1 = a['createdAt'] is Timestamp ? (a['createdAt'] as Timestamp).toDate() : DateTime.now();
                          final t2 = b['createdAt'] is Timestamp ? (b['createdAt'] as Timestamp).toDate() : DateTime.now();
                          return t1.compareTo(t2);
                        });
                        for (var child in children) {
                          result.add({...child, 'isChild': true, 'replyToUserName': parentName});
                          result.addAll(getDescendants(child['id'], child['authorName'] ?? 'Unknown', allReplies));
                        }
                        return result;
                      }

                      final rootReplies = replies.where((r) => r['replyToId'] == null || r['replyToId'].toString().isEmpty).toList();
                      rootReplies.sort((a, b) {
                        final t1 = a['createdAt'] is Timestamp ? (a['createdAt'] as Timestamp).toDate() : DateTime.now();
                        final t2 = b['createdAt'] is Timestamp ? (b['createdAt'] as Timestamp).toDate() : DateTime.now();
                        return t1.compareTo(t2);
                      });

                      List<Map<String, dynamic>> displayList = [];
                      for (var root in rootReplies) {
                        displayList.add({...root, 'isChild': false});
                        displayList.addAll(getDescendants(root['id'], root['authorName'] ?? 'Unknown', replies));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final reply = displayList[index];
                          return _InstructorReplyItem(
                            authorName: reply['authorName'] ?? 'Unknown',
                            content: reply['content'] ?? '',
                            timeAgo: _formatTimeAgo(_parseDateTime(reply['createdAt'])),
                            isChild: reply['isChild'] ?? false,
                            replyToUserName: reply['replyToUserName'],
                            attachments: reply['attachments'] ?? [],
                            onReply: () {
                              setState(() {
                                _replyingToId = reply['id'];
                                _replyingToAuthor = reply['authorName'];
                              });
                            },
                            onDelete: () => _confirmDeleteReply(reply['id']),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Reply Input
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
                              style: TextStyle(color: Colors.indigo[300], fontSize: 12),
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
                  if (_replyFiles.isNotEmpty) ...[
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _replyFiles.length,
                        itemBuilder: (context, index) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _replyFiles[index].name,
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                              InkWell(
                                onTap: () => setState(() => _replyFiles.removeAt(index)),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      IconButton(
                        onPressed: _pickReplyFiles,
                        icon: const Icon(Icons.attach_file, color: Colors.grey),
                      ),
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
// WIDGET: Instructor Reply Item (with Delete button)
// ========================================
class _InstructorReplyItem extends StatelessWidget {
  final String authorName;
  final String content;
  final String timeAgo;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final bool isChild;
  final String? replyToUserName;
  final List<dynamic> attachments;

  const _InstructorReplyItem({
    required this.authorName,
    required this.content,
    required this.timeAgo,
    required this.onReply,
    required this.onDelete,
    required this.isChild,
    this.replyToUserName,
    this.attachments = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isChild) ...[
            const SizedBox(width: 14),
            Column(
              children: [
                Icon(Icons.subdirectory_arrow_right_rounded, color: Colors.grey[600], size: 20),
              ],
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isChild ? const Color(0xFF252F3F) : const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isChild ? Colors.indigo.withOpacity(0.3) : Colors.grey[800]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.indigo.shade800,
                        child: Text(
                          authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authorName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(timeAgo, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: onReply,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            children: [
                              Icon(Icons.reply, color: Colors.indigo[400], size: 16),
                              const SizedBox(width: 4),
                              Text('Reply', style: TextStyle(color: Colors.indigo[400], fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Content Administrator: Delete button
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(Icons.delete_outline, color: Colors.red[400], size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isChild && replyToUserName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                          children: [
                            const TextSpan(text: "Replying to "),
                            TextSpan(
                              text: "@$replyToUserName",
                              style: TextStyle(color: Colors.indigo[300], fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Text(
                    content,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.4),
                  ),
                  _AttachmentDisplayWidget(attachments: attachments),
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
// WIDGET: Attachment Display (copied from student version)
// ========================================
class _AttachmentDisplayWidget extends StatelessWidget {
  final List<dynamic>? attachments;
  const _AttachmentDisplayWidget({this.attachments});

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black87,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline, color: Colors.red, size: 48),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFile(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('File Options', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File: ${url.split('/').last.split('?').first}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Text('What would you like to do?', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cannot open this file'), backgroundColor: Colors.red),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            icon: const Icon(Icons.open_in_browser, color: Colors.blue),
            label: const Text('Open in Browser', style: TextStyle(color: Colors.blue)),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL copied to clipboard'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy, color: Colors.green),
            label: const Text('Copy Link', style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (attachments == null || attachments!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: attachments!.map((url) {
          final urlStr = url.toString();
          final isImage = urlStr.contains('.jpg') || 
                         urlStr.contains('.png') || 
                         urlStr.contains('.jpeg') || 
                         urlStr.contains('alt=media');

          if (isImage) {
            return GestureDetector(
              onTap: () => _showImageDialog(context, urlStr),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  urlStr,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    width: 100,
                    color: Colors.grey[800],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            );
          } else {
            return GestureDetector(
              onTap: () => _openFile(context, urlStr),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insert_drive_file, size: 16, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('Attachment', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            );
          }
        }).toList(),
      ),
    );
  }
}