import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elearning_management_app/presentation/widgets/student/course/assignment/assignment_card.dart';
import 'package:elearning_management_app/presentation/widgets/student/course/material/material_card.dart';
import 'package:elearning_management_app/presentation/widgets/student/course/quiz/student_quiz_card.dart';
import 'package:elearning_management_app/presentation/widgets/student/course/quiz/quiz_lobby_screen.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/domain/models/quiz_model.dart';
import 'package:elearning_management_app/data/repositories/assignment/assignment_repository.dart';
import 'package:elearning_management_app/data/repositories/assignment_tracker_repository.dart';
import 'package:elearning_management_app/data/repositories/material/material_repository.dart';
import 'package:elearning_management_app/data/repositories/quiz/quiz_repository.dart';
import 'package:elearning_management_app/data/repositories/group/group_repository.dart';
import 'package:elearning_management_app/data/repositories/course/enrollment_repository.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/domain/models/material_model.dart';
import 'package:elearning_management_app/presentation/screens/student/course/tab_course/classwork/assignment_detail_page.dart';

// StreamProvider for real-time assignment updates (FILTERED BY TRACKER)
// Only shows assignments that the student has a tracker for (respects group changes)
final studentAssignmentStreamProvider =
    StreamProvider.family<List<Assignment>, String>((ref, courseId) async* {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    yield [];
    return;
  }

  final studentId = currentUser.uid;
  final trackerRepository = AssignmentTrackerRepository();

  // Listen to student's trackers for this course
  await for (final trackers in trackerRepository.streamTrackersForStudent(
    studentId,
    courseId: courseId,
  )) {
    // Extract assignment IDs from trackers (tracker acts as whitelist)
    final assignmentIds = trackers.map((t) => t.assignmentId).toList();

    if (assignmentIds.isEmpty) {
      yield [];
      continue;
    }

    // Query assignments by IDs (only assignments student has tracker for)
    final assignments = await Future.wait(
      assignmentIds.map((id) => AssignmentRepository.getAssignmentById(id)),
    );

    // Filter out nulls
    yield assignments.whereType<Assignment>().toList();
  }
});

// StreamProvider for real-time material updates
final studentMaterialStreamProvider =
    StreamProvider.family<List<MaterialModel>, String>((ref, courseId) {
  return MaterialRepository.listenToMaterials(courseId);
});

// StreamProvider for real-time quiz updates (FILTERED BY STUDENT'S GROUPS)
final studentQuizStreamProvider =
    StreamProvider.family<List<Quiz>, String>((ref, courseId) async* {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    yield [];
    return;
  }

  final studentId = currentUser.uid;

  // Stream all quizzes for the course first (simple query, no index needed)
  final repository = QuizRepository();

  // Get student's group IDs once
  List<String> studentGroupIds = [];
  try {
    final enrollmentRepository = EnrollmentRepository();
    final allEnrollments =
        await enrollmentRepository.getCoursesOfStudent(studentId);
    final enrollments =
        allEnrollments.where((e) => e.courseId == courseId).toList();
    studentGroupIds = enrollments.map((e) => e.groupId).toSet().toList();
  } catch (e) {
    print('Error getting student enrollments: $e');
  }

  // Stream and filter quizzes by group IDs in memory
  await for (final allQuizzes in repository.streamQuizzesByCourse(courseId)) {
    if (studentGroupIds.isEmpty) {
      // No enrollments = no quizzes visible
      yield [];
      continue;
    }

    // Client-side filtering by groupIds
    final filteredQuizzes = allQuizzes.where((quiz) {
      if (quiz.groupIds == null || quiz.groupIds!.isEmpty) {
        return true; // No group restriction = visible to all
      }
      if (quiz.groupIds!.contains('all')) {
        return true; // 'all' = visible to everyone
      }
      // Check if student's group is in quiz's allowed groups
      return quiz.groupIds!.any((groupId) => studentGroupIds.contains(groupId));
    }).toList();

    yield filteredQuizzes;
  }
});

class ClassworkTab extends ConsumerStatefulWidget {
  final CourseModel course;

  const ClassworkTab({super.key, required this.course});

