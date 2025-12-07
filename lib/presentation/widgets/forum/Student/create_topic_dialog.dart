// ========================================
// FILE: create_topic_dialog.dart
// MÔ TẢ: Dialog tạo topic mới trong forum
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:ui' as ui;
import 'package:elearning_management_app/application/controllers/forum/forum_provider.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_repository.dart';
import '../../../../core/services/file_upload_service.dart';
class CreateTopicDialog extends ConsumerStatefulWidget {
  final String courseId;
  final String? topicId; // For editing
  final String? initialTitle;
  final String? initialContent;

  const CreateTopicDialog({
    super.key,
    required this.courseId,
    this.topicId,
    this.initialTitle,
    this.initialContent,
  });

  @override
  ConsumerState<CreateTopicDialog> createState() => _CreateTopicDialogState();
}

class _CreateTopicDialogState extends ConsumerState<CreateTopicDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isSubmitting = false;
  
  // 1. Biến lưu danh sách file đã chọn
  List<PlatformFile> _selectedFiles = [];

  bool get isEditing => widget.topicId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 2. Hàm chọn file - chỉ cho phép PDF, Word, PNG
  Future<void> _pickFiles() async {
    final uploadService = ref.read(fileUploadServiceProvider);
    try {
      final files = await uploadService.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png'],
      );
      if (files != null) {
        setState(() {
          _selectedFiles.addAll(files);
        });
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  // 3. Hàm xóa file khỏi danh sách chọn
  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  // 4. Hàm xử lý file được kéo thả vào
  bool _isValidFileType(String fileName) {
    final lowerName = fileName.toLowerCase();
    return lowerName.endsWith('.pdf') ||
        lowerName.endsWith('.doc') ||
        lowerName.endsWith('.docx') ||
        lowerName.endsWith('.png');
  }

  // 5. Hàm xử lý file được kéo thả vào (từ DragTarget hoặc HTML5 drag and drop)
  Future<void> _handleDroppedFiles(List<PlatformFile> files) async {
    final validFiles = files.where((file) => _isValidFileType(file.name)).toList();
    
    if (validFiles.isEmpty) {
      _showError('Chỉ chấp nhận file PDF, DOC, DOCX, PNG');
      return;
    }

    if (files.length != validFiles.length) {
      _showError('Một số file không được hỗ trợ. Đã thêm ${validFiles.length}/${files.length} file hợp lệ.');
    }

    setState(() {
      _selectedFiles.addAll(validFiles);
    });
  }


  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = await ref.read(authRepositoryProvider).currentUserModel;
      if (currentUser == null) {
        _showError('You must be logged in');
        return;
      }

      final notifier = ref.read(forumControllerProvider.notifier);
      
      // 4. Upload file trước khi tạo topic
      List<String> attachmentUrls = [];
      if (_selectedFiles.isNotEmpty) {
        final uploadService = ref.read(fileUploadServiceProvider);
        // Upload vào folder theo courseId
        attachmentUrls = await uploadService.uploadMultipleFiles(
          files: _selectedFiles,
          folder: 'forum_topics/${widget.courseId}',
        );
      }

      final bool success;

      if (isEditing) {
        // Logic Update (Tạm thời giữ nguyên, chưa hỗ trợ thêm file khi edit)
        success = await notifier.updateTopic(
          courseId: widget.courseId,
          topicId: widget.topicId!,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        );
      } else {
        // Logic Create: Truyền thêm attachmentUrls
        success = await notifier.createTopic(
          courseId: widget.courseId,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          currentUser: currentUser,
          attachments: attachmentUrls, // <--- QUAN TRỌNG
        );
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing 
                  ? 'Topic updated successfully!' 
                  : 'Topic created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        _showError('Failed to ${isEditing ? 'update' : 'create'} topic');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView( // Thêm ScrollView để tránh lỗi overflow khi hiện file
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.topic, color: Colors.indigo[400], size: 28),
                      const SizedBox(width: 12),
                      Text(
                        isEditing ? 'Edit Topic' : 'Create New Topic',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    enabled: !_isSubmitting,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Topic Title *',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      hintText: 'Enter a clear, descriptive title',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[700]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.indigo, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[800]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) => 
                        value == null || value.trim().isEmpty 
                            ? 'Title is required' 
                            : null,
                  ),
                  const SizedBox(height: 20),

                  // Content Field
                  TextFormField(
                    controller: _contentController,
                    enabled: !_isSubmitting,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 5, // Giảm bớt số dòng để dành chỗ cho file
                    decoration: InputDecoration(
                      labelText: 'Content *',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      alignLabelWithHint: true,
                      hintText: 'Describe your question or topic in detail...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[700]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.indigo, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[800]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) => 
                        value == null || value.trim().isEmpty 
                            ? 'Content is required' 
                            : null,
                  ),
                  
                  const SizedBox(height: 24),

                  // File Attachment Section
                  if (_selectedFiles.isEmpty)
                    // Old design: Simple button when no files
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _pickFiles,
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: const Text('Add File'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo[400],
                        side: BorderSide(color: Colors.grey[700]!),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    )
                  else
                    // New design: File cards with dashed border button when files exist
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // File count label
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '${_selectedFiles.length} file${_selectedFiles.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        // Files and Add button row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Display selected files
                              ...List.generate(_selectedFiles.length, (index) {
                                final file = _selectedFiles[index];
                                final fileName = file.name.toLowerCase();
                                final isPng = fileName.endsWith('.png');
                                final isPdf = fileName.endsWith('.pdf');
                                final isWord = fileName.endsWith('.doc') || fileName.endsWith('.docx');
                                
                                // Determine icon and color by file type
                                IconData fileIcon;
                                Color iconColor;
                                String fileTypeLabel;
                                if (isPng) {
                                  fileIcon = Icons.image;
                                  iconColor = Colors.green;
                                  fileTypeLabel = 'PNG';
                                } else if (isPdf) {
                                  fileIcon = Icons.picture_as_pdf;
                                  iconColor = Colors.red;
                                  fileTypeLabel = 'PDF';
                                } else if (isWord) {
                                  fileIcon = Icons.description;
                                  iconColor = Colors.blue;
                                  fileTypeLabel = 'DOC';
                                } else {
                                  fileIcon = Icons.insert_drive_file;
                                  iconColor = Colors.grey;
                                  fileTypeLabel = 'FILE';
                                }
                                
                                return Padding(
                                  padding: EdgeInsets.only(right: index < _selectedFiles.length - 1 ? 12 : 12),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF374151),
                                          borderRadius: BorderRadius.circular(8),
                                          image: (isPng && file.bytes != null)
                                              ? DecorationImage(
                                                  image: MemoryImage(file.bytes!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: isPng && file.bytes != null
                                            ? null
                                            : Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: iconColor,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      fileTypeLabel,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                                    child: Text(
                                                      file.name.length > 12
                                                          ? '${file.name.substring(0, 12)}...'
                                                          : file.name,
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 11,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                      // Remove button
                                      Positioned(
                                        right: 4,
                                        top: 4,
                                        child: InkWell(
                                          onTap: () => _removeFile(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              
                              // Add file button with dashed border
                              InkWell(
                                onTap: _isSubmitting ? null : _pickFiles,
                                child: _DashedBorder(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[600]!,
                                  strokeWidth: 2,
                                  dashPattern: [5, 5],
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF374151),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 32,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          disabledBackgroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isEditing ? Icons.save : Icons.add_circle,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEditing ? 'Save Changes' : 'Create Topic',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom widget for dashed border
class _DashedBorder extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final Color color;
  final double strokeWidth;
  final List<int> dashPattern;

  const _DashedBorder({
    required this.child,
    required this.width,
    required this.height,
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashPattern: dashPattern,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<int> dashPattern;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ));

    final dashLength = dashPattern[0].toDouble();
    final dashSpace = dashPattern[1].toDouble();
    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      double distance = 0;
      while (distance < pathMetric.length) {
        final extractPath = pathMetric.extractPath(
          distance,
          distance + dashLength,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashLength + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}