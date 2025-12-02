// ========================================
// FILE: semester_filter_instructor.dart
// MÔ TẢ: Widget chuyển đổi học kỳ cho Instructor Dashboard với tính năng tạo mới
// ========================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../data/repositories/semester/semester_template_repository.dart';
import '../../../../../domain/models/semester_model.dart';
import '../../../../../domain/models/semester_template_model.dart';
import '../../../../../domain/models/validation_result.dart';
import '../../../../../application/controllers/semester/semester_provider.dart';

// ========================================
// Using global providers from semester_provider.dart
// ========================================

// ========================================
// MAIN WIDGET: SemesterFilterInstructor
// ========================================
class SemesterFilterInstructor extends ConsumerStatefulWidget {
  final String? selectedSemesterId;
  final Function(String semesterId) onSemesterChanged;

  const SemesterFilterInstructor({
    super.key,
    this.selectedSemesterId,
    required this.onSemesterChanged,
  });

  @override
  ConsumerState<SemesterFilterInstructor> createState() =>
      _SemesterFilterInstructorState();
}

class _SemesterFilterInstructorState
    extends ConsumerState<SemesterFilterInstructor> {
  String? _selectedSemesterId;

  @override
  void initState() {
    super.initState();
    _selectedSemesterId = widget.selectedSemesterId;
  }

  @override
  Widget build(BuildContext context) {
    final semesterListAsync = ref.watch(semesterListProvider);

    return Container(
      height: 50, // Fixed height to match action buttons
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        children: [
          // Flexible Dropdown Semester List (Takes remaining space)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dropdownWidth = constraints.maxWidth;

                return semesterListAsync.when(
                  data: (semesters) => _buildConstrainedDropdown(
                    context,
                    semesters,
                    _selectedSemesterId,
                    'Select Semester',
                    dropdownWidth, // Pass the exact width
                    (String? newValue) {
                      if (newValue != null && newValue != _selectedSemesterId) {
                        setState(() {
                          _selectedSemesterId = newValue;
                        });
                        widget.onSemesterChanged(newValue);
                      }
                    },
                  ),
                  loading: () => const SizedBox(
                    height: 40,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.indigo),
                        ),
                      ),
                    ),
                  ),
                  error: (error, stack) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Error loading semesters',
                      style: TextStyle(color: Colors.red),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
          // Separator
          Container(
            width: 1,
            height: 32,
            color: Colors.grey[700],
          ),
          // Fixed Add Button (48px width)
          SizedBox(
            width: 48,
            child: InkWell(
              onTap: () => _showCreateSemesterDialog(context),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: Container(
                height: 40, // Fixed height to match dropdown
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConstrainedDropdown(
    BuildContext context,
    List<SemesterModel> items,
    String? selectedValue,
    String hint,
    double constrainedWidth, // Add constrained width parameter
    Function(String?) onChanged,
  ) {
    return DropdownMenu<String>(
      initialSelection: selectedValue,
      hintText: hint,
      // Remove fixed width to allow flexible sizing
      enableSearch: true,
      enableFilter: true,
      textStyle: const TextStyle(color: Colors.white, fontSize: 14),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
      ),
      menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Color(0xFF1F2937)),
          elevation: const WidgetStatePropertyAll(8),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Constrain menu width to match dropdown width exactly
          fixedSize:
              WidgetStatePropertyAll(Size(constrainedWidth, double.infinity))),
      trailingIcon:
          const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
      selectedTrailingIcon:
          const Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 20),
      onSelected: (String? value) {
        if (value != null) {
          onChanged(value);
        }
      },
      dropdownMenuEntries:
          items.map<DropdownMenuEntry<String>>((SemesterModel item) {
        return DropdownMenuEntry<String>(
          value: item.name, // Use semester name instead of ID for filtering
          label: item.name,
          labelWidget: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 3, // Allow up to 3 lines
                    overflow: TextOverflow.visible, // Show full text
                  ),
                ),
                InkWell(
                  onTap: () => _showEditSemesterDialog(context, item),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.more_vert, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          style: MenuItemButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.transparent,
            padding: EdgeInsets
                .zero, // Remove default padding since we handle it in labelWidget
            fixedSize: null, // Allow flexible height
            minimumSize: const Size(double.infinity, 48),
          ),
        );
      }).toList(),
    );
  }

  void _showCreateSemesterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateSemesterDialog(
        onSemesterCreated: (String newSemesterId) {
          // Refresh semester list
          ref.invalidate(semesterListProvider);
          // Auto-select new semester
          setState(() {
            _selectedSemesterId = newSemesterId;
          });
          widget.onSemesterChanged(newSemesterId);
        },
      ),
    );
  }

  void _showEditSemesterDialog(BuildContext context, SemesterModel semester) {
    showDialog(
      context: context,
      builder: (context) => EditSemesterDialog(
        semester: semester,
        onSemesterUpdated: (String updatedSemesterId) {
          // Refresh semester list
          ref.invalidate(semesterListProvider);
          // Keep current selection
          if (_selectedSemesterId == updatedSemesterId) {
            widget.onSemesterChanged(updatedSemesterId);
          }
        },
        onSemesterDeleted: () {
          // Refresh semester list
          ref.invalidate(semesterListProvider);
          // Clear selection if deleted semester was selected
          if (_selectedSemesterId == semester.id) {
            setState(() {
              _selectedSemesterId = null;
            });
          }
        },
      ),
    );
  }
}

