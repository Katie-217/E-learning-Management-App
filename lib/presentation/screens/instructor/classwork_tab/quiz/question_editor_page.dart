import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import Question model from question_bank_page
import 'question_bank_page.dart';

// Model cho một câu hỏi trong Bulk Editor
class QuestionFormData {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> answerControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  String difficulty = 'medium';
  int correctAnswerIndex = 0;
  String? errorMessage;

  QuestionFormData({
    String? questionText,
    String? difficulty,
    List<String>? answers,
    int? correctAnswerIndex,
  }) {
    if (questionText != null) questionController.text = questionText;
    if (difficulty != null) this.difficulty = difficulty;
    if (correctAnswerIndex != null)
      this.correctAnswerIndex = correctAnswerIndex;
    if (answers != null && answers.length == 4) {
      for (int i = 0; i < 4; i++) {
        answerControllers[i].text = answers[i];
      }
    }
  }

  bool validate() {
    if (questionController.text.trim().isEmpty) {
      errorMessage = 'Question text is required';
      return false;
    }
    for (int i = 0; i < answerControllers.length; i++) {
      if (answerControllers[i].text.trim().isEmpty) {
        errorMessage = 'Answer ${String.fromCharCode(65 + i)} is required';
        return false;
      }
    }
    errorMessage = null;
    return true;
  }

  void dispose() {
    questionController.dispose();
    for (var controller in answerControllers) {
      controller.dispose();
    }
  }
}

class QuestionEditorPage extends ConsumerStatefulWidget {
  final String courseId;
  final Question? question; // null = create mode, not null = edit mode

  const QuestionEditorPage({
    super.key,
    required this.courseId,
    this.question,
  });

  @override
  ConsumerState<QuestionEditorPage> createState() => _QuestionEditorPageState();
}

class _QuestionEditorPageState extends ConsumerState<QuestionEditorPage> {
  final List<QuestionFormData> _questions = [];
  final ScrollController _scrollController = ScrollController();
  bool _isSaving = false;

  bool get _isEditMode => widget.question != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      // Edit mode: Load existing question as single card
      _questions.add(_loadExistingQuestion(widget.question!));
    } else {
      // Create mode: Start with 1 empty card
      _questions.add(QuestionFormData());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  QuestionFormData _loadExistingQuestion(Question question) {
    return QuestionFormData(
      questionText: question.text,
      difficulty: question.difficulty,
      answers: question.options.length >= 4 ? question.options : null,
      correctAnswerIndex: question.correctAnswerIndex,
    );
  }

  void _addNewQuestion() {
    setState(() {
      _questions.add(QuestionFormData());
    });
    // Auto scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length > 1) {
      setState(() {
        _questions[index].dispose();
        _questions.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Cannot remove the last question')),
      );
    }
  }

  Future<void> _generateWithAI() async {
    // TODO: Implement AI generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🤖 AI Generation feature coming soon!'),
        backgroundColor: Colors.purple,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveAll() async {
    // Validate all questions
    bool allValid = true;
    int? firstInvalidIndex;

    for (int i = 0; i < _questions.length; i++) {
      if (!_questions[i].validate()) {
        allValid = false;
        firstInvalidIndex ??= i;
      }
    }

    if (!allValid && firstInvalidIndex != null) {
      setState(() {}); // Refresh to show errors
      // Scroll to first invalid card
      final cardHeight = 550.0; // Approximate height
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          firstInvalidIndex * (cardHeight + 16), // +16 for padding
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please fix validation errors'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // All valid - Save to Firestore
    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: Implement actual Firestore save
      await Future.delayed(const Duration(seconds: 1)); // Simulate save

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? '✅ Question updated successfully!'
                  : '✅ ${_questions.length} question(s) saved successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh list
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
        title: Text(
          _isEditMode ? 'Edit Question' : 'Create Questions',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // AI Generate button (only in Create mode)
          if (!_isEditMode) ...[
            TextButton.icon(
              onPressed: _isSaving ? null : _generateWithAI,
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text('Generate AI'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple[300],
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Save All button
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAll,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'SAVE ALL'),
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
          final isWideScreen = constraints.maxWidth >= 800;
          final maxWidth = isWideScreen ? 800.0 : constraints.maxWidth;

          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _QuestionFormCard(
                      key: ValueKey('question_$index'),
                      questionData: _questions[index],
                      onRemove: () => _removeQuestion(index),
                      canRemove: _questions.length > 1,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: !_isEditMode
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _addNewQuestion,
              backgroundColor: Colors.purple[600],
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
            )
          : null,
    );
  }
}

// ========================================
// Question Form Card Widget
// ========================================
class _QuestionFormCard extends StatefulWidget {
  final QuestionFormData questionData;
  final VoidCallback onRemove;
  final bool canRemove;

  const _QuestionFormCard({
    super.key,
    required this.questionData,
    required this.onRemove,
    required this.canRemove,
  });

  @override
  State<_QuestionFormCard> createState() => _QuestionFormCardState();
}

class _QuestionFormCardState extends State<_QuestionFormCard> {
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'hard':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.questionData.errorMessage != null;

    return Card(
      color: const Color(0xFF1E293B),
      elevation: hasError ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasError ? Colors.red : Colors.grey[800]!,
          width: hasError ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: widget.questionData.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Difficulty Segmented + Remove button
              Row(
                children: [
                  Expanded(child: _buildDifficultySegmented()),
                  const SizedBox(width: 12),
                  if (widget.canRemove)
                    IconButton(
                      onPressed: widget.onRemove,
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red[400],
                      tooltip: 'Remove question',
                    ),
                ],
              ),

              // Error banner
              if (hasError) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.questionData.errorMessage!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Question Text Field
              Text(
                'Question',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: widget.questionData.questionController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Enter your question here...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
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
                    borderSide:
                        const BorderSide(color: Colors.purple, width: 2),
                  ),
                ),
                onChanged: (_) {
                  widget.questionData.errorMessage = null;
                  setState(() {});
                },
              ),

              const SizedBox(height: 20),

              // Answers Section
              Text(
                'Answers (Select the correct one)',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              ...List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAnswerRow(index),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultySegmented() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: ['easy', 'medium', 'hard'].map((difficulty) {
          final isSelected = widget.questionData.difficulty == difficulty;
          final color = _getDifficultyColor(difficulty);

          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  widget.questionData.difficulty = difficulty;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isSelected ? color.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    difficulty.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? color : Colors.grey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnswerRow(int index) {
    final letter = String.fromCharCode(65 + index); // A, B, C, D
    final isCorrect = widget.questionData.correctAnswerIndex == index;

    return Row(
      children: [
        // Radio Button
        Radio<int>(
          value: index,
          groupValue: widget.questionData.correctAnswerIndex,
          onChanged: (value) {
            setState(() {
              widget.questionData.correctAnswerIndex = value!;
            });
          },
          activeColor: Colors.green,
        ),
        const SizedBox(width: 8),
        // Letter Badge
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCorrect
                ? Colors.green.withOpacity(0.2)
                : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isCorrect ? Colors.green : Colors.grey[800]!,
            ),
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                color: isCorrect ? Colors.green : Colors.grey[400],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Answer TextField
        Expanded(
          child: TextField(
            controller: widget.questionData.answerControllers[index],
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Answer $letter',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                borderSide: const BorderSide(color: Colors.purple, width: 2),
              ),
            ),
            onChanged: (_) {
              widget.questionData.errorMessage = null;
              setState(() {});
            },
          ),
        ),
      ],
    );
  }
}
