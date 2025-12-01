import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../application/controllers/announcement/announcement_provider.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_repository.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/announcement_tab_widget/announcement_attachment_handler.dart';
import 'group_selector_widget.dart';
import 'rich_text_editor_widget.dart';

/// Provider to fetch groups for a course
final courseGroupsProvider = FutureProvider.family<List<String>, String>((ref, courseId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('courses')
      .doc(courseId)
      .collection('groups')
      .get();
  
  return snapshot.docs.map((doc) => doc.data()['name'] as String? ?? doc.id).toList();
});

class SimpleCreateAnnouncementDialog extends ConsumerStatefulWidget {
  final String courseId;
  final String? announcementId;
  final String? initialTitle;
  final String? initialContent;
  final List<Map<String, dynamic>>? initialAttachments;
  final List<String>? initialTargetGroupIds;

  const SimpleCreateAnnouncementDialog({
    super.key,
    required this.courseId,
    this.announcementId,
    this.initialTitle,
    this.initialContent,
    this.initialAttachments,
    this.initialTargetGroupIds,
  });

  @override
  ConsumerState<SimpleCreateAnnouncementDialog> createState() => 
      _SimpleCreateAnnouncementDialogState();
}

class _SimpleCreateAnnouncementDialogState 
    extends ConsumerState<SimpleCreateAnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  
  // File attachments
  List<PlatformFile> _selectedFiles = [];
  List<Map<String, dynamic>> _uploadedFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  
  // Group selection
  List<String> _targetGroupIds = [];

  bool get isEditing => widget.announcementId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
    _uploadedFiles = widget.initialAttachments ?? [];
    _targetGroupIds = widget.initialTargetGroupIds ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ========================================
  // FILE HANDLING
  // ========================================
  
  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png', 'zip'],
      );
      
      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      _showError('Error picking files: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _removeUploadedFile(int index) {
    setState(() {
      _uploadedFiles.removeAt(index);
    });
  }

  // ========================================
  // SUBMIT LOGIC
  // ========================================
  
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final currentUser = await ref.read(authRepositoryProvider).currentUserModel;
      if (currentUser == null) throw Exception('User not authenticated');

      // 1. Upload new files if any
      if (_selectedFiles.isNotEmpty) {
        final handler = ref.read(attachmentHandlerProvider);
        final uploaded = await handler.uploadFiles(
          files: _selectedFiles,
          courseId: widget.courseId,
          announcementId: widget.announcementId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
          onProgress: (progress) {
            setState(() => _uploadProgress = progress);
          },
        );
        _uploadedFiles.addAll(uploaded);
      }

      // 2. Submit to repository (WITHOUT isPinned)
      final notifier = ref.read(announcementControllerProvider.notifier);
      final bool success;

      if (isEditing) {
        success = await notifier.updateAnnouncement(
          courseId: widget.courseId,
          announcementId: widget.announcementId!,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          attachments: _uploadedFiles,
          targetGroupIds: _targetGroupIds,
        );
      } else {
        success = await notifier.createAnnouncement(
          courseId: widget.courseId,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          currentUser: currentUser,
          attachments: _uploadedFiles,
          targetGroupIds: _targetGroupIds,
        );
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing 
                ? 'Announcement updated successfully!' 
                : 'Announcement posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // ========================================
  // BUILD UI
  // ========================================
  
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementControllerProvider);
    final groupsAsync = ref.watch(courseGroupsProvider(widget.courseId));
    final isLoading = state.isLoading || _isUploading;

    return Dialog(
      backgroundColor: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.campaign, color: Colors.indigo[400], size: 28),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'Edit Announcement' : 'New Announcement',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Field
                        TextFormField(
                          controller: _titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Title *',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            hintText: 'Enter announcement title',
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
                          ),
                          validator: (value) => 
                              value == null || value.trim().isEmpty 
                                  ? 'Title is required' 
                                  : null,
                        ),
                        const SizedBox(height: 20),

                        // Rich-Text Content Editor
                        RichTextEditorWidget(
                          controller: _contentController,
                          label: 'Content *',
                          hint: 'Write your announcement content...\n\nYou can use **bold**, *italic*, # headings, and more!',
                          maxLines: 10,
                          validator: (value) => 
                              value == null || value.trim().isEmpty 
                                  ? 'Content is required' 
                                  : null,
                        ),
                        const SizedBox(height: 20),

                        // Group Selector
                        groupsAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (err, stack) => Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Text(
                              'Error loading groups: $err',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          data: (groups) {
                            if (groups.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.orange[400]),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'No groups found in this course. Announcement will be visible to all students.',
                                        style: TextStyle(color: Colors.orange),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return GroupSelectorWidget(
                              availableGroups: groups,
                              selectedGroups: _targetGroupIds,
                              onSelectionChanged: (selected) {
                                setState(() {
                                  _targetGroupIds = selected;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // File Attachments Section
                        _buildFileSection(),
                        
                        // Upload Progress
                        if (_isUploading) ...[
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: _uploadProgress,
                            backgroundColor: Colors.grey[700],
                            color: Colors.indigo,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Uploading files... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        disabledBackgroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
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
                                  isEditing ? Icons.save : Icons.send,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isEditing ? 'Save Changes' : 'Post Announcement',
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
    );
  }

  // ========================================
  // FILE SECTION WIDGET
  // ========================================
  
  Widget _buildFileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.attach_file, color: Colors.indigo[400], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Attachments (Optional)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _isUploading ? null : _pickFiles,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Files'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Supported: PDF, DOC, DOCX, PPT, PPTX, JPG, PNG, ZIP',
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
          const SizedBox(height: 12),
          
          if (_selectedFiles.isNotEmpty) ...[
            const Text(
              'Selected Files:',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ..._selectedFiles.asMap().entries.map((entry) {
              final file = entry.value;
              return _FileItem(
                fileName: file.name,
                fileSize: _formatBytes(file.size),
                isUploaded: false,
                onRemove: () => _removeFile(entry.key),
              );
            }),
          ],
          
          if (_uploadedFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Uploaded Files:',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ..._uploadedFiles.asMap().entries.map((entry) {
              final file = entry.value;
              return _FileItem(
                fileName: file['name'] ?? 'Unknown',
                fileSize: _formatBytes(file['sizeInBytes'] ?? 0),
                isUploaded: true,
                onRemove: () => _removeUploadedFile(entry.key),
              );
            }),
          ],
          
          if (_selectedFiles.isEmpty && _uploadedFiles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No files attached',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ========================================
// FILE ITEM WIDGET
// ========================================

class _FileItem extends StatelessWidget {
  final String fileName;
  final String fileSize;
  final bool isUploaded;
  final VoidCallback onRemove;

  const _FileItem({
    required this.fileName,
    required this.fileSize,
    this.isUploaded = false,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isUploaded ? Colors.green.withOpacity(0.3) : Colors.grey[800]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(fileName),
            color: isUploaded ? Colors.green[400] : Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      fileSize,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                    if (isUploaded) ...[
                      Text(
                        ' • ',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      Text(
                        'Uploaded',
                        style: TextStyle(
                          color: Colors.green[400],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18),
            color: Colors.grey[400],
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'zip':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }
}