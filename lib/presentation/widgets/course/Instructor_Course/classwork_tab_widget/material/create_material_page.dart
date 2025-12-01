import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/domain/models/material_model.dart'
    as model;
import 'package:elearning_management_app/application/controllers/material/material_controller.dart';
import '../assignment/add_link_assignments.dart';
import '../assignment/upload_file_assignment.dart';
import '../assignment/file_preview_overlay.dart';

class CreateMaterialPage extends ConsumerStatefulWidget {
  final CourseModel? course;
  final model.MaterialModel? existingMaterial;

  const CreateMaterialPage({
    super.key,
    this.course,
    this.existingMaterial,
  }) : assert(course != null || existingMaterial != null,
            'Either course or existingMaterial must be provided');

  @override
  ConsumerState<CreateMaterialPage> createState() => _CreateMaterialPageState();
}

class _CreateMaterialPageState extends ConsumerState<CreateMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<LinkMetadata> _attachedLinks = [];
  List<UploadedFileModel> _uploadedFiles = [];
  Map<String, double> _uploadProgress = {};
  bool _isPublished = false;
  bool _isLoadingEditData = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingMaterial != null) {
      _initializeEditMode();
    }
  }

  void _initializeEditMode() async {
    final material = widget.existingMaterial;
    if (material == null) return;

    setState(() {
      _isLoadingEditData = true;
    });

    try {
      // Dùng controller để load data
      final data = await MaterialController.initializeEditMode(material);

      _titleController.text = data['title'];
      _descriptionController.text = data['description'];
      _attachedLinks = List<LinkMetadata>.from(data['attachedLinks']);
      _uploadedFiles = List<UploadedFileModel>.from(data['uploadedFiles']);
    } catch (e) {
      print('Error loading material data: $e');
    } finally {
      setState(() {
        _isLoadingEditData = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _hasUploadingFiles() {
    return MaterialController.hasUploadingFiles(
        _uploadedFiles, _uploadProgress);
  }

  Future<void> _cleanupUploadedFiles() async {
    await MaterialController.cleanupUploadedFiles(
      _uploadedFiles,
      _isPublished,
      widget.existingMaterial != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingEditData) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          title: Text(
            widget.existingMaterial != null
                ? 'Edit Material'
                : 'Create Material',
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
                'Loading material data...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _cleanupUploadedFiles();
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
              await _cleanupUploadedFiles();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            widget.existingMaterial != null
                ? 'Edit Material'
                : 'Create Material',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                onPressed: _hasUploadingFiles() ? null : _publishMaterial,
                icon: const Icon(Icons.send, size: 18),
                label: Text(
                  widget.existingMaterial != null ? 'Save' : 'Publish',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth >= 800;

              if (isWideScreen) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 7,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildMainContentSection(),
                      ),
                    ),
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
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: _buildConfigurationSection(),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
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
      ),
    );
  }

  Widget _buildMainContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Title', required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: 'Material title',
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
        _buildSectionTitle('Description'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Provide a description for this material (optional)...',
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
        _buildSectionTitle('Attachments'),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildAttachmentButton(
              icon: Icons.upload_file,
              label: 'Upload File',
              onTap: () async {
                // Dùng controller để pick files
                final files = await MaterialController.pickFiles();
                if (files.isNotEmpty) {
                  for (var file in files) {
                    try {
                      setState(() {
                        _uploadProgress[file.fileName] = 0.0;
                        _uploadedFiles.add(file);
                      });

                      // Dùng controller để upload file
                      final uploadedFile = await MaterialController.uploadFile(
                        file: file,
                        courseId: widget.course?.id ??
                            widget.existingMaterial?.courseId ??
                            '',
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
                        // Dùng controller để delete file
                        try {
                          await MaterialController.deleteFile(file.filePath);
                        } catch (e) {
                          print('Error deleting file: $e');
                        }
                        setState(() {
                          _uploadProgress.remove(file.fileName);
                          _uploadedFiles.removeAt(index);
                        });
                      },
                      onTap: () async {
                        final fileName = _uploadedFiles[index].fileName;
                        final progress = _uploadProgress[fileName] ?? 1.0;

                        if (progress >= 1.0) {
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
        if (_attachedLinks.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...List.generate(
            _attachedLinks.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LinkPreviewCard(
                metadata: _attachedLinks[index],
                onRemove: () {
                  setState(() {
                    _attachedLinks.removeAt(index);
                  });
                },
              ),
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
        _buildSectionTitle('For'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Row(
            children: [
              Icon(Icons.people_outline, color: Colors.grey[400], size: 20),
              const SizedBox(width: 12),
              const Text(
                'All Groups in Course',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
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

  void _publishMaterial() async {
    if (_formKey.currentState!.validate()) {
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

      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final courseId =
            widget.course?.id ?? widget.existingMaterial?.courseId ?? '';

        // Dùng controller để publish material
        await MaterialController.publishMaterial(
          courseId: courseId,
          title: _titleController.text,
          description: _descriptionController.text,
          attachedLinks: _attachedLinks,
          uploadedFiles: _uploadedFiles,
          existingMaterial: widget.existingMaterial,
        );

        _isPublished = true;

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.existingMaterial != null
                  ? '✅ Material updated successfully!'
                  : '✅ Material published successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true)
              .pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
