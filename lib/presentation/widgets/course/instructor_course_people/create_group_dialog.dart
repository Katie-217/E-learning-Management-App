import 'package:flutter/material.dart';

/// Widget Create Group Dialog - Component tách riêng cho việc tạo nhóm mới
/// Có validation và thêm Group Code field
class CreateGroupDialog extends StatefulWidget {
  final Function(String groupName, String groupCode) onCreateGroup;

  const CreateGroupDialog({
    super.key,
    required this.onCreateGroup,
  });

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupCodeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _groupNameError;
  String? _groupCodeError;

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1F2937),
      title: const Row(
        children: [
          Icon(Icons.group_add, color: Colors.indigo, size: 24),
          SizedBox(width: 12),
          Text(
            'Create New Group',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Name Field
              const Text(
                'Group Name *',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _groupNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter group name (e.g., Group 1 - SE501.N21)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  errorText: _groupNameError,
                  errorStyle: const TextStyle(color: Colors.red),
                  prefixIcon:
                      const Icon(Icons.group, color: Colors.indigo, size: 20),
                  filled: true,
                  fillColor: const Color(0xFF374151),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Colors.indigo, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                validator: _validateGroupName,
                onChanged: (value) {
                  if (_groupNameError != null) {
                    setState(() {
                      _groupNameError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Group Code Field
              const Text(
                'Group Code *',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _groupCodeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter group code (e.g., SE501N21G1)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  errorText: _groupCodeError,
                  errorStyle: const TextStyle(color: Colors.red),
                  prefixIcon:
                      const Icon(Icons.code, color: Colors.green, size: 20),
                  filled: true,
                  fillColor: const Color(0xFF374151),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                validator: _validateGroupCode,
                onChanged: (value) {
                  if (_groupCodeError != null) {
                    setState(() {
                      _groupCodeError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Both group name and code are required. Group code should be unique.',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Cancel Button
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),

        // Create Button
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleCreateGroup,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add, size: 20),
          label: Text(_isLoading ? 'Creating...' : 'Create Group'),
        ),
      ],
    );
  }

  String? _validateGroupName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Group name is required';
    }
    if (value.trim().length < 3) {
      return 'Group name must be at least 3 characters';
    }
    if (value.trim().length > 50) {
      return 'Group name must not exceed 50 characters';
    }
    return null;
  }

  String? _validateGroupCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Group code is required';
    }
    if (value.trim().length < 2) {
      return 'Group code must be at least 2 characters';
    }
    if (value.trim().length > 20) {
      return 'Group code must not exceed 20 characters';
    }
    // Check for valid characters (alphanumeric only)
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value.trim())) {
      return 'Group code can only contain letters and numbers';
    }
    return null;
  }

  Future<void> _handleCreateGroup() async {
    // Clear previous errors
    setState(() {
      _groupNameError = null;
      _groupCodeError = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 800));

      final groupName = _groupNameController.text.trim();
      final groupCode = _groupCodeController.text.trim().toUpperCase();

      // Call the callback function
      widget.onCreateGroup(groupName, groupCode);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Group "$groupName" created successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Close dialog
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _groupNameError = 'Failed to create group. Please try again.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error: ${error.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Static method để hiển thị dialog một cách dễ dàng
  static Future<void> show(
    BuildContext context, {
    required Function(String groupName, String groupCode) onCreateGroup,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateGroupDialog(
        onCreateGroup: onCreateGroup,
      ),
    );
  }
}
