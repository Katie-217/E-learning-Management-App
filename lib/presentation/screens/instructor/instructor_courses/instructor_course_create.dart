import 'package:flutter/material.dart';

class CreateCoursePage extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const CreateCoursePage({
    super.key,
    this.onSuccess,
    this.onCancel,
  });

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final TextEditingController _courseCodeController = TextEditingController();
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _creditsController = TextEditingController(text: '3');

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  
  String? _selectedSemester;
  int _selectedSessions = 10;
  String _selectedStatus = 'active';
  int _maxCapacity = 50;

  // Mock data for semesters - replace with actual data
  final List<String> _semesters = [
    'HK1/24-25',
    'HK2/24-25',
    'HK3/24-25',
    'HK1/25-26',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSemester = _semesters.first;
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_courseCodeController.text.trim().isEmpty) {
      _showError('⚠️ Please enter course code');
      return false;
    }

    if (_courseNameController.text.trim().isEmpty) {
      _showError('⚠️ Please enter course name');
      return false;
    }

    return true;
  }

  Future<void> _createCourse() async {
    if (!_validateForm()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      // TODO: Implement actual course creation logic
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        _showSuccess(
          '✅ Course created successfully!\n'
          'Code: ${_courseCodeController.text}\n'
          'Name: ${_courseNameController.text}',
        );

        await Future.delayed(const Duration(seconds: 1));
        if (mounted && widget.onSuccess != null) {
          widget.onSuccess!();
        }
      }
    } catch (e) {
      _showError('❌ Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text(
              '🎉 Success!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.onSuccess != null) {
                widget.onSuccess!();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int minLines = 1,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines ?? minLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFF1F2937),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFF1F2937),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            style: const TextStyle(color: Colors.white),
            dropdownColor: const Color(0xFF1F2937),
            items: items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.indigo),
                  SizedBox(height: 16),
                  Text(
                    '🔄 Creating course...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 📌 NOTE AT TOP
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[900]?.withOpacity(0.3),
                        border: Border.all(color: Colors.blue[700]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ℹ️ Note:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Course code must be unique\n'
                            '• Course name is required\n'
                            '• Select appropriate semester\n'
                            '• Set maximum capacity for enrollments',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildSection(
                      '📚 Basic Information',
                      [
                        _buildTextField(
                          controller: _courseCodeController,
                          label: 'Course Code',
                          hint: 'E.g.: CS101',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter course code';
                            }
                            if (value.length < 3) {
                              return 'Course code must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _courseNameController,
                          label: 'Course Name',
                          hint: 'E.g.: Introduction to Programming',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter course name';
                            }
                            if (value.length < 5) {
                              return 'Course name must be at least 5 characters';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint: 'Brief description of the course...',
                          minLines: 3,
                          maxLines: 5,
                        ),
                      ],
                    ),

                    _buildSection(
                      '⚙️ Course Settings',
                      [
                        _buildDropdown<String>(
                          label: 'Semester',
                          value: _selectedSemester!,
                          items: _semesters,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedSemester = value);
                            }
                          },
                          itemLabel: (item) => item,
                        ),
                        _buildDropdown<int>(
                          label: 'Number of Sessions',
                          value: _selectedSessions,
                          items: const [10, 15, 20],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedSessions = value);
                            }
                          },
                          itemLabel: (item) => '$item sessions',
                        ),
                        _buildTextField(
                          controller: _creditsController,
                          label: 'Credits',
                          hint: 'E.g.: 3',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter credits';
                            }
                            final credits = int.tryParse(value);
                            if (credits == null || credits < 1 || credits > 6) {
                              return 'Credits must be between 1 and 6';
                            }
                            return null;
                          },
                        ),
                        _buildDropdown<String>(
                          label: 'Status',
                          value: _selectedStatus,
                          items: const ['active', 'draft', 'archived'],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedStatus = value);
                            }
                          },
                          itemLabel: (item) => item[0].toUpperCase() + item.substring(1),
                        ),
                      ],
                    ),

                    _buildSection(
                      '👥 Capacity',
                      [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Maximum Students: $_maxCapacity',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _maxCapacity.toDouble(),
                          min: 10,
                          max: 200,
                          divisions: 38,
                          label: _maxCapacity.toString(),
                          activeColor: Colors.blue,
                          inactiveColor: Colors.grey[700],
                          onChanged: (value) {
                            setState(() => _maxCapacity = value.toInt());
                          },
                        ),
                      ],
                    ),

                    const Divider(height: 32, color: Colors.grey),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _createCourse,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.add, size: 24),
                        label: Text(
                          isLoading ? 'Creating...' : 'Create Course',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _handleCancel,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Colors.red),
                        ),
                        icon: const Icon(Icons.close,
                            size: 24, color: Colors.red),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseNameController.dispose();
    _descriptionController.dispose();
    _creditsController.dispose();
    super.dispose();
  }
}