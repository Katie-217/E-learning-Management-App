import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:elearning_management_app/domain/models/comment_model.dart';
import 'package:elearning_management_app/application/controllers/announcement/announcement_provider.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_repository.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Để sử dụng Uint8List
import 'package:flutter_html/flutter_html.dart'; // Thêm mới
import 'package:http/http.dart' as http; // Thêm mới

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

    /// 🎯 Track that student viewed this announcement
  Future<void> _trackView() async {
    try {
      // Cách 1: Lấy từ StreamProvider (nhanh, đồng bộ)
      var userModel = ref.read(currentUserProvider).value;

      // Cách 2: Nếu Stream chưa có dữ liệu, gọi trực tiếp Future từ Repository (chậm hơn chút nhưng chắc chắn)
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

    // Get file extension
    final extension = _getFileExtension(fileName);
    
    // Check if file supports preview
    final supportsPreview = _supportsPreview(extension);
    
    if (supportsPreview) {
      // Show preview dialog
      final shouldDownload = await _showPreviewDialog(url, fileName, extension);
      if (shouldDownload == null || !shouldDownload) {
        return; // User closed preview without downloading
      }
    }

    // Track download action in Firestore
    await ref.read(announcementControllerProvider.notifier).markAsDownloaded(
      announcementId: widget.announcementId,
      courseId: widget.courseId,
      currentUser: userModel,
    );

    // Open/download file
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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

// Add these helper methods to the class:

bool _supportsPreview(String extension) {
  final previewExtensions = ['pdf', 'doc', 'docx', 'txt'];
  return previewExtensions.contains(extension);
}

Future<bool?> _showPreviewDialog(String url, String fileName, String extension) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFF1F2937),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
            const Divider(color: Colors.grey),
            const SizedBox(height: 8),
            
            // Preview content
            Expanded(
              child: _DocumentPreviewWidget(
                url: url,
                fileName: fileName,
                extension: extension,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
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

Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSendingComment) return;

    setState(() => _isSendingComment = true);

    try {
      var userModel = ref.read(currentUserProvider).value;
      
      if (userModel == null) {
        userModel = await ref.read(authRepositoryProvider).currentUserModel;
      }

      // Kiểm tra kỹ nếu vẫn không có user
      if (userModel == null) {
        _showSnackBar('You must be logged in to comment', isError: true);
        setState(() => _isSendingComment = false); // Dừng loading
        return;
      }

      _commentController.clear();
      FocusScope.of(context).unfocus();

      // Gọi controller với userModel chắc chắn đã có dữ liệu
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
                                          '$fileSize • ${extension.toUpperCase()}',
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
class DocumentPreviewScreen extends StatefulWidget {
  final String url;
  final String fileName;
  final String fileExtension;

  const DocumentPreviewScreen({
    super.key,
    required this.url,
    required this.fileName,
    required this.fileExtension,
  });

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _htmlContent;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await http.get(Uri.parse(widget.url));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      final bytes = response.bodyBytes;

      if (widget.fileExtension == 'pdf') {
        // For PDF, just store bytes
        setState(() {
          _pdfBytes = bytes;
          _isLoading = false;
        });
      } else if (['doc', 'docx'].contains(widget.fileExtension)) {
        // For DOC/DOCX, convert to HTML using mammoth
        // Note: mammoth package for Flutter web might need special handling
        // For now, we'll show a basic text extraction
        final htmlContent = await _convertDocToHtml(bytes);
        setState(() {
          _htmlContent = htmlContent;
          _isLoading = false;
        });
      } else {
        throw Exception('Unsupported file type: ${widget.fileExtension}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<String> _convertDocToHtml(Uint8List bytes) async {
    // This is a placeholder. In a real implementation, you would:
    // 1. Use mammoth package to convert DOCX to HTML
    // 2. Or use a backend service to do the conversion
    // 3. Or use platform channels for native conversion
    
    // For now, return a message indicating preview is not available
    return '''
      <div style="padding: 20px; text-align: center;">
        <h2>Document Preview</h2>
        <p>File: ${widget.fileName}</p>
        <p>Size: ${(bytes.length / 1024).toStringAsFixed(2)} KB</p>
        <br>
        <p style="color: #666;">
          Document preview for ${widget.fileExtension.toUpperCase()} files 
          requires document conversion service.
        </p>
        <p style="color: #999; font-size: 12px;">
          Please download the file to view its contents.
        </p>
      </div>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        title: Text(
          widget.fileName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Trigger download
              Navigator.pop(context, true); // Return true to trigger download
            },
            tooltip: 'Download',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.indigo),
            SizedBox(height: 16),
            Text(
              'Loading document...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load document',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadDocument,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_htmlContent != null) {
      return Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Html(
            data: _htmlContent!,
            style: {
              "body": Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
              ),
              "h1": Style(
                fontSize: FontSize(24),
                fontWeight: FontWeight.bold,
                margin: Margins.only(bottom: 16),
              ),
              "h2": Style(
                fontSize: FontSize(20),
                fontWeight: FontWeight.bold,
                margin: Margins.only(bottom: 12),
              ),
              "p": Style(
                fontSize: FontSize(16),
                lineHeight: const LineHeight(1.6),
                margin: Margins.only(bottom: 12),
              ),
            },
          ),
        ),
      );
    }

    // For PDF preview, you would use a PDF viewer package
    // like flutter_pdfview or syncfusion_flutter_pdfviewer
    return const Center(
      child: Text(
        'PDF preview requires additional setup',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}

class _DocumentPreviewWidget extends StatefulWidget {
  final String url;
  final String fileName;
  final String extension;

  const _DocumentPreviewWidget({
    required this.url,
    required this.fileName,
    required this.extension,
  });

  @override
  State<_DocumentPreviewWidget> createState() => _DocumentPreviewWidgetState();
}

class _DocumentPreviewWidgetState extends State<_DocumentPreviewWidget> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _content;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // For DOC/DOCX, show a formatted placeholder
      // In production, you'd use a document conversion service
      if (['doc', 'docx'].contains(widget.extension)) {
        await Future.delayed(const Duration(seconds: 1)); // Simulate loading
        setState(() {
          _content = _generateDocPreviewHtml();
          _isLoading = false;
        });
      } else if (widget.extension == 'txt') {
        // For TXT files, fetch and display content
        final response = await http.get(Uri.parse(widget.url));
        if (response.statusCode == 200) {
          setState(() {
            _content = _generateTextPreviewHtml(response.body);
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load file');
        }
      } else if (widget.extension == 'pdf') {
        setState(() {
          _content = _generatePdfPreviewHtml();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _generateDocPreviewHtml() {
    return '''
      <div style="padding: 32px; text-align: center; background: white; border-radius: 8px;">
        <div style="margin-bottom: 24px;">
          <svg width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="#4F46E5" stroke-width="1.5">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
            <polyline points="14 2 14 8 20 8"></polyline>
            <line x1="16" y1="13" x2="8" y2="13"></line>
            <line x1="16" y1="17" x2="8" y2="17"></line>
            <polyline points="10 9 9 9 8 9"></polyline>
          </svg>
        </div>
        
        <h2 style="color: #1F2937; font-size: 24px; margin-bottom: 12px; font-weight: 600;">
          ${widget.fileName}
        </h2>
        
        <p style="color: #6B7280; font-size: 14px; margin-bottom: 24px;">
          ${widget.extension.toUpperCase()} Document
        </p>
        
        <div style="background: #F3F4F6; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
          <p style="color: #4B5563; font-size: 14px; line-height: 1.6; margin: 0;">
            <strong>Document Preview Information:</strong><br><br>
            This is a ${widget.extension.toUpperCase()} document. To view the full content with proper formatting,
            please download the file using the button below.<br><br>
            The document will open in your default document viewer where you can:
          </p>
          <ul style="color: #4B5563; font-size: 14px; text-align: left; margin-top: 12px; line-height: 1.8;">
            <li>View formatted text and images</li>
            <li>Navigate through pages</li>
            <li>Search for specific content</li>
            <li>Print or save a copy</li>
          </ul>
        </div>
        
        <div style="background: #EEF2FF; border-left: 4px solid #4F46E5; padding: 16px; border-radius: 4px;">
          <p style="color: #4338CA; font-size: 13px; margin: 0; text-align: left;">
            <strong>💡 Tip:</strong> Make sure you have Microsoft Word, LibreOffice, or Google Docs 
            installed to view this document.
          </p>
        </div>
      </div>
    ''';
  }

  String _generateTextPreviewHtml(String content) {
    // Escape HTML and convert line breaks
    final escapedContent = content
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('\n', '<br>');
    
    return '''
      <div style="padding: 20px; background: white; border-radius: 8px; font-family: monospace;">
        <pre style="white-space: pre-wrap; word-wrap: break-word; margin: 0; color: #1F2937; line-height: 1.6;">$escapedContent</pre>
      </div>
    ''';
  }

  String _generatePdfPreviewHtml() {
    return '''
      <div style="padding: 32px; text-align: center; background: white; border-radius: 8px;">
        <div style="margin-bottom: 24px;">
          <svg width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="#DC2626" stroke-width="1.5">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
            <polyline points="14 2 14 8 20 8"></polyline>
          </svg>
        </div>
        
        <h2 style="color: #1F2937; font-size: 24px; margin-bottom: 12px; font-weight: 600;">
          ${widget.fileName}
        </h2>
        
        <p style="color: #6B7280; font-size: 14px; margin-bottom: 24px;">
          PDF Document
        </p>
        
        <div style="background: #FEE2E2; border-left: 4px solid #DC2626; padding: 16px; border-radius: 4px; margin-bottom: 20px;">
          <p style="color: #991B1B; font-size: 13px; margin: 0; text-align: left;">
            <strong>⚠️ Note:</strong> Full PDF preview requires additional setup. 
            Please download the file to view it in your PDF reader.
          </p>
        </div>
        
        <p style="color: #6B7280; font-size: 14px; line-height: 1.6;">
          Click the download button below to save and view this PDF document.
        </p>
      </div>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.indigo),
            SizedBox(height: 16),
            Text(
              'Loading preview...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load preview',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Html(
        data: _content ?? '',
        style: {
          "body": Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
          ),
        },
      ),
    );
  }
}