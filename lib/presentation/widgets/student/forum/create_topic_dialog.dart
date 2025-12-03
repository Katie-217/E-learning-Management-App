// ========================================
// FILE: create_topic_dialog.dart
// MÔ TẢ: Dialog tạo topic mới trong forum
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/application/controllers/forum/forum_provider.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_repository.dart';

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
      final bool success;

      if (isEditing) {
        success = await notifier.updateTopic(
          courseId: widget.courseId,
          topicId: widget.topicId!,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        );
      } else {
        success = await notifier.createTopic(
          courseId: widget.courseId,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          currentUser: currentUser,
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
                  maxLines: 8,
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
    );
  }
}