  @override
  ConsumerState<ClassworkTab> createState() => _ClassworkTabState();
}

class _ClassworkTabState extends ConsumerState<ClassworkTab> {
  final GlobalKey _categoryFilterButtonKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedCategory; // null = "All Types"
  String _selectedCategoryName = 'All Types';
  final List<Map<String, String>> _categories = [
    {'id': 'assignment', 'name': 'Assignments'},
    {'id': 'quiz', 'name': 'Quizzes'},
    {'id': 'material', 'name': 'Materials'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Section (Category only - no Group filter for students)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Row(
              children: [
                Icon(Icons.category_outlined,
                    color: Colors.grey[400], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Filter by Type:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 120,
                      maxWidth: 250,
                    ),
                    child: InkWell(
                      key: _categoryFilterButtonKey,
                      onTap: () => _showCategoryFilterMenu(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedCategory != null
                                ? Colors.indigo
                                : Colors.grey[700]!,
                            width: _selectedCategory != null ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedCategory != null
                                  ? Icons.check_box_outlined
                                  : Icons.category,
                              size: 18,
                              color: _selectedCategory != null
                                  ? Colors.indigo
                                  : Colors.grey[400],
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _selectedCategoryName,
                                style: TextStyle(
                                  color: _selectedCategory != null
                                      ? Colors.indigo
                                      : Colors.grey[300],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_drop_down,
                                size: 20, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Class Materials',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.sort, size: 18),
                label: const Text('Sort'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo[400],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Search Box
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search assignments by title...',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon:
                          Icon(Icons.clear, color: Colors.grey[400], size: 20),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),

          const SizedBox(height: 20),

          // Merged Assignments and Materials List (Sorted by createdAt)
          Consumer(
            builder: (context, ref, child) {
              final assignmentsAsync =
                  ref.watch(studentAssignmentStreamProvider(widget.course.id));
              final materialsAsync =
                  ref.watch(studentMaterialStreamProvider(widget.course.id));
              final quizzesAsync =
                  ref.watch(studentQuizStreamProvider(widget.course.id));

              // Wait for all streams to load
              if (assignmentsAsync.isLoading ||
                  materialsAsync.isLoading ||
                  quizzesAsync.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                  ),
                );
              }

              // Handle errors
              if (assignmentsAsync.hasError ||
                  materialsAsync.hasError ||
                  quizzesAsync.hasError) {
                final error = assignmentsAsync.hasError
                    ? assignmentsAsync.error
                    : materialsAsync.hasError
                        ? materialsAsync.error
                        : quizzesAsync.error;
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading classwork',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // Get data from all streams
              final assignments = assignmentsAsync.value ?? [];
              final materials = materialsAsync.value ?? [];
              final quizzes = quizzesAsync.value ?? [];

              // Apply search filter to assignments
              var filteredAssignments = assignments;
              if (_searchQuery.isNotEmpty) {
                filteredAssignments = assignments
                    .where((assignment) =>
                        assignment.title.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              // Apply search filter to materials
              var filteredMaterials = materials;
              if (_searchQuery.isNotEmpty) {
                filteredMaterials = materials
                    .where((material) =>
                        material.title.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              // Apply search filter to quizzes
              var filteredQuizzes = quizzes;
              if (_searchQuery.isNotEmpty) {
                filteredQuizzes = quizzes
                    .where((quiz) =>
                        quiz.title.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              // Apply category filter
              if (_selectedCategory != null) {
                if (_selectedCategory == 'assignment') {
                  filteredMaterials = [];
                  filteredQuizzes = [];
                } else if (_selectedCategory == 'material') {
                  filteredAssignments = [];
                  filteredQuizzes = [];
                } else if (_selectedCategory == 'quiz') {
                  filteredAssignments = [];
                  filteredMaterials = [];
                }
              }

              // Create merged list with type information
              List<Map<String, dynamic>> mergedItems = [];

              // Add assignments with type marker
              for (var assignment in filteredAssignments) {
                mergedItems.add({
                  'type': 'assignment',
                  'data': assignment,
                  'createdAt': assignment.createdAt,
                });
              }

              // Add materials with type marker
              for (var material in filteredMaterials) {
                mergedItems.add({
                  'type': 'material',
                  'data': material,
                  'createdAt': material.createdAt,
                });
              }

              // Add quizzes with type marker
              for (var quiz in filteredQuizzes) {
                mergedItems.add({
                  'type': 'quiz',
                  'data': quiz,
                  'createdAt': quiz.openDate ?? DateTime.now(),
                });
              }

              // Sort merged list by createdAt (newest first)
              mergedItems.sort((a, b) {
                final aTime = a['createdAt'] as DateTime;
                final bTime = b['createdAt'] as DateTime;
                return bTime.compareTo(aTime); // Descending order
              });

              // Check if empty
              if (mergedItems.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined,
                          size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No results found for "$_searchQuery"'
                            : _selectedCategory != null
                                ? 'No ${_selectedCategoryName.toLowerCase()} yet'
                                : 'No classwork yet',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Try a different search term'
                            : 'Classwork will appear here when they are created',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              // Render merged list
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: mergedItems.map((item) {
                  final type = item['type'] as String;

                  if (type == 'assignment') {
                    final assignment = item['data'] as Assignment;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AssignmentCard(
                        assignment: assignment,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssignmentDetailView(
                                assignment: assignment,
                                course: widget.course,
                                onBack: () => Navigator.pop(context),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  } else if (type == 'material') {
                    final material = item['data'] as MaterialModel;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MaterialCard(
                        material: material,
                        // onTap is handled by MaterialCard internally
                      ),
                    );
                  } else if (type == 'quiz') {
                    final quiz = item['data'] as Quiz;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: StudentQuizCard(
                        quiz: quiz,
                        onTap: () async {
                          // Fetch full quiz details and navigate to lobby
                          final quizRepository = QuizRepository();
                          final fullQuiz = await quizRepository.getQuizById(
                            widget.course.id,
                            quiz.id,
                          );

                          if (fullQuiz != null && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizLobbyScreen(
                                  quiz: fullQuiz,
                                  courseId: widget.course.id,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 16), // Bottom padding
        ],
      ),
    );
  }

  void _showCategoryFilterMenu(BuildContext context) {
    final RenderBox renderBox = _categoryFilterButtonKey.currentContext!
        .findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height + 8,
        position.dx + size.width,
        position.dy + size.height + 8,
      ),
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      items: <PopupMenuEntry<String?>>[
        // "All Types" option
        PopupMenuItem<String?>(
          value: null,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _selectedCategory == null
                      ? Colors.indigo.withOpacity(0.2)
                      : Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.category,
                  color:
                      _selectedCategory == null ? Colors.indigo : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'All Types',
                  style: TextStyle(
                    color: _selectedCategory == null
                        ? Colors.indigo
                        : Colors.white,
                    fontWeight: _selectedCategory == null
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              if (_selectedCategory == null)
                const Icon(Icons.check, color: Colors.indigo, size: 20),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        // Category options
        ..._categories.map((category) {
          final categoryId = category['id']!;
          final categoryName = category['name']!;
          final isSelected = _selectedCategory == categoryId;

          IconData icon;
          Color color;
          switch (categoryId) {
            case 'assignment':
              icon = Icons.assignment_outlined;
              color = Colors.blue;
              break;
            case 'quiz':
              icon = Icons.quiz_outlined;
              color = Colors.green;
              break;
            case 'material':
              icon = Icons.menu_book_outlined;
              color = Colors.orange;
              break;
            default:
              icon = Icons.description;
              color = Colors.grey;
          }

          return PopupMenuItem<String?>(
            value: categoryId,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.indigo.withOpacity(0.2)
                        : color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.indigo : color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      color: isSelected ? Colors.indigo : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: Colors.indigo, size: 20),
              ],
            ),
          );
        }),
      ],
    ).then((selectedValue) {
      if (selectedValue != null || selectedValue == null) {
        setState(() {
          _selectedCategory = selectedValue;
          if (selectedValue == null) {
            _selectedCategoryName = 'All Types';
          } else {
            _selectedCategoryName = _categories
                .firstWhere((c) => c['id'] == selectedValue)['name']!;
          }
        });
      }
    });
  }
}
