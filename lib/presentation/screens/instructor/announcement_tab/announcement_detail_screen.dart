import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:elearning_management_app/domain/models/comment_model.dart';
import 'package:elearning_management_app/application/controllers/announcement/announcement_provider.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_repository.dart';
import '../../../widgets/course/Instructor_Course/classwork_tab_widget/assignment/file_preview_overlay.dart';
import '../../../widgets/course/Instructor_Course/classwork_tab_widget/assignment/upload_file_assignment.dart';


class AnnouncementDetailScreen extends ConsumerStatefulWidget {
  final String announcementId;
  final String courseId;
  final String title;
  final String content;
  final String authorName;
  final DateTime createdAt;
  final List<Map<String, dynamic>> attachments;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcementId,
    required this.courseId,
    required this.title,
    required this.content,
    required this.authorName,
    required this.createdAt,
    this.attachments = const [],
  });

  @override
  ConsumerState<AnnouncementDetailScreen> createState() => 
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState 
    extends ConsumerState<AnnouncementDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSendingComment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackView();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

    /// ðŸŽ¯ Track that student viewed this announcement
  Future<void> _trackView() async {
    try {
      // CÃ¡ch 1: Láº¥y tá»« StreamProvider (nhanh, Ä‘á»“ng bá»™)
      var userModel = ref.read(currentUserProvider).value;

      // CÃ¡ch 2: Náº¿u Stream chÆ°a cÃ³ dá»¯ liá»‡u, gá»i trá»±c tiáº¿p Future tá»« Repository (cháº­m hÆ¡n chÃºt nhÆ°ng cháº¯c cháº¯n)
      if (userModel == null) {
        userModel = await ref.read(authRepositoryProvider).currentUserModel;
      }

      if (userModel == null) return;

      await ref.read(announcementControllerProvider.notifier).markAsViewed(
        announcementId: widget.announcementId,
        courseId: widget.courseId,
        currentUser: userModel,
      );
    } catch (e) {
      debugPrint('Error tracking view: $e');
    }
  }

// 2. Sá»­a hÃ m _handleDownload
Future<void> _handleDownload(String url, String fileName) async {
  try {
    var userModel = ref.read(currentUserProvider).value;
    if (userModel == null) {
      userModel = await ref.read(authRepositoryProvider).currentUserModel;
    }
    
    if (userModel == null) {
      _showSnackBar('You must be logged in to download', isError: true);
      return;
    }

    // Get file info
    final extension = _getFileExtension(fileName);
    final fileSize = widget.attachments
        .firstWhere(
          (file) => file['name'] == fileName,
          orElse: () => {'sizeInBytes': 0},
        )['sizeInBytes'] as int;

    // Check if file supports preview
    if (_supportsPreview(extension)) {
      // Create UploadedFileModel for preview
      final fileModel = UploadedFileModel(
        fileName: fileName,
        filePath: url, // Firebase URL
        fileSizeBytes: fileSize,
        fileExtension: extension,
        fileBytes: null, // Not needed for uploaded files
        platformFile: PlatformFile(
          name: fileName,
          size: fileSize,
          path: url,
        ),
      );

      // Show preview overlay
      await FilePreviewOverlay.show(
        context,
        [fileModel], // Single file
        initialIndex: 0,
      );

      // Track download after preview (user saw the file)
      await ref.read(announcementControllerProvider.notifier).markAsDownloaded(
        announcementId: widget.announcementId,
        courseId: widget.courseId,
        currentUser: userModel,
      );
      
      return;
    }

    // For non-previewable files, download directly
    await ref.read(announcementControllerProvider.notifier).markAsDownloaded(
      announcementId: widget.announcementId,
      courseId: widget.courseId,
      currentUser: userModel,
    );

    // Open/download file
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        _showSnackBar('Download started successfully');
      }
    } else {
      if (mounted) {
        _showSnackBar('Cannot open file', isError: true);
      }
    }
  } catch (e) {
    if (mounted) {
      _showSnackBar('Error: $e', isError: true);
    }
  }
}

// 3. Thêm helper method để check file có support preview không
bool _supportsPreview(String extension) {
  // Các định dạng được hỗ trợ preview bởi FilePreviewOverlay
  final supportedExtensions = [
    // Images
    '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp',
    // Documents
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
    // Text & Code
    '.txt', '.md', '.json', '.xml', '.csv', '.html', '.css', '.js',
    '.dart', '.java', '.py', '.cpp', '.c', '.h', '.cs', '.php',
  ];
  return supportedExtensions.contains(extension.toLowerCase());
}

// ========================================
// ALTERNATIVE: Nếu muốn preview nhiều files cùng lúc
// ========================================

// Method này cho phép user swipe qua lại giữa các attachments
Future<void> _handleDownloadWithGallery(String url, String fileName) async {
  try {
    var userModel = ref.read(currentUserProvider).value;
    if (userModel == null) {
      userModel = await ref.read(authRepositoryProvider).currentUserModel;
    }
    
    if (userModel == null) {
      _showSnackBar('You must be logged in to download', isError: true);
      return;
    }

    // Convert all attachments to UploadedFileModel
    final fileModels = widget.attachments.map((attachment) {
      final name = attachment['name'] as String;
      final fileUrl = attachment['url'] as String;
      final size = attachment['sizeInBytes'] as int;
      final ext = _getFileExtension(name);

      return UploadedFileModel(
        fileName: name,
        filePath: fileUrl,
        fileSizeBytes: size,
        fileExtension: ext,
        fileBytes: null,
        platformFile: PlatformFile(
          name: name,
          size: size,
          path: fileUrl,
        ),
      );
    }).toList();

    // Find initial index (file user clicked)
    final initialIndex = fileModels.indexWhere(
      (file) => file.fileName == fileName,
    );

    // Show preview overlay with gallery mode
    await FilePreviewOverlay.show(
      context,
      fileModels,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
    );

    // Track download
    await ref.read(announcementControllerProvider.notifier).markAsDownloaded(
      announcementId: widget.announcementId,
      courseId: widget.courseId,
      currentUser: userModel,
    );
  } catch (e) {
    if (mounted) {
      _showSnackBar('Error: $e', isError: true);
    }
  }
}

