import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'question_editor_page.dart';

// Mock data model - sẽ được thay thế bằng model thật sau
class Question {
  final String id;
  final String text;
  final String difficulty; // 'easy', 'medium', 'hard'
  final List<String> options;
  final int correctAnswerIndex;

  Question({
    required this.id,
    required this.text,
    required this.difficulty,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class QuestionBankPage extends ConsumerStatefulWidget {
  final String courseId;

  const QuestionBankPage({super.key, required this.courseId});

  @override
  ConsumerState<QuestionBankPage> createState() => _QuestionBankPageState();
}

class _QuestionBankPageState extends ConsumerState<QuestionBankPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDifficulty = 'all'; // 'all', 'easy', 'medium', 'hard'
  String _searchQuery = '';

  // Mock data - sẽ được thay thế bằng provider/repository sau
  List<Question> _mockQuestions = [
    Question(
      id: '1',
      text: 'What is Flutter?',
      difficulty: 'easy',
      options: [
        'A mobile app framework',
        'A programming language',
        'A database',
        'An operating system'
      ],
      correctAnswerIndex: 0,
    ),
    Question(
      id: '2',
      text: 'Which widget is used for scrolling in Flutter?',
      difficulty: 'medium',
      options: ['Container', 'ListView', 'Text', 'Image'],
      correctAnswerIndex: 1,
    ),
    Question(
      id: '3',
      text: 'What is the purpose of StatefulWidget?',
      difficulty: 'hard',
      options: [
        'To create static UI',
        'To manage mutable state',
        'To handle routing',
        'To connect to database'
      ],
      correctAnswerIndex: 1,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Question> get _filteredQuestions {
    return _mockQuestions.where((question) {
      // Filter by difficulty
      if (_selectedDifficulty != 'all' &&
          question.difficulty != _selectedDifficulty) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty &&
          !question.text.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();
  }

  int _getQuestionCount(String difficulty) {
    if (difficulty == 'all') {
      return _mockQuestions.length;
    }
    return _mockQuestions.where((q) => q.difficulty == difficulty).length;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'Easy';
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      default:
        return '';
    }
  }

  void _deleteQuestion(String questionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('Delete Question',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this question? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _mockQuestions.removeWhere((q) => q.id == questionId);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Question deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          // SliverAppBar - Chỉ có title và back button
          SliverAppBar(
            backgroundColor: const Color(0xFF1E293B),
            floating: false,
            pinned: true,
            title: const Text(
              'Question Bank',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            actions: [
              // Desktop: Button "+ Add Question"
              if (isDesktop)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToEditor(),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Question'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Search and Filter Section (Floating)
          SliverPersistentHeader(
            delegate: _SearchFilterDelegate(
              searchController: _searchController,
              selectedDifficulty: _selectedDifficulty,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onDifficultyChanged: (value) {
                setState(() {
                  _selectedDifficulty = value;
                });
              },
              buildFilterChip: _buildFilterChip,
            ),
            floating: true, // Floating behavior khi scroll
            pinned: false,
          ),

          // Question List
          SliverPadding(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            sliver: _filteredQuestions.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.quiz_outlined,
                              size: 64, color: Colors.grey[700]),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty ||
                                    _selectedDifficulty != 'all'
                                ? 'No questions found'
                                : 'No questions yet',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty ||
                                    _selectedDifficulty != 'all'
                                ? 'Try adjusting your filters'
                                : 'Tap + to create your first question',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final question = _filteredQuestions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isDesktop ? 800 : double.infinity,
                              ),
                              child: _buildQuestionCard(question),
                            ),
                          ),
                        );
                      },
                      childCount: _filteredQuestions.length,
                    ),
                  ),
          ),
        ],
      ),

      // Mobile: Floating Action Button
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              onPressed: () => _navigateToEditor(),
              backgroundColor: Colors.purple[600],
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedDifficulty == value;
    Color chipColor;

    if (value == 'easy') {
      chipColor = Colors.green;
    } else if (value == 'medium') {
      chipColor = Colors.orange;
    } else if (value == 'hard') {
      chipColor = Colors.red;
    } else {
      chipColor = Colors.purple;
    }

    final count = _getQuestionCount(value);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDifficulty = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? chipColor.withOpacity(0.2) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? chipColor : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isSelected ? chipColor.withOpacity(0.3) : Colors.grey[800],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? chipColor : Colors.grey[500],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    final difficultyColor = _getDifficultyColor(question.difficulty);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Color Stripe (Left)
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: difficultyColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Difficulty badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: difficultyColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: difficultyColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            _getDifficultyLabel(question.difficulty),
                            style: TextStyle(
                              color: difficultyColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Question Text
                    Text(
                      question.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Options preview
                    Text(
                      '${question.options.length} options',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions (Right)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _navigateToEditor(question: question),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: Colors.blue[400],
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    onPressed: () => _deleteQuestion(question.id),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red[400],
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditor({Question? question}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionEditorPage(
          courseId: widget.courseId,
          question: question,
        ),
      ),
    );

    // Refresh list if question was saved
    if (result == true) {
      setState(() {
        // TODO: Reload questions from repository
      });
    }
  }
}

// Custom Delegate for Search/Filter Section with Floating behavior
class _SearchFilterDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final String selectedDifficulty;
  final Function(String) onSearchChanged;
  final Function(String) onDifficultyChanged;
  final Widget Function(String, String) buildFilterChip;

  _SearchFilterDelegate({
    required this.searchController,
    required this.selectedDifficulty,
    required this.onSearchChanged,
    required this.onDifficultyChanged,
    required this.buildFilterChip,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Bar
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search questions...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.purple, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                buildFilterChip('Easy', 'easy'),
                const SizedBox(width: 8),
                buildFilterChip('Medium', 'medium'),
                const SizedBox(width: 8),
                buildFilterChip('Hard', 'hard'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 130; // Chiều cao tối đa

  @override
  double get minExtent =>
      130; // Chiều cao tối thiểu (giống maxExtent để cố định)

  @override
  bool shouldRebuild(covariant _SearchFilterDelegate oldDelegate) {
    return selectedDifficulty != oldDelegate.selectedDifficulty;
  }
}