// ========================================
// CREATE SEMESTER DIALOG
// ========================================
class CreateSemesterDialog extends ConsumerStatefulWidget {
  final Function(String semesterId) onSemesterCreated;

  const CreateSemesterDialog({
    super.key,
    required this.onSemesterCreated,
  });

  @override
  ConsumerState<CreateSemesterDialog> createState() =>
      _CreateSemesterDialogState();
}

class _CreateSemesterDialogState extends ConsumerState<CreateSemesterDialog> {
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  String? _selectedTemplateId;
  String? _previewText;
  Timer? _debounceTimer;
  bool _isLoading = false;

  // Validation errors (updated from controller)
  String? _templateError;
  String? _yearError;
  String? _nameError;
  String? _creationError; // Inline error for semester creation duplication

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onInputChanged() {
    // Clear creation error immediately when user makes changes
    _clearCreationError();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _generatePreview();
    });
  }

  // Helper method to clear creation error
  void _clearCreationError() {
    if (_creationError != null) {
      setState(() {
        _creationError = null;
      });
    }
  }

  Future<void> _generatePreview() async {
    if (_selectedTemplateId == null || _yearController.text.isEmpty) {
      setState(() {
        _previewText = null;
      });
      return;
    }

    try {
      final year = int.parse(_yearController.text);
      final templateRepository = SemesterTemplateRepository();
      final template =
          await templateRepository.getTemplateById(_selectedTemplateId!);

      if (template != null) {
        final startDate = template.generateStartDate(year);
        final endDate = template.generateEndDate(year);

        setState(() {
          _previewText =
              'Duration: ${_formatDate(startDate)} - ${_formatDate(endDate)}';
        });
      }
    } catch (e) {
      setState(() {
        _previewText = null;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<bool> _validateFields() async {
    final controller = ref.read(semesterControllerProvider);

    final validationResult = await controller.validateSemesterCreation(
      templateId: _selectedTemplateId,
      yearText: _yearController.text,
      name: _nameController.text,
    );

    setState(() {
      _templateError = validationResult.templateError;
      _yearError = validationResult.yearError;
      _nameError = validationResult.nameError;
    });

    return validationResult.isValid;
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(semesterTemplateListProvider);

    return AlertDialog(
      title: const Text('Create New Semester'),
      backgroundColor: const Color(0xFF1F2937),
      titleTextStyle: const TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Template + Year (Merged Input)
            const Text(
              'Semester Configuration',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _templateError != null || _yearError != null
                      ? Colors.red
                      : Colors.grey[600]!,
                  width: _templateError != null || _yearError != null ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Template Dropdown
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: Colors.grey)),
                      ),
                      child: templatesAsync.when(
                        data: (templates) => _buildTemplateAnchoredDropdown(
                          context,
                          templates.where((t) => t.isActive).toList(),
                          _selectedTemplateId,
                          'Select Term',
                          (String? value) {
                            setState(() {
                              _selectedTemplateId = value;
                              _templateError = null; // Clear error on selection
                            });
                            _clearCreationError(); // Clear creation error immediately
                            _onInputChanged();
                          },
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => const Text('Error',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ),
                  // Year Input
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _yearController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Year',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _yearError = null; // Clear error on change
                        });
                        _clearCreationError(); // Clear creation error immediately
                        _onInputChanged();
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Template and Year Error Messages
            if (_templateError != null || _yearError != null) ...[
              const SizedBox(height: 4),
              if (_templateError != null)
                Text(
                  _templateError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              if (_yearError != null)
                Text(
                  _yearError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
            ],
            // Creation Error (Inline display for duplication errors)
            if (_creationError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[900]?.withOpacity(0.3),
                  border: Border.all(color: Colors.red, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _creationError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Preview Time (moved up)
            if (_previewText != null) ...[
              const SizedBox(height: 12),
              Text(
                _previewText!,
                style: TextStyle(
                  color: Colors.indigo[300],
                  fontSize: 14, // Increased from 12
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Row 2: Display Name
            const Text(
              'Display Name',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Semester 1 (2025-2026)',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _nameError != null ? Colors.red : Colors.grey[600]!,
                    width: _nameError != null ? 2 : 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _nameError != null ? Colors.red : Colors.grey[600]!,
                    width: _nameError != null ? 2 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _nameError != null ? Colors.red : Colors.indigo,
                    width: 2,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _nameError = null; // Clear error on change
                });
                _clearCreationError(); // Clear creation error immediately
              },
            ),
            // Display Name Error Message
            if (_nameError != null) ...[
              const SizedBox(height: 4),
              Text(
                _nameError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Cancel Button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        // Create Button
        ElevatedButton(
          onPressed: _isLoading ? null : _showCreateConfirmation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Create Semester'),
        ),
      ],
    );
  }

  Widget _buildTemplateAnchoredDropdown(
    BuildContext context,
    List<SemesterTemplateModel> templates,
    String? selectedValue,
    String hint,
    Function(String?) onChanged,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dropdownWidth =
            constraints.maxWidth > 0 ? constraints.maxWidth : 200.0;

        return DropdownMenu<String>(
          initialSelection: selectedValue,
          hintText: hint,
          width: dropdownWidth,
          textStyle: const TextStyle(color: Colors.white, fontSize: 14),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          menuStyle: MenuStyle(
            backgroundColor: const WidgetStatePropertyAll(Color(0xFF1F2937)),
            elevation: const WidgetStatePropertyAll(8),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maximumSize: WidgetStatePropertyAll(Size.fromWidth(dropdownWidth)),
          ),
          trailingIcon: const Icon(Icons.keyboard_arrow_down,
              color: Colors.white, size: 20),
          selectedTrailingIcon: const Icon(Icons.keyboard_arrow_up,
              color: Colors.white, size: 20),
          onSelected: (String? value) {
            if (value != null) {
              onChanged(value);
            }
          },
          dropdownMenuEntries: templates
              .map<DropdownMenuEntry<String>>((SemesterTemplateModel template) {
            return DropdownMenuEntry<String>(
              value: template.id,
              label: template.name,
              style: MenuItemButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _showCreateConfirmation() async {
    // Validate all fields
    final isValid = await _validateFields();
    if (!isValid) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Semester Details'),
        backgroundColor: const Color(0xFF1F2937),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        content: const Text(
          'Please review the information before saving',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _createSemester();
    }
  }

  Future<void> _createSemester() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final year = int.parse(_yearController.text);
      final controller = ref.read(semesterControllerProvider);

      final semesterId = await controller.handleCreateSemester(
        templateId: _selectedTemplateId!,
        year: year,
        name: _nameController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSemesterCreated(semesterId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semester created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Clean error message - remove all technical prefixes comprehensively
        String errorMessage = e.toString();

        // Remove common technical prefixes (order matters - most specific first)
        final prefixesToRemove = [
          'Exception: Lỗi tạo semester: Exception: ',
          'Lỗi tạo semester: Exception: ',
          'Error creating semester: Exception: ',
          'Exception: Lỗi tạo semester: ',
          'Error creating semester: ',
          'Lỗi tạo semester: ',
          'Exception: ',
          'Error: ',
          'FirebaseException: ',
        ];

        // Apply prefix removal iteratively until no more prefixes are found
        bool foundPrefix;
        do {
          foundPrefix = false;
          for (final prefix in prefixesToRemove) {
            if (errorMessage.startsWith(prefix)) {
              errorMessage = errorMessage.substring(prefix.length);
              foundPrefix = true;
              break; // Only remove one prefix per iteration
            }
          }
        } while (foundPrefix);

        setState(() {
          _creationError = errorMessage.trim();
        });

        // Error will persist until user interacts with input fields
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// ========================================
// EDIT SEMESTER DIALOG
// ========================================
class EditSemesterDialog extends ConsumerStatefulWidget {
  final SemesterModel semester;
  final Function(String semesterId) onSemesterUpdated;
  final VoidCallback onSemesterDeleted;

  const EditSemesterDialog({
    super.key,
    required this.semester,
    required this.onSemesterUpdated,
    required this.onSemesterDeleted,
  });

  @override
  ConsumerState<EditSemesterDialog> createState() => _EditSemesterDialogState();
}

class _EditSemesterDialogState extends ConsumerState<EditSemesterDialog> {
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  final _templateController = TextEditingController();
  String? _selectedTemplateId;
  String? _previewText;
  Timer? _debounceTimer;
  bool _isLoading = false;

  // Validation errors
  String? _templateError;
  String? _yearError;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data
    _nameController.text = widget.semester.name;
    // Extract year from semester code (format: "templateId_year")
    final codeParts = widget.semester.code.split('_');
    if (codeParts.length == 2) {
      _selectedTemplateId = codeParts[0];
      _yearController.text = codeParts[1];
    }

    // Calculate preview immediately after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generatePreview();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _templateController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onInputChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _generatePreview();
    });
  }

  Future<void> _generatePreview() async {
    if (_selectedTemplateId == null || _yearController.text.isEmpty) {
      setState(() {
        _previewText = null;
      });
      return;
    }

    try {
      final year = int.parse(_yearController.text);
      final templateRepository = SemesterTemplateRepository();
      final template =
          await templateRepository.getTemplateById(_selectedTemplateId!);

      if (template != null) {
        final startDate = template.generateStartDate(year);
        final endDate = template.generateEndDate(year);

        setState(() {
          _previewText =
              'Duration: ${_formatDate(startDate)} - ${_formatDate(endDate)}';
        });
      }
    } catch (e) {
      setState(() {
        _previewText = null;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<bool> _validateFields() async {
    final controller = ref.read(semesterControllerProvider);

    final validationResult = await controller.validateSemesterCreation(
      templateId: _selectedTemplateId,
      yearText: _yearController.text,
      name: _nameController.text,
    );

    setState(() {
      _templateError = validationResult.templateError;
      _yearError = validationResult.yearError;
      _nameError = validationResult.nameError;
    });

    return validationResult.isValid;
  }

  Widget _buildTemplateDropdown() {
    final templatesAsync = ref.watch(semesterTemplateListProvider);

    return templatesAsync.when(
      data: (templates) => LayoutBuilder(
        builder: (context, constraints) {
          final dropdownWidth =
              constraints.maxWidth > 0 ? constraints.maxWidth : 200.0;

          // Set the template controller text if we have a selected template
          if (_selectedTemplateId != null && _templateController.text.isEmpty) {
            final selectedTemplate = templates.firstWhere(
                (t) => t.id == _selectedTemplateId,
                orElse: () => templates.first);
            _templateController.text = selectedTemplate.name;
            // Trigger preview calculation when template is set
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _generatePreview();
            });
          }

          return DropdownMenu<String>(
            controller: _templateController,
            initialSelection: _selectedTemplateId,
            hintText: 'Select Term',
            width: dropdownWidth,
            enableSearch: true,
            enableFilter: true,
            textStyle: const TextStyle(color: Colors.white, fontSize: 14),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Colors.transparent,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            menuStyle: MenuStyle(
              backgroundColor: const WidgetStatePropertyAll(Color(0xFF1F2937)),
              elevation: const WidgetStatePropertyAll(8),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maximumSize:
                  WidgetStatePropertyAll(Size.fromWidth(dropdownWidth)),
            ),
            trailingIcon: const Icon(Icons.keyboard_arrow_down,
                color: Colors.white, size: 20),
            selectedTrailingIcon: const Icon(Icons.keyboard_arrow_up,
                color: Colors.white, size: 20),
            onSelected: (String? value) {
              if (value != null) {
                setState(() {
                  _selectedTemplateId = value;
                  _templateError = null;
                });
                _onInputChanged();
              }
            },
            dropdownMenuEntries: templates
                .where((t) => t.isActive)
                .map<DropdownMenuEntry<String>>((template) {
              return DropdownMenuEntry<String>(
                value: template.id,
                label: template.name,
                style: MenuItemButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              );
            }).toList(),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          const Text('Error', style: TextStyle(color: Colors.red)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Edit Semester'),
          IconButton(
            onPressed: _showDeleteConfirmation,
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete Semester',
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1F2937),
      titleTextStyle: const TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Semester Configuration
            const Text(
              'Semester Configuration',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _templateError != null || _yearError != null
                      ? Colors.red
                      : Colors.grey[600]!,
                  width: _templateError != null || _yearError != null ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Template Dropdown
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: Colors.grey)),
                      ),
                      child: _buildTemplateDropdown(),
                    ),
                  ),
                  // Year Input
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _yearController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Year',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _yearError = null;
                        });
                        _onInputChanged();
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Template and Year Error Messages
            if (_templateError != null || _yearError != null) ...[
              const SizedBox(height: 4),
              if (_templateError != null)
                Text(
                  _templateError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              if (_yearError != null)
                Text(
                  _yearError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
            ],
            // Preview Time
            if (_previewText != null) ...[
              const SizedBox(height: 12),
              Text(
                _previewText!,
                style: TextStyle(
                  color: Colors.indigo[300],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Display Name
            const Text(
              'Display Name',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Semester 1 (2025-2026)',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _nameError != null ? Colors.red : Colors.grey[600]!,
                    width: _nameError != null ? 2 : 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _nameError != null ? Colors.red : Colors.grey[600]!,
                    width: _nameError != null ? 2 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _nameError != null ? Colors.red : Colors.indigo,
                    width: 2,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _nameError = null;
                });
              },
            ),
            // Display Name Error Message
            if (_nameError != null) ...[
              const SizedBox(height: 4),
              Text(
                _nameError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Cancel Button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        // Save Button
        ElevatedButton(
          onPressed: _isLoading ? null : _showUpdateConfirmation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }

  Future<void> _showUpdateConfirmation() async {
    final isValid = await _validateFields();
    if (!isValid) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Semester Details'),
        backgroundColor: const Color(0xFF1F2937),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        content: const Text(
          'Please review the information before saving',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateSemester();
    }
  }

  Future<void> _updateSemester() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final year = int.parse(_yearController.text);
      final controller = ref.read(semesterControllerProvider);

      await controller.handleUpdateSemester(
        semesterId: widget.semester.id,
        templateId: _selectedTemplateId!,
        year: year,
        name: _nameController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSemesterUpdated(widget.semester.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semester updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating semester: $e'),
            backgroundColor: Colors.red,
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

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Semester?'),
        backgroundColor: const Color(0xFF1F2937),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        content: const Text(
          'Are you sure you want to delete this semester? This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteSemester();
    }
  }

  Future<void> _deleteSemester() async {
    try {
      final controller = ref.read(semesterControllerProvider);
      await controller.handleDeleteSemester(widget.semester.id);

      if (mounted) {
        Navigator.of(context).pop(); // Close edit dialog
        widget.onSemesterDeleted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semester deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting semester: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
