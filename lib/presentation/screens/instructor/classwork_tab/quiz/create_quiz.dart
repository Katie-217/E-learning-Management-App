import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:intl/intl.dart';

class CreateQuizPage extends ConsumerStatefulWidget {
  final CourseModel course;

  const CreateQuizPage({
    super.key,
    required this.course,
  });

  @override
  ConsumerState<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends ConsumerState<CreateQuizPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Question counters
  final _easyCountController = TextEditingController(text: '0');
  final _mediumCountController = TextEditingController(text: '0');
  final _hardCountController = TextEditingController(text: '0');

  // Configuration controllers
  final _durationController = TextEditingController(text: '45');

  // Available questions from bank (TODO: fetch from Firestore)
  int _availableEasy = 50;
  int _availableMedium = 30;
  int _availableHard = 20;

  // Dates
  DateTime? _openDate;
  TimeOfDay? _openTime;
  DateTime? _closeDate;
  TimeOfDay? _closeTime;

  // Settings
  int _maxAttempts = 1;
  bool _shuffleAnswers = true;
  bool _showScore = true;

  // Validation errors
  String? _easyError;
  String? _mediumError;
  String? _hardError;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // TODO: Fetch available question counts from Firestore
    _loadAvailableQuestions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _easyCountController.dispose();
    _mediumCountController.dispose();
    _hardCountController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableQuestions() async {
    // TODO: Implement Firestore query to count questions by difficulty
    // For now, using mock data
    setState(() {
      _availableEasy = 50;
      _availableMedium = 30;
      _availableHard = 20;
    });
  }

  int get _totalQuestions {
    final easy = int.tryParse(_easyCountController.text) ?? 0;
    final medium = int.tryParse(_mediumCountController.text) ?? 0;
    final hard = int.tryParse(_hardCountController.text) ?? 0;
    return easy + medium + hard;
  }

  void _validateQuestionCount() {
    setState(() {
      final easy = int.tryParse(_easyCountController.text) ?? 0;
      final medium = int.tryParse(_mediumCountController.text) ?? 0;
      final hard = int.tryParse(_hardCountController.text) ?? 0;

      _easyError =
          easy > _availableEasy ? 'Not enough questions in bank' : null;
      _mediumError =
          medium > _availableMedium ? 'Not enough questions in bank' : null;
      _hardError =
          hard > _availableHard ? 'Not enough questions in bank' : null;
    });
  }

  Future<void> _selectDateTime(
    BuildContext context,
    DateTime? currentDate,
    TimeOfDay? currentTime,
    Function(DateTime?, TimeOfDay?) onSelected,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: currentTime ?? TimeOfDay.now(),
      );

