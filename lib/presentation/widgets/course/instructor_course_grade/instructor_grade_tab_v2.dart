// ========================================
// FILE: instructor_grade_tab_v2.dart
// PURPOSE: Grade Tab using Assignment Tracker System
// DESCRIPTION: Refactored to use real-time tracker data instead of mock data
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/domain/models/assignment_tracker_model.dart';
import 'package:elearning_management_app/domain/models/quiz_model.dart';
import 'package:elearning_management_app/domain/models/quiz_tracker_model.dart';
import 'package:elearning_management_app/data/repositories/assignment/assignment_repository.dart';
import 'package:elearning_management_app/data/repositories/assignment_tracker_repository.dart';
import 'package:elearning_management_app/data/repositories/quiz/quiz_repository.dart';
import 'package:elearning_management_app/data/repositories/quiz/quiz_tracker_repository.dart';
import 'package:elearning_management_app/data/services/grade_return_service.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';
import 'grade_filter_bar.dart';
import 'gradebook_table_v2.dart';
import 'quiz_gradebook_table.dart';
import 'gradebook_export_v2.dart';

class InstructorGradeTabV2 extends ConsumerStatefulWidget {
  final CourseModel course;

  const InstructorGradeTabV2({
    super.key,
    required this.course,
  });

  @override
  ConsumerState<InstructorGradeTabV2> createState() =>
      _InstructorGradeTabV2State();
}

class _InstructorGradeTabV2State extends ConsumerState<InstructorGradeTabV2> {
  final AssignmentTrackerRepository _trackerRepo =
      AssignmentTrackerRepository();
  final QuizTrackerRepository _quizTrackerRepo = QuizTrackerRepository();
  final ScrollController _horizontalScrollController = ScrollController();

  // State variables
  List<Assignment> _assignments = [];
  List<Quiz> _quizzes = [];
  bool _isLoadingAssignments = true;
  bool _isLoadingQuizzes = true;
  Set<String> _selectedStudentIds = {};

  // Filter state
  String? _selectedGroup;
  String? _selectedType; // 'assignment', 'quiz', null = all
  String? _selectedItemId; // Selected assignment ID
  String? _selectedStatus; // 'missing', 'submitted', 'late', 'graded'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAssignments();
    _loadQuizzes();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  /// Load assignments for this course
  Future<void> _loadAssignments() async {
    setState(() => _isLoadingAssignments = true);
    try {
      final assignments =
          await AssignmentRepository.getAssignmentsByCourse(widget.course.id);

      if (mounted) {
        setState(() {
          _assignments = assignments;
          _isLoadingAssignments = false;
          // Don't auto-select - wait for user to choose type first
        });
      }
    } catch (e) {
      print('❌ Error loading assignments: $e');
      if (mounted) {
        setState(() => _isLoadingAssignments = false);
      }
    }
  }

  /// Load quizzes for this course
  Future<void> _loadQuizzes() async {
    setState(() => _isLoadingQuizzes = true);
    try {
      final quizRepository = QuizRepository();
      // Use streamQuizzesByCourse and take first value
      final quizzes =
          await quizRepository.streamQuizzesByCourse(widget.course.id).first;

      print(
          '📊 DEBUG: Loaded ${quizzes.length} quizzes for course ${widget.course.id}');
      for (final quiz in quizzes) {
        print('  - Quiz: ${quiz.title} (ID: ${quiz.id})');
      }

      if (mounted) {
        setState(() {
          _quizzes = quizzes;
          _isLoadingQuizzes = false;
        });
      }
    } catch (e) {
      print('❌ Error loading quizzes: $e');
      if (mounted) {
        setState(() => _isLoadingQuizzes = false);
      }
    }
  }

  /// Calculate statistics for QUIZ trackers
  Map<String, int> _calculateQuizStats(List<QuizTrackerModel> trackers) {
    int total = trackers.length;
    int completed = 0;
    int inProgress = 0;
    int notStarted = 0;

    for (final tracker in trackers) {
      switch (tracker.status) {
        case 'completed':
          completed++;
          break;
        case 'in_progress':
          inProgress++;
          break;
        case 'not_started':
          notStarted++;
          break;
      }
    }

    return {
      'students': total,
      'submitted': completed, // "Submitted" = Completed for quiz
      'late': inProgress, // "Late" = In Progress for quiz
      'notSubmitted': notStarted, // "Not Submitted" = Not Started
    };
  }