// ========================================
// EXAMPLE: Sử dụng trong build method
// ========================================

// Tìm phần render attachments trong build method và update như sau:

Widget _buildAttachmentsList() {
  if (widget.attachments.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 24),
      const Divider(color: Colors.grey),
      const SizedBox(height: 20),
      
      Row(
        children: [
          Icon(Icons.attach_file, color: Colors.indigo[400], size: 22),
          const SizedBox(width: 8),
          const Text(
            "Attachments",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      
      const SizedBox(height: 12),
      
      ...widget.attachments.map((file) {
        final fileName = file['name'] ?? 'Unknown file';
        final fileSize = _formatFileSize(file['sizeInBytes'] ?? 0);
        final extension = _getFileExtension(fileName);
        final fileColor = _getFileColor(extension);
        final fileIcon = _getFileIcon(extension);
        final supportsPreview = _supportsPreview(extension);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              // ✅ SỬ DỤNG METHOD MỚI
              onTap: () => _handleDownload(
                file['url'] ?? '',
                fileName,
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: fileColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        fileIcon,
                        color: fileColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '$fileSize • ${extension.toUpperCase()}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                              ),
                              // Badge cho previewable files
                              if (supportsPreview) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.5),
                                    ),
                                  ),
                                  child: const Text(
                                    'PREVIEW',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      supportsPreview ? Icons.visibility : Icons.download_rounded,
                      color: Colors.indigo[400],
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ],
  );
}

Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSendingComment) return;

    setState(() => _isSendingComment = true);

    try {
      var userModel = ref.read(currentUserProvider).value;
      
      if (userModel == null) {
        userModel = await ref.read(authRepositoryProvider).currentUserModel;
      }

      // Kiá»ƒm tra ká»¹ náº¿u váº«n khÃ´ng cÃ³ user
      if (userModel == null) {
        _showSnackBar('You must be logged in to comment', isError: true);
        setState(() => _isSendingComment = false); // Dá»«ng loading
        return;
      }

      _commentController.clear();
      FocusScope.of(context).unfocus();

      // Gá»i controller vá»›i userModel cháº¯c cháº¯n Ä‘Ã£ cÃ³ dá»¯ liá»‡u
      await ref.read(announcementControllerProvider.notifier).sendComment(
        announcementId: widget.announcementId,
        courseId: widget.courseId,
        content: text,
        currentUser: userModel,
      );

      if (mounted) {
        _showSnackBar('Comment posted successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to post comment: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingComment = false);
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String extension) {
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.purple;
      case 'zip':
      case 'rar':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentListProvider(widget.announcementId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        title: const Text(
          "Announcement",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // SCROLLABLE CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.indigo,
                          child: Text(
                            widget.authorName.isNotEmpty 
                                ? widget.authorName[0].toUpperCase() 
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.authorName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${widget.createdAt.day}/${widget.createdAt.month}/${widget.createdAt.year} at ${widget.createdAt.hour.toString().padLeft(2, '0')}:${widget.createdAt.minute.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Content (Markdown support)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: MarkdownBody(
                      data: widget.content,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.6,
                        ),
                        h1: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        h2: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        code: TextStyle(
                          backgroundColor: Colors.grey[800],
                          color: Colors.greenAccent,
                        ),
                        blockquote: TextStyle(
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),

                  // ATTACHMENTS SECTION
                  if (widget.attachments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Icon(Icons.attach_file, color: Colors.indigo[400], size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          "Attachments",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    ...widget.attachments.map((file) {
                      final fileName = file['name'] ?? 'Unknown file';
                      final fileSize = _formatFileSize(file['sizeInBytes'] ?? 0);
                      final extension = _getFileExtension(fileName);
                      final fileColor = _getFileColor(extension);
                      final fileIcon = _getFileIcon(extension);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _handleDownload(
                              file['url'] ?? '',
                              fileName,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: fileColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      fileIcon,
                                      color: fileColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fileName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$fileSize â€¢ ${extension.toUpperCase()}',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.download_rounded,
                                    color: Colors.indigo[400],
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],

                  const SizedBox(height: 24),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 20),
                  
                  // COMMENTS SECTION
                  const Row(
                    children: [
                      Icon(Icons.comment_outlined, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "Class Comments",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  commentsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, stack) => Text(
                      'Error loading comments: $err',
                      style: const TextStyle(color: Colors.red),
                    ),
                    data: (comments) {
                      if (comments.isEmpty) {
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
                                  "No comments yet",
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Be the first to comment!",
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
                      
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
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

          // COMMENT INPUT (Fixed at bottom)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              border: Border(
                top: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: "Add a class comment...",
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
                      onPressed: _isSendingComment ? null : _sendComment,
                      icon: _isSendingComment
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
            ),
          ),
        ],
      ),
    );
  }
}

/// Comment Item Widget
class _CommentItem extends StatelessWidget {
  final CommentModel comment;

  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[700],
            child: Text(
              comment.authorName.isNotEmpty 
                  ? comment.authorName[0].toUpperCase() 
                  : "?",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}