      if (time != null && mounted) {
        onSelected(date, time);
      }
    }
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    _validateQuestionCount();
    if (_easyError != null || _mediumError != null || _hardError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please fix validation errors'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_totalQuestions == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please add at least one question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_openDate == null || _closeDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please set open and close dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: Implement Firestore save logic
      await Future.delayed(const Duration(seconds: 1)); // Simulate save

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Quiz created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Quiz',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveQuiz,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.publish, size: 18),
              label: Text(_isSaving ? 'Publishing...' : 'Publish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;

          if (isDesktop) {
            // Desktop: 2-column layout (70% - 30%)
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: Main content (70%)
                Expanded(
                  flex: 7,
                  child: _buildMainContent(),
                ),
                // Right column: Configuration (30%)
                Container(
                  width: constraints.maxWidth * 0.3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    border: Border(
                      left: BorderSide(color: Colors.grey[800]!, width: 1),
                    ),
                  ),
                  child: _buildConfigurationSidebar(),
                ),
              ],
            );
          } else {
            // Mobile: Single column (stacked vertically)
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildMainContent(),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      border: Border(
                        top: BorderSide(color: Colors.grey[800]!, width: 1),
                      ),
                    ),
                    child: _buildConfigurationSidebar(),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            _buildSectionTitle('Quiz Title', required: true),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: _buildInputDecoration(
                hintText: 'Enter quiz title...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Description
            _buildSectionTitle('Description (Optional)'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: 4,
              decoration: _buildInputDecoration(
                hintText: 'Enter instructions for students...',
              ),
            ),
            const SizedBox(height: 32),

            // Quiz Structure Builder
            _buildSectionTitle('Randomize Questions from Bank', required: true),
            const SizedBox(height: 8),
            Text(
              'Set the number of questions to randomly select from each difficulty level',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Easy questions counter
            _buildQuestionCounter(
              label: 'Easy',
              icon: Icons.check_circle,
              color: Colors.green,
              controller: _easyCountController,
              available: _availableEasy,
              error: _easyError,
            ),
            const SizedBox(height: 16),

            // Medium questions counter
            _buildQuestionCounter(
              label: 'Medium',
              icon: Icons.adjust,
              color: Colors.orange,
              controller: _mediumCountController,
              available: _availableMedium,
              error: _mediumError,
            ),
            const SizedBox(height: 16),

            // Hard questions counter
            _buildQuestionCounter(
              label: 'Hard',
              icon: Icons.warning,
              color: Colors.red,
              controller: _hardCountController,
              available: _availableHard,
              error: _hardError,
            ),
            const SizedBox(height: 24),

            // Total Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Questions:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$_totalQuestions',
                    style: TextStyle(
                      color: Colors.purple[300],
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationSidebar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Schedule section
          _buildSectionTitle('Schedule', required: true),
          const SizedBox(height: 16),

          // Open Date
          _buildDateTimeField(
            label: 'Open Date',
            date: _openDate,
            time: _openTime,
            onTap: () => _selectDateTime(
              context,
              _openDate,
              _openTime,
              (date, time) {
                setState(() {
                  _openDate = date;
                  _openTime = time;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Close Date
          _buildDateTimeField(
            label: 'Close Date',
            date: _closeDate,
            time: _closeTime,
            onTap: () => _selectDateTime(
              context,
              _closeDate,
              _closeTime,
              (date, time) {
                setState(() {
                  _closeDate = date;
                  _closeTime = time;
                });
              },
            ),
          ),
          const SizedBox(height: 32),

          // Limits section
          _buildSectionTitle('Limits', required: true),
          const SizedBox(height: 16),

          // Duration
          Text(
            'Duration (Minutes)',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _durationController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _buildInputDecoration(
              hintText: '45',
              suffixIcon: const Icon(Icons.timer, color: Colors.grey),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              final duration = int.tryParse(value);
              if (duration == null || duration <= 0) {
                return 'Invalid duration';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Max Attempts
          Text(
            'Max Attempts',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _maxAttempts,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _buildInputDecoration(
              hintText: 'Select max attempts',
            ),
            items: [
              const DropdownMenuItem(value: 1, child: Text('1 attempt')),
              const DropdownMenuItem(value: 2, child: Text('2 attempts')),
              const DropdownMenuItem(value: 3, child: Text('3 attempts')),
              const DropdownMenuItem(value: -1, child: Text('Unlimited')),
            ],
            onChanged: (value) {
              setState(() {
                _maxAttempts = value!;
              });
            },
          ),
          const SizedBox(height: 32),

          // Settings section
          _buildSectionTitle('Settings'),
          const SizedBox(height: 16),

          // Shuffle Answers
          CheckboxListTile(
            value: _shuffleAnswers,
            onChanged: (value) {
              setState(() {
                _shuffleAnswers = value!;
              });
            },
            title: const Text(
              'Shuffle Answers',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            subtitle: Text(
              'Randomize A/B/C/D order for each student',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            activeColor: Colors.purple[600],
            contentPadding: EdgeInsets.zero,
          ),

          // Show Score
          CheckboxListTile(
            value: _showScore,
            onChanged: (value) {
              setState(() {
                _showScore = value!;
              });
            },
            title: const Text(
              'Show Score Immediately',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            subtitle: Text(
              'Display score right after submission',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            activeColor: Colors.purple[600],
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCounter({
    required String label,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required int available,
    String? error,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: error != null ? Colors.red : Colors.grey[800]!,
          width: error != null ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Available: $available',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Minus button
              IconButton(
                onPressed: () {
                  final current = int.tryParse(controller.text) ?? 0;
                  if (current > 0) {
                    controller.text = (current - 1).toString();
                    _validateQuestionCount();
                  }
                },
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.grey[400],
              ),
              // Input field
              Expanded(
                child: TextFormField(
                  controller: controller,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => _validateQuestionCount(),
                ),
              ),
              // Plus button
              IconButton(
                onPressed: () {
                  final current = int.tryParse(controller.text) ?? 0;
                  controller.text = (current + 1).toString();
                  _validateQuestionCount();
                },
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.grey[400],
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime? date,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    final dateText =
        date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Select date';
    final timeText = time != null ? time.format(context) : '--:--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[400], size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$dateText  $timeText',
                    style: TextStyle(
                      color: date != null ? Colors.white : Colors.grey[500],
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: Colors.grey[600], size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {bool required = false}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[600]),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[800]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.purple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