  /// Get statistics from current tracker list (for assignments)
  Map<String, int> _calculateStats(List<AssignmentTrackerModel> trackers) {
    int total = trackers.length;
    int submitted = 0;
    int late = 0;
    int notSubmitted = 0;

    for (final tracker in trackers) {
      switch (tracker.status) {
        case TrackerStatus.submitted:
        case TrackerStatus.graded:
          submitted++;
          break;
        case TrackerStatus.late:
          late++;
          break;
        case TrackerStatus.missing:
          notSubmitted++;
          break;
      }
    }

    return {
      'students': total,
      'submitted': submitted,
      'late': late,
      'notSubmitted': notSubmitted,
    };
  }

  /// Get available items filtered by selected type
  List<dynamic> _getAvailableItems() {
    if (_selectedType == null) {
      return []; // No type selected = no items
    }

    if (_selectedType == 'quiz') {
      print('📊 DEBUG: Returning ${_quizzes.length} quizzes');
      return _quizzes; // Return actual quiz objects
    } else if (_selectedType == 'assignment') {
      print('📊 DEBUG: Returning ${_assignments.length} assignments');
      return _assignments; // Return actual assignment objects
    }
    return [];
  }

  /// Handle grade update
  Future<void> _handleGradeUpdate(
    String trackerId,
    double grade,
    String? feedback,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Not authenticated');
      }

