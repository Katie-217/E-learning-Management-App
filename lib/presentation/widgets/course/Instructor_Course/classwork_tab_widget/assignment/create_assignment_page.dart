import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // For PlatformFile
import 'package:url_launcher/url_launcher.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/data/repositories/group/group_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/application/controllers/assignment/assignment_controller.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:intl/intl.dart';
import 'choose_group_create.dart';
import 'add_link_assignments.dart';
import 'upload_file_assignment.dart';
import 'file_preview_overlay.dart';

class CreateAssignmentPage extends ConsumerStatefulWidget {
  final CourseModel? course;
  final Assignment? existingAssignment; // For Edit mode

  const CreateAssignmentPage({
    super.key,
    this.course,
    this.existingAssignment,
  }) : assert(course != null || existingAssignment != null,
            'Either course or existingAssignment must be provided');

  @override
  ConsumerState<CreateAssignmentPage> createState() =>
      _CreateAssignmentPageState();
}

class _CreateAssignmentPageState extends ConsumerState<CreateAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _pointsController = TextEditingController(text: '100');
  final _maxAttemptsController = TextEditingController(text: '1');
  final _fileFormatController =
      TextEditingController(text: '.pdf, .docx, .zip');
  final _sizeLimitController = TextEditingController(text: '10');

  List<String> _selectedGroups = [];
  List<String> _availableGroups = [];
  bool _isLoadingGroups = true;
  bool _isLoadingEditData = false; // NEW: Track edit data loading
  List<LinkMetadata> _attachedLinks = []; // Store attached links
  List<UploadedFileModel> _uploadedFiles =
      []; // Store uploaded files (with Firebase URLs)
  Map<String, double> _uploadProgress =
      {}; // Track upload progress by file name
  bool _isPublished = false; // Track if assignment was successfully published
  DateTime? _scheduleDate;
  TimeOfDay? _scheduleTime;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _allowLateSubmission = false;
  DateTime? _lateDeadline;
  TimeOfDay? _lateDeadlineTime;

  @override
  void initState() {
    super.initState();
    _loadGroups();
    if (widget.existingAssignment != null) {
      _initializeEditMode(); // This sets _isLoadingEditData
    }
  }

  /// Initialize form with existing assignment data if in Edit mode
  void _initializeEditMode() async {
    final assignment = widget.existingAssignment;
    if (assignment == null) return;

    setState(() {
      _isLoadingEditData = true;
    });

    // Populate form fields
    _titleController.text = assignment.title;
    _instructionsController.text = assignment.description;
    _pointsController.text = assignment.maxPoints.toString();
    _maxAttemptsController.text = assignment.maxSubmissionAttempts.toString();
    _fileFormatController.text = assignment.allowedFileFormats.join(', ');
    _sizeLimitController.text = assignment.maxFileSizeMB.toString();

    // Set dates
    _scheduleDate = assignment.createdAt;
    _scheduleTime = TimeOfDay.fromDateTime(assignment.createdAt);
    _dueDate = assignment.deadline;
    _dueTime = TimeOfDay.fromDateTime(assignment.deadline);

    // Set late submission settings
    _allowLateSubmission = assignment.allowLateSubmissions;
    if (assignment.lateDeadline != null) {
      _lateDeadline = assignment.lateDeadline;
      _lateDeadlineTime = TimeOfDay.fromDateTime(assignment.lateDeadline!);
    }

    // Map Group IDs to Group Names for UI display and checkbox state
    await _loadGroupNamesFromIds(assignment.groupIds);

    // Load attachments
    _loadExistingAttachments(assignment);

    // Mark loading complete
    setState(() {
      _isLoadingEditData = false;
    });
  }

  /// Convert Group IDs to Group Names for Edit mode
  Future<void> _loadGroupNamesFromIds(List<String> groupIds) async {
    try {
      final courseId = widget.course?.id ?? widget.existingAssignment?.courseId;
      if (courseId == null) return;

      final allGroups = await GroupRepository.getGroupsByCourse(courseId);

      // Check if all groups are selected
      if (groupIds.length == allGroups.length) {
        setState(() {
          _selectedGroups = ['All Groups'];
        });
      } else {
        // Map group IDs to group names
        final selectedGroupNames = <String>[];
        for (var groupId in groupIds) {
          final group = allGroups.firstWhere(
            (g) => g.id == groupId,
            orElse: () => throw Exception('Group not found: $groupId'),
          );
          selectedGroupNames.add(group.name);
        }

        setState(() {
          _selectedGroups = selectedGroupNames;
        });
      }
    } catch (e) {
      print('Error loading group names: $e');
    }
  }

  /// Load existing attachments from assignment
  void _loadExistingAttachments(Assignment assignment) {
    for (var attachment in assignment.attachments) {
      if (attachment['type'] == 'link') {
        _attachedLinks.add(LinkMetadata(
          url: attachment['url'] ?? '',
          title: attachment['title'] ?? attachment['name'] ?? 'Untitled',
          imageUrl: attachment['imageUrl'],
          description: attachment['description'],
          domain: attachment['domain'] ?? '',
        ));
      } else {
        // File attachment
        final fileName =
            attachment['name'] ?? attachment['fileName'] ?? 'Untitled';
        final fileUrl = attachment['url'] ?? '';

        // Extract file extension from fileName
        String fileExtension = '';
        if (fileName.contains('.')) {
          fileExtension = fileName.substring(fileName.lastIndexOf('.'));
        }

        _uploadedFiles.add(UploadedFileModel(
          fileName: fileName,
          filePath: fileUrl,
          fileSizeBytes: attachment['size'] ?? attachment['fileSize'] ?? 0,
          fileExtension:
              fileExtension, // Use extracted extension, not 'file' type
          fileBytes: null,
          platformFile: PlatformFile(
            name: fileName,
            size: attachment['size'] ?? 0,
            path: fileUrl,
          ),
        ));
      }
    }
  }

  Future<void> _loadGroups() async {
    try {
      setState(() => _isLoadingGroups = true);

      final courseId = widget.course?.id ?? widget.existingAssignment?.courseId;
      if (courseId == null) {
        throw Exception('No course ID available');
      }

      final groups = await GroupRepository.getGroupsByCourse(courseId);
      final groupNames = groups.map((g) => g.name).toList();

      setState(() {
        _availableGroups = ['All Groups', ...groupNames];
        _isLoadingGroups = false;
      });
    } catch (e) {
      print('Error loading groups: $e');
      setState(() {
        _availableGroups = ['All Groups']; // Fallback
        _isLoadingGroups = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _pointsController.dispose();
    _maxAttemptsController.dispose();
    _fileFormatController.dispose();
    _sizeLimitController.dispose();
    super.dispose();
  }

  /// Check if any files are still uploading
  bool _hasUploadingFiles() {
    for (var file in _uploadedFiles) {
      final progress = _uploadProgress[file.fileName] ?? 1.0;
      if (progress < 1.0) {
        return true;
      }
    }
    return false;
  }

  /// Cleanup uploaded files from Firebase Storage when canceling without publishing
  Future<void> _cleanupUploadedFiles() async {
    try {
      // IMPORTANT: Do NOT cleanup files if:
      // 1. Assignment was successfully published (_isPublished = true)
      // 2. We are in EDIT mode (existingAssignment != null)
      //    - In edit mode, files belong to existing assignment and should NOT be deleted
      if (_isPublished || widget.existingAssignment != null) {
        print(
            'ℹ️ Skipping cleanup: ${_isPublished ? "Published" : "Edit Mode"}');
        return;
      }

      // Delete all uploaded files from Firebase Storage (CREATE mode only)
      final filesToDelete = _uploadedFiles
          .where(
            (file) => file.filePath.startsWith('https://'),
          )
          .toList();

      if (filesToDelete.isEmpty) return;

      print(
          '🗑️ Cleaning up ${filesToDelete.length} uploaded files (CREATE mode cancelled)...');

      for (var file in filesToDelete) {
        try {
          await FileUploadService.deleteFileFromFirebase(file.filePath);
          print('  ✅ Deleted: ${file.fileName}');
        } catch (e) {
          print('  ❌ Failed to delete ${file.fileName}: $e');
        }
      }

      print('✅ Cleanup completed');
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while loading edit data
    if (_isLoadingEditData) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          title: Text(
            widget.existingAssignment != null
                ? 'Edit Assignment'
                : 'Create Assignment',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
              ),
              SizedBox(height: 16),
              Text(
                'Loading assignment data...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false, // Prevent immediate pop
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Cleanup uploaded files before exit
        await _cleanupUploadedFiles();

        // Now pop the page
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              // Cleanup uploaded files before closing
              await _cleanupUploadedFiles();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            widget.existingAssignment != null
                ? 'Edit Assignment'
                : 'Create Assignment',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          actions: [
            // Split Button: Publish + Dropdown for Save Draft
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.indigo[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main Publish Button (wider)
                    InkWell(
                      onTap: _hasUploadingFiles() ? null : _publishAssignment,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      child: Opacity(
                        opacity: _hasUploadingFiles() ? 0.5 : 1.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.send,
                                  size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                widget.existingAssignment != null
                                    ? 'Save'
                                    : 'Publish',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Divider
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.indigo[400],
                    ),
                    // Dropdown Button (narrower)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.white, size: 20),
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[800]!),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      offset: const Offset(0, 45),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'draft',
                          child: Row(
                            children: [
                              Icon(Icons.save_outlined,
                                  size: 18, color: Colors.grey[400]),
                              const SizedBox(width: 12),
                              const Text(
                                'Save Draft',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'draft') {
                          _saveAsDraft();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsive breakpoint: if width < 800px, stack vertically
              final isWideScreen = constraints.maxWidth >= 800;

              if (isWideScreen) {
                // Wide screen: 2 columns (70/30 split)
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column - Main Content (70%)
                    Expanded(
                      flex: 7,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMainContentSection(),
                          ],
                        ),
                      ),
                    ),

                    // Right Column - Configuration (30%)
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          border: Border(
                            left:
                                BorderSide(color: Colors.grey[800]!, width: 1),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildConfigurationSection(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Narrow screen: Single column layout
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainContentSection(),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: _buildConfigurationSection(),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ), // Close Scaffold
    ); // Close PopScope
  }

  Widget _buildMainContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        _buildSectionTitle('Title', required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: 'Assignment title',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.indigo, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Title is required';
            }
            return null;
          },
        ),

        const SizedBox(height: 24),

        // Instructions
        _buildSectionTitle('Instructions'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _instructionsController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 8,
          decoration: InputDecoration(
            hintText: 'Provide detailed instructions for this assignment...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.indigo, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Attachments
        _buildSectionTitle('Attachments'),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildAttachmentButton(
              icon: Icons.upload_file,
              label: 'Upload File',
              onTap: () async {
                final files = await FileUploadService.pickFiles();
                if (files.isNotEmpty) {
                  for (var file in files) {
                    // ALL FILES: Upload immediately to Firebase Storage
                    // This provides consistent UI with loading indicator
                    // Office files: Need URL for Google Docs Viewer preview
                    // PDF/Text/Image: Need URL for storage, but preview uses native viewers
                    try {
                      setState(() {
                        _uploadProgress[file.fileName] = 0.0;
                        _uploadedFiles.add(file);
                      });

                      final uploadedFile =
                          await FileUploadService.uploadFileImmediately(
                        file: file,
                        courseId: widget.course?.id ??
                            widget.existingAssignment?.courseId ??
                            '',
                        folderName:
                            'assignments', // Assignment files → 'assignments' folder
                        onProgress: (progress) {
                          if (mounted) {
                            setState(() {
                              _uploadProgress[file.fileName] = progress;
                            });
                          }
                        },
                      );

                      if (mounted) {
                        setState(() {
                          final index = _uploadedFiles
                              .indexWhere((f) => f.fileName == file.fileName);
                          if (index != -1) {
                            _uploadedFiles[index] = uploadedFile;
                          }
                          _uploadProgress[file.fileName] = 1.0;
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _uploadedFiles
                              .removeWhere((f) => f.fileName == file.fileName);
                          _uploadProgress.remove(file.fileName);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('❌ Failed to upload ${file.fileName}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  }
                }
              },
            ),
            const SizedBox(width: 12),
            _buildAttachmentButton(
              icon: Icons.link,
              label: 'Insert Link',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AddLinkDialog(
                    onLinkAdded: (metadata) {
                      setState(() {
                        _attachedLinks.add(metadata);
                      });
                    },
                  ),
                );
              },
            ),
          ],
        ),

        // Display Uploaded Files
        if (_uploadedFiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...List.generate(
            _uploadedFiles.length,
            (index) {
              final file = _uploadedFiles[index];
              final progress = _uploadProgress[file.fileName] ?? 1.0;
              final isUploading = progress < 1.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Stack(
                  children: [
                    FilePreviewCard(
                      file: file,
                      onRemove: () async {
                        final file = _uploadedFiles[index];

                        // If file has Firebase URL, delete from Storage
                        if (file.filePath.startsWith('https://')) {
                          try {
                            await FileUploadService.deleteFileFromFirebase(
                                file.filePath);
                          } catch (e) {
                            print('Error deleting file from Firebase: $e');
                          }
                        }

                        // Remove from UI
                        setState(() {
                          _uploadProgress.remove(file.fileName);
                          _uploadedFiles.removeAt(index);
                        });
                      },
                      onTap: () async {
                        // Only allow preview if file is fully uploaded
                        final fileName = _uploadedFiles[index].fileName;
                        final progress = _uploadProgress[fileName] ?? 1.0;

                        if (progress >= 1.0) {
                          // Always open FilePreviewOverlay for all platforms and file types
                          // Banner will show inside overlay for Desktop Office files
                          FilePreviewOverlay.show(
                            context,
                            _uploadedFiles,
                            initialIndex: index,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Please wait, uploading ${(progress * 100).toStringAsFixed(0)}%...'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    // Upload progress overlay - Full overlay with percentage
                    if (isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.indigo,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Uploading... ${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 200,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.indigo,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],

        // Display Attached Links
        if (_attachedLinks.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...List.generate(
            _attachedLinks.length,
            (index) => LinkPreviewCard(
              metadata: _attachedLinks[index],
              onRemove: () {
                setState(() {
                  _attachedLinks.removeAt(index);
                });
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConfigurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configuration',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        // Assign to Groups
        _buildSectionTitle('Assign to', required: true),
        const SizedBox(height: 8),
        _isLoadingGroups
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                  ),
                ),
              )
            : ChooseGroupCreate(
                availableGroups: _availableGroups,
                selectedGroups: _selectedGroups,
                onSelectionChanged: (selected) {
                  setState(() {
                    _selectedGroups = selected;
                  });
                },
              ),

        const SizedBox(height: 24),

        // Points
        _buildSectionTitle('Points'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _pointsController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Enter points'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Points required';
            }
            if (double.tryParse(value) == null) {
              return 'Enter valid number';
            }
            return null;
          },
        ),

        const SizedBox(height: 24),

        // Schedule
        _buildSectionTitle('Schedule', required: true),
        const SizedBox(height: 8),
        _buildDateTimePicker(
          label: 'Start Date & Time',
          date: _scheduleDate,
          time: _scheduleTime,
          onDateSelected: (date) => setState(() => _scheduleDate = date),
          onTimeSelected: (time) => setState(() => _scheduleTime = time),
        ),

        const SizedBox(height: 24),

        // Due Date
        _buildSectionTitle('Due Date', required: true),
        const SizedBox(height: 8),
        _buildDateTimePicker(
          label: 'Due Date & Time',
          date: _dueDate,
          time: _dueTime,
          onDateSelected: (date) => setState(() => _dueDate = date),
          onTimeSelected: (time) => setState(() => _dueTime = time),
        ),

        const SizedBox(height: 24),

        // Late Submission
        Row(
          children: [
            Checkbox(
              value: _allowLateSubmission,
              onChanged: (value) {
                setState(() => _allowLateSubmission = value ?? false);
              },
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.indigo;
                }
                return Colors.grey[700];
              }),
            ),
            const Text(
              'Allow late submissions',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),

        if (_allowLateSubmission) ...[
          const SizedBox(height: 12),
          _buildDateTimePicker(
            label: 'Late Deadline',
            date: _lateDeadline,
            time: _lateDeadlineTime,
            onDateSelected: (date) => setState(() => _lateDeadline = date),
            onTimeSelected: (time) => setState(() => _lateDeadlineTime = time),
          ),
        ],

        const SizedBox(height: 24),

        // Submission Settings
        const Text(
          'Submission Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionTitle('Max Attempts'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _maxAttemptsController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Number of attempts'),
        ),

        const SizedBox(height: 16),

        _buildSectionTitle('File Format'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fileFormatController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('e.g., .pdf, .docx, .zip'),
        ),

        const SizedBox(height: 16),

        _buildSectionTitle('Size Limit (MB)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _sizeLimitController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Maximum file size'),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? date,
    required TimeOfDay? time,
    required Function(DateTime) onDateSelected,
    required Function(TimeOfDay) onTimeSelected,
  }) {
    return Container(
      width: double.infinity, // Full width
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              // If width is enough for 2 buttons side by side (> 350px), use Row
              // Otherwise, stack them vertically with full width
              final canFitSideBySide = constraints.maxWidth > 350;

              if (canFitSideBySide) {
                // Wide enough: Display side by side (50-50 split)
                return Row(
                  children: [
                    Expanded(
                      child: _buildDateButton(
                        icon: Icons.calendar_today,
                        label: date != null
                            ? DateFormat('MMM dd, yyyy').format(date)
                            : 'Select date',
                        hasValue: date != null,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Colors.indigo,
                                    surface: Color(0xFF1E293B),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            onDateSelected(picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateButton(
                        icon: Icons.access_time,
                        label:
                            time != null ? time.format(context) : 'Select time',
                        hasValue: time != null,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: time ?? TimeOfDay.now(),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Colors.indigo,
                                    surface: Color(0xFF1E293B),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            onTimeSelected(picked);
                          }
                        },
                      ),
                    ),
                  ],
                );
              } else {
                // Narrow: Stack vertically with full width
                return Column(
                  children: [
                    _buildDateButton(
                      icon: Icons.calendar_today,
                      label: date != null
                          ? DateFormat('MMM dd, yyyy').format(date)
                          : 'Select date',
                      hasValue: date != null,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Colors.indigo,
                                  surface: Color(0xFF1E293B),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          onDateSelected(picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDateButton(
                      icon: Icons.access_time,
                      label:
                          time != null ? time.format(context) : 'Select time',
                      hasValue: time != null,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: time ?? TimeOfDay.now(),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Colors.indigo,
                                  surface: Color(0xFF1E293B),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          onTimeSelected(picked);
                        }
                      },
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.indigo, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool required = false}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(color: Colors.red, fontSize: 14),
          ),
        ],
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[800]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[800]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.indigo, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  void _saveAsDraft() {
    // TODO: Implement save as draft
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Assignment saved as draft!')),
    );
  }

  void _publishAssignment() async {
    if (_formKey.currentState!.validate()) {
      // Check if any files are still uploading
      if (_hasUploadingFiles()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏳ Please wait for all files to finish uploading'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      if (_selectedGroups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one group')),
        );
        return;
      }

      if (_scheduleDate == null || _scheduleTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please set schedule date and time')),
        );
        return;
      }

      if (_dueDate == null || _dueTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please set due date and time')),
        );
        return;
      }

      try {
        // Show loading indicator immediately
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Combine date and time
        final startDateTime = DateTime(
          _scheduleDate!.year,
          _scheduleDate!.month,
          _scheduleDate!.day,
          _scheduleTime!.hour,
          _scheduleTime!.minute,
        );

        final dueDateTime = DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          _dueTime!.hour,
          _dueTime!.minute,
        );

        DateTime? lateDateTime;
        if (_allowLateSubmission &&
            _lateDeadline != null &&
            _lateDeadlineTime != null) {
          lateDateTime = DateTime(
            _lateDeadline!.year,
            _lateDeadline!.month,
            _lateDeadline!.day,
            _lateDeadlineTime!.hour,
            _lateDeadlineTime!.minute,
          );
        }

        // Convert uploaded files and links to attachments format
        final attachments = <Map<String, dynamic>>[];

        // All files should be uploaded to Firebase Storage at this point
        for (var file in _uploadedFiles) {
          if (file.filePath.startsWith('http')) {
            attachments.add({
              'type': 'file',
              'name': file.fileName,
              'fileName': file.fileName,
              'url': file.filePath, // Firebase Storage URL
              'size': file.fileSizeBytes,
              'fileSize': file.fileSizeBytes,
              'fileType': file.fileExtension,
            });
          } else {
            // This shouldn't happen - all files should be uploaded
            print('❌ Error: File ${file.fileName} not uploaded yet');
            if (mounted) {
              Navigator.of(context).pop(); // Close loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'File ${file.fileName} is not uploaded yet. Please wait.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        // Add links
        for (var link in _attachedLinks) {
          attachments.add({
            'type': 'link',
            'name': link.title,
            'url': link.url,
            'title': link.title,
            'imageUrl': link.imageUrl,
            'domain': link.domain,
          });
        }

        // Get group IDs from selected group names
        final courseId =
            widget.course?.id ?? widget.existingAssignment?.courseId;
        if (courseId == null) {
          throw Exception('No course ID available');
        }

        final allGroups = await GroupRepository.getGroupsByCourse(courseId);
        final selectedGroupIds = <String>[];

        if (_selectedGroups.contains('All Groups')) {
          // If "All Groups" is selected, add all group IDs
          selectedGroupIds.addAll(allGroups.map((g) => g.id));
        } else {
          // Otherwise, map selected names to IDs
          for (var selectedName in _selectedGroups) {
            final group = allGroups.firstWhere((g) => g.name == selectedName);
            selectedGroupIds.add(group.id);
          }
        }

        // Parse allowed file formats
        final allowedFormats = _fileFormatController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        // Determine semester ID
        final semesterId = widget.course?.semester ??
            widget.existingAssignment?.semesterId ??
            '';

        // Create or Update assignment object
        final assignment = Assignment(
          id: widget.existingAssignment?.id ??
              '', // Use existing ID for update, empty for create
          courseId: courseId,
          semesterId: semesterId,
          title: _titleController.text.trim(),
          description: _instructionsController.text.trim(),
          startDate: startDateTime,
          deadline: dueDateTime,
          allowLateSubmissions: _allowLateSubmission,
          lateDeadline: lateDateTime,
          maxSubmissionAttempts: int.tryParse(_maxAttemptsController.text) ?? 1,
          allowedFileFormats: allowedFormats,
          maxFileSizeMB: int.tryParse(_sizeLimitController.text) ?? 10,
          attachments: attachments,
          groupIds: selectedGroupIds,
          createdAt: widget.existingAssignment?.createdAt ?? DateTime.now(),
          maxPoints: double.tryParse(_pointsController.text) ?? 100.0,
          updatedAt: widget.existingAssignment != null
              ? DateTime.now()
              : null, // Set updatedAt only for edits
        );

        // Create or Update assignment using controller
        final controller = ref.read(assignmentControllerProvider.notifier);
        final bool success;

        if (widget.existingAssignment != null) {
          // Update existing assignment
          success = await controller.updateAssignment(assignment);
        } else {
          // Create new assignment
          success = await controller.createAssignment(assignment);
        }

        // Hide loading indicator
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (success) {
          // Mark as published - no cleanup needed
          _isPublished = true;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(widget.existingAssignment != null
                      ? 'Assignment updated successfully!'
                      : 'Assignment published successfully!')),
            );
            Navigator.pop(context, true); // Return true to indicate success
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Failed to publish assignment. Please try again.')),
            );
          }
        }
      } catch (e) {
        // Hide loading indicator if shown
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Widget _buildDateButton({
    required IconData icon,
    required String label,
    required bool hasValue,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: hasValue ? Colors.white : Colors.grey[600],
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