      await _trackerRepo.updateGrade(
        trackerId: trackerId,
        grade: grade,
        feedback: feedback,
        gradedBy: currentUser.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Grade updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating grade: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update grade: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Export to CSV
  Future<void> _handleExport(List<AssignmentTrackerModel> trackers) async {
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an assignment first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedAssignment = _assignments.firstWhere(
      (a) => a.id == _selectedItemId,
      orElse: () => _assignments.first,
    );

    await GradebookExportV2.downloadAssignmentCSV(
      context: context,
      trackers: trackers,
      assignment: selectedAssignment,
      selectedStudentIds: _selectedStudentIds,
    );
  }

  /// Export Quiz to CSV
  Future<void> _handleQuizExport(List<QuizTrackerModel> trackers) async {
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a quiz first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedQuiz = _quizzes.firstWhere(
      (q) => q.id == _selectedItemId,
      orElse: () => _quizzes.first,
    );

    await GradebookExportV2.downloadQuizCSV(
      context: context,
      trackers: trackers,
      quiz: selectedQuiz,
      selectedStudentIds: _selectedStudentIds,
    );
  }

  /// Return grades to selected students
  Future<void> _handleReturnGrades() async {
    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select students first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an assignment or quiz first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Grades'),
        content: Text(
          'Return grades to ${_selectedStudentIds.length} selected student(s)?\n\n'
          'Students will receive notifications and can view their grades.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Return Grades'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Returning grades...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      final gradeReturnService = GradeReturnService();

      // Return grades based on type
      Map<String, dynamic> result;
      if (_selectedType == 'assignment') {
        result = await gradeReturnService.returnAssignmentGrades(
          assignmentId: _selectedItemId!,
          courseId: widget.course.id,
          studentIds: _selectedStudentIds.toList(),
        );
      } else if (_selectedType == 'quiz') {
        result = await gradeReturnService.returnQuizGrades(
          quizId: _selectedItemId!,
          courseId: widget.course.id,
          studentIds: _selectedStudentIds.toList(),
        );
      } else {
        throw Exception('Invalid type selected');
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show result
      if (context.mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Grades returned successfully to ${_selectedStudentIds.length} student(s)',
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Clear selection
          setState(() {
            _selectedStudentIds.clear();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['error'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error returning grades: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAssignments || _isLoadingQuizzes) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_assignments.isEmpty && _quizzes.isEmpty) {
      return _buildEmptyState();
    }

    // Make everything scrollable together - no sticky filter bar
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar (scrolls with content)
          // Need to fetch availableGroups - use StreamBuilder for dynamic groups
          _selectedItemId != null
              ? StreamBuilder<List<AssignmentTrackerModel>>(
                  stream: _trackerRepo.streamTrackersForAssignment(
                    _selectedItemId!,
                    groupId: null,
                    status: null,
                  ),
                  builder: (context, groupSnapshot) {
                    final availableGroups = groupSnapshot.hasData
                        ? _getAvailableGroups(groupSnapshot.data!)
                        : <String>[];

                    return GradeFilterBar(
                      searchQuery: _searchQuery,
                      selectedGroup: _selectedGroup,
                      selectedType: _selectedType,
                      selectedItemId: _selectedItemId,
                      selectedStatus: _selectedStatus,
                      assignments: _assignments,
                      availableGroups: availableGroups,
                      availableItems: _getAvailableItems(),
                      isItemDisabled: _selectedType == null,
                      onSearchChanged: (query) =>
                          setState(() => _searchQuery = query),
                      onGroupChanged: (group) =>
                          setState(() => _selectedGroup = group),
                      onTypeChanged: (type) {
                        setState(() {
                          _selectedType = type;
                          _selectedItemId = null;
                          _selectedGroup = null;
                          _selectedStudentIds.clear();
                        });
                      },
                      onItemChanged: (itemId) {
                        setState(() {
                          _selectedItemId = itemId;
                          _selectedGroup = null;
                          _selectedStudentIds.clear();
                        });
                      },
                      onStatusChanged: (status) =>
                          setState(() => _selectedStatus = status),
                      onReset: () {
                        setState(() {
                          _searchQuery = '';
                          _selectedType = null;
                          _selectedItemId = null;
                          _selectedGroup = null;
                          _selectedStatus = null;
                          _selectedStudentIds.clear();
                        });
                      },
                    );
                  },
                )
              : GradeFilterBar(
                  searchQuery: _searchQuery,
                  selectedGroup: _selectedGroup,
                  selectedType: _selectedType,
                  selectedItemId: _selectedItemId,
                  selectedStatus: _selectedStatus,
                  assignments: _assignments,
                  availableGroups: const [],
                  availableItems: _getAvailableItems(),
                  isItemDisabled: _selectedType == null,
                  onSearchChanged: (query) =>
                      setState(() => _searchQuery = query),
                  onGroupChanged: (group) =>
                      setState(() => _selectedGroup = group),
                  onTypeChanged: (type) {
                    setState(() {
                      _selectedType = type;
                      _selectedItemId = null;
                      _selectedGroup = null;
                      _selectedStudentIds.clear();
                    });
                  },
                  onItemChanged: (itemId) {
                    setState(() {
                      _selectedItemId = itemId;
                      _selectedGroup = null;
                      _selectedStudentIds.clear();
                    });
                  },
                  onStatusChanged: (status) =>
                      setState(() => _selectedStatus = status),
                  onReset: () {
                    setState(() {
                      _searchQuery = '';
                      _selectedType = null;
                      _selectedItemId = null;
                      _selectedGroup = null;
                      _selectedStatus = null;
                      _selectedStudentIds.clear();
                    });
                  },
                ),
          const SizedBox(height: 16),

          // Show warning OR show data (no Expanded needed in scrollable)
          (_selectedType == null || _selectedItemId == null)
              ? _buildSelectAssignmentPrompt()
              : _buildGradebookContent(),
        ],
      ),
    );
  }

  /// Build gradebook content with data
  Widget _buildGradebookContent() {
    // Check if selected type is quiz or assignment
    if (_selectedType == 'quiz') {
      return _buildQuizGradebookContent();
    } else {
      return _buildAssignmentGradebookContent();
    }
  }

  /// Build gradebook content for QUIZ trackers
  Widget _buildQuizGradebookContent() {
    print('📊 DEBUG: Building quiz gradebook for quiz ID: $_selectedItemId');

    return StreamBuilder<List<QuizTrackerModel>>(
      stream: _quizTrackerRepo.streamTrackersForQuiz(
        _selectedItemId!,
        groupId: null,
        status: _selectedStatus,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          print('❌ DEBUG: Error loading quiz trackers: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print('📊 DEBUG: No quiz trackers found');
          return _buildNoDataState();
        }

        final trackers = snapshot.data!;
        print('📊 DEBUG: Loaded ${trackers.length} quiz trackers');

        // Apply filters client-side
        var filteredTrackers = trackers;

        // Filter by group name
        if (_selectedGroup != null && _selectedGroup != 'All') {
          filteredTrackers = filteredTrackers
              .where((t) => t.groupName == _selectedGroup)
              .toList();
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          filteredTrackers = filteredTrackers.where((t) {
            return t.studentName.toLowerCase().contains(query) ||
                t.studentEmail.toLowerCase().contains(query);
          }).toList();
        }

        // Calculate stats for quiz trackers using dedicated function
        final stats = _calculateQuizStats(filteredTrackers);

        // Get selected quiz
        final selectedQuiz =
            _quizzes.firstWhere((q) => q.id == _selectedItemId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatisticsBar(stats),
            const SizedBox(height: 16),
            _buildSearchAndExportRow(filteredTrackers),
            const SizedBox(height: 16),

            // Use QuizGradebookTable instead of GradebookTableV2
            QuizGradebookTable(
              trackers: filteredTrackers,
              quiz: selectedQuiz,
              selectedStudentIds: _selectedStudentIds,
              onStudentSelected: (studentId) {
                setState(() {
                  if (_selectedStudentIds.contains(studentId)) {
                    _selectedStudentIds.remove(studentId);
                  } else {
                    _selectedStudentIds.add(studentId);
                  }
                });
              },
              onGradeUpdate: (trackerId, grade, feedback) async {
                // Handle quiz grade update
                final parts = trackerId.split('_');
                if (parts.length == 2) {
                  final quizId = parts[0];
                  final studentId = parts[1];
                  await _quizTrackerRepo.updateGrade(
                      quizId, studentId, grade ?? 0);
                }
              },
              horizontalScrollController: _horizontalScrollController,
            ),
          ],
        );
      },
    );
  }

  /// Build gradebook content for ASSIGNMENT trackers
  Widget _buildAssignmentGradebookContent() {
    // Stream trackers for selected assignment
    return StreamBuilder<List<AssignmentTrackerModel>>(
      stream: _trackerRepo.streamTrackersForAssignment(
        _selectedItemId!,
        groupId: null, // Don't filter by groupId in query, filter client-side
        status: _selectedStatus != null
            ? TrackerStatusExtension.fromString(_selectedStatus!)
            : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildNoDataState();
        }

        final trackers = snapshot.data!;

        // Apply filters client-side
        var filteredTrackers = trackers;

        // Filter by group name
        if (_selectedGroup != null && _selectedGroup != 'All') {
          filteredTrackers = filteredTrackers
              .where((t) => t.groupName == _selectedGroup)
              .toList();
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          filteredTrackers = filteredTrackers.where((t) {
            return t.studentName.toLowerCase().contains(query) ||
                t.studentEmail.toLowerCase().contains(query);
          }).toList();
        }

        final stats = _calculateStats(filteredTrackers);

        // Return content without nested SingleChildScrollView
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Bar
            _buildStatisticsBar(stats),
            const SizedBox(height: 16),

            // Search + Export Row
            _buildSearchAndExportRow(filteredTrackers),
            const SizedBox(height: 16),

            // Gradebook Table V2 (uses tracker data directly)
            GradebookTableV2(
              trackers: filteredTrackers,
              assignment:
                  _assignments.firstWhere((a) => a.id == _selectedItemId),
              horizontalScrollController: _horizontalScrollController,
              selectedStudentIds: _selectedStudentIds,
              onSelectionChanged: (ids) =>
                  setState(() => _selectedStudentIds = ids),
              onGradeUpdated: (trackerId, grade, feedback) async {
                await _handleGradeUpdate(trackerId, grade, feedback);
              },
            ),
          ],
        );
      },
    );
  }

  /// Build statistics bar
  Widget _buildStatisticsBar(Map<String, int> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return _buildMobileStats(stats);
        } else {
          return _buildDesktopStats(stats);
        }
      },
    );
  }

  Widget _buildMobileStats(Map<String, int> stats) {
    final isQuiz = _selectedType == 'quiz';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Students',
                  stats['students'] ?? 0,
                  Icons.people,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  isQuiz ? 'Completed' : 'Submitted',
                  stats['submitted'] ?? 0,
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  isQuiz ? 'In Progress' : 'Late',
                  stats['late'] ?? 0,
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  isQuiz ? 'Not Started' : 'Not Submitted',
                  stats['notSubmitted'] ?? 0,
                  Icons.cancel,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStats(Map<String, int> stats) {
    final isQuiz = _selectedType == 'quiz';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Students',
              stats['students'] ?? 0,
              Icons.people,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              isQuiz ? 'Completed' : 'Submitted',
              stats['submitted'] ?? 0,
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              isQuiz ? 'In Progress' : 'Late',
              stats['late'] ?? 0,
              Icons.schedule,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              isQuiz ? 'Not Started' : 'Not Submitted',
              stats['notSubmitted'] ?? 0,
              Icons.cancel,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build search bar + export button row
  Widget _buildSearchAndExportRow(List<dynamic> trackers) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Row(
          children: [
            // Search field
            Expanded(
              child: TextField(
                onChanged: (query) => setState(() => _searchQuery = query),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by name, ID, or group...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Clear selection button (if any selected)
            if (_selectedStudentIds.isNotEmpty) ...[
              if (!isMobile)
                TextButton.icon(
                  onPressed: () => setState(() => _selectedStudentIds.clear()),
                  icon: const Icon(Icons.clear, size: 18),
                  label: Text('Clear (${_selectedStudentIds.length})'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                )
              else
                IconButton(
                  onPressed: () => setState(() => _selectedStudentIds.clear()),
                  tooltip: 'Clear ${_selectedStudentIds.length} selected',
                  icon: Badge(
                    label: Text('${_selectedStudentIds.length}'),
                    child: const Icon(Icons.clear, size: 20),
                  ),
                ),
              const SizedBox(width: 8),
            ],

            // Return button (only show when students are selected) - ICON ONLY
            if (_selectedStudentIds.isNotEmpty) ...[
              IconButton(
                onPressed: _handleReturnGrades,
                tooltip:
                    'Return Grades to ${_selectedStudentIds.length} student(s)',
                icon: const Icon(Icons.assignment_turned_in, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Export button - ICON ONLY
            // Show export for both assignment and quiz trackers
            if (_selectedType == 'assignment') ...[
              IconButton(
                onPressed: () =>
                    _handleExport(trackers.cast<AssignmentTrackerModel>()),
                tooltip: 'Export Assignment CSV',
                icon: const Icon(Icons.file_download, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else if (_selectedType == 'quiz') ...[
              IconButton(
                onPressed: () =>
                    _handleQuizExport(trackers.cast<QuizTrackerModel>()),
                tooltip: 'Export Quiz CSV',
                icon: const Icon(Icons.file_download, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Get available groups from trackers (returns group names)
  List<String> _getAvailableGroups(List<AssignmentTrackerModel> trackers) {
    final Set<String> groups = {};
    for (final tracker in trackers) {
      if (tracker.groupName.isNotEmpty) {
        groups.add(tracker.groupName);
      }
    }
    return groups.toList();
  }

  /// Build empty state (no assignments)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No assignments in this course yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create an assignment to start tracking grades',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Build prompt to select type and assignment
  Widget _buildSelectAssignmentPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 80,
            color: AppColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Please Select Type and Item',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You must choose both Type and Item from the filters above to view the gradebook table',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error loading grade data',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAssignments,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Build no data state (assignment has no trackers yet)
  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tracking data available',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Trackers will be created when assignment is assigned to groups',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
