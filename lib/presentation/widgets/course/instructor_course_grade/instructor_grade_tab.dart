import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/domain/models/enrollment_model.dart';
import 'package:elearning_management_app/data/repositories/course/enrollment_repository.dart';
import 'package:elearning_management_app/data/repositories/assignment/assignment_repository.dart';
import 'package:elearning_management_app/data/repositories/submission/submission_repository.dart';
import 'package:elearning_management_app/domain/models/submission_model.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';
import 'grade_filter_bar.dart';
import 'gradebook_table.dart';
import 'gradebook_export.dart';

class InstructorGradeTab extends ConsumerStatefulWidget {
  final CourseModel course;

  const InstructorGradeTab({
    super.key,
    required this.course,
  });

  @override
  ConsumerState<InstructorGradeTab> createState() => _InstructorGradeTabState();
}

class _InstructorGradeTabState extends ConsumerState<InstructorGradeTab> {
  bool _isLoading = true;
  List<EnrollmentModel> _students = [];
  List<Assignment> _assignments = [];
  Map<String, Map<String, SubmissionModel?>> _gradebook = {};
  
  List<MockGradeData> _mockGradeData = [];
  List<MockGradeData> _filteredGradeData = [];
  List<Assignment> _cachedFilteredAssignments = [];
  Set<String> _selectedStudentIds = {};
  final ScrollController _horizontalScrollController = ScrollController();
  String? _selectedGroup;
  String? _selectedType; // 'All', 'assignment', 'quiz'
  String? _selectedItemId; // ID của assignment/quiz được chọn
  String? _selectedStatus; // 'all', 'submitted', 'late', 'not_submitted'
  double? _minScore;
  double? _maxScore;
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'group', 'score', 'deadline'
  bool _sortAscending = true;
  

  @override
  void initState() {
    super.initState();
    _loadGradebook();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGradebook() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final enrollmentRepo = EnrollmentRepository();
      _students = await enrollmentRepo.getStudentsInCourse(widget.course.id);
      _assignments = await AssignmentRepository.getAssignmentsByCourse(widget.course.id);
      _assignments.sort((a, b) => a.deadline.compareTo(b.deadline));
      final submissions = await SubmissionRepository.getSubmissionsByCourse(widget.course.id);

      _gradebook = {};
      for (final student in _students) {
        _gradebook[student.userId] = {};
        for (final assignment in _assignments) {
          try {
            final submission = submissions.firstWhere(
              (s) => s.studentId == student.userId && s.assignmentId == assignment.id,
            );
            _gradebook[student.userId]![assignment.id] = submission;
          } catch (e) {
            _gradebook[student.userId]![assignment.id] = null;
          }
        }
      }

      if (_assignments.isEmpty) {
        final now = DateTime.now();
        _assignments = [
          Assignment(
            id: 'mock_assignment_1',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Assignment 1',
            description: 'Mock assignment',
            startDate: now,
            deadline: now.add(const Duration(days: 7)),
          ),
          Assignment(
            id: 'mock_assignment_2',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Assignment 2',
            description: 'Mock assignment',
            startDate: now,
            deadline: now.add(const Duration(days: 14)),
          ),
          Assignment(
            id: 'mock_assignment_3',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Quiz 1',
            description: 'Mock quiz',
            startDate: now,
            deadline: now.add(const Duration(days: 21)),
          ),
          Assignment(
            id: 'mock_assignment_4',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Assignment 3',
            description: 'Mock assignment',
            startDate: now,
            deadline: now.add(const Duration(days: 28)),
          ),
          Assignment(
            id: 'mock_assignment_5',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Quiz 2',
            description: 'Mock quiz',
            startDate: now,
            deadline: now.add(const Duration(days: 35)),
          ),
          Assignment(
            id: 'mock_assignment_6',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Assignment 4',
            description: 'Mock assignment',
            startDate: now,
            deadline: now.add(const Duration(days: 42)),
          ),
          Assignment(
            id: 'mock_assignment_7',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Midterm Exam',
            description: 'Mock exam',
            startDate: now,
            deadline: now.add(const Duration(days: 49)),
          ),
          Assignment(
            id: 'mock_assignment_8',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Assignment 5',
            description: 'Mock assignment',
            startDate: now,
            deadline: now.add(const Duration(days: 56)),
          ),
          Assignment(
            id: 'mock_assignment_9',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Quiz 3',
            description: 'Mock quiz',
            startDate: now,
            deadline: now.add(const Duration(days: 63)),
          ),
          Assignment(
            id: 'mock_assignment_10',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Assignment 6',
            description: 'Mock assignment',
            startDate: now,
            deadline: now.add(const Duration(days: 70)),
          ),
          Assignment(
            id: 'mock_assignment_11',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Quiz 4',
            description: 'Mock quiz',
            startDate: now,
            deadline: now.add(const Duration(days: 77)),
          ),
          Assignment(
            id: 'mock_assignment_12',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Assignment 7',
            description: 'Mock assignment',
            startDate: now,
            deadline: now.add(const Duration(days: 84)),
          ),
          Assignment(
            id: 'mock_assignment_13',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Final Exam',
            description: 'Mock exam',
            startDate: now,
            deadline: now.add(const Duration(days: 91)),
          ),
          Assignment(
            id: 'mock_assignment_14',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Assignment 8',
            description: 'Mock assignment',
            startDate: now,
            deadline: now.add(const Duration(days: 98)),
          ),
          Assignment(
            id: 'mock_assignment_15',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Quiz 5',
            description: 'Mock quiz',
            startDate: now,
            deadline: now.add(const Duration(days: 105)),
          ),
        ];
      }

      _generateMockData();
      _applyFilters();
    } catch (e) {
      print('DEBUG: ❌ Error loading gradebook: $e');
      if (_assignments.isEmpty) {
        final now = DateTime.now();
        _assignments = [
          Assignment(
            id: 'mock_assignment_1',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Assignment 1',
            description: 'Mock assignment',
            startDate: now,
            deadline: now.add(const Duration(days: 7)),
          ),
          Assignment(
            id: 'mock_assignment_2',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Assignment 2',
            description: 'Mock assignment',
            startDate: now,
            deadline: now.add(const Duration(days: 14)),
          ),
          Assignment(
            id: 'mock_assignment_3',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Quiz 1',
            description: 'Mock quiz',
            startDate: now,
            deadline: now.add(const Duration(days: 21)),
          ),
          Assignment(
            id: 'mock_assignment_4',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Assignment 3',
            description: 'Mock assignment',
            startDate: now,
            deadline: now.add(const Duration(days: 28)),
          ),
          Assignment(
            id: 'mock_assignment_5',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Quiz 2',
            description: 'Mock quiz',
            startDate: now,
            deadline: now.add(const Duration(days: 35)),
          ),
          Assignment(
            id: 'mock_assignment_6',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Assignment 4',
            description: 'Mock assignment',
            startDate: now,
            deadline: now.add(const Duration(days: 42)),
          ),
          Assignment(
            id: 'mock_assignment_7',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Midterm Exam',
            description: 'Mock exam',
            startDate: now,
            deadline: now.add(const Duration(days: 49)),
          ),
          Assignment(
            id: 'mock_assignment_8',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Assignment 5',
            description: 'Mock assignment',
            startDate: now,
            deadline: now.add(const Duration(days: 56)),
          ),
          Assignment(
            id: 'mock_assignment_9',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Quiz 3',
            description: 'Mock quiz',
            startDate: now,
            deadline: now.add(const Duration(days: 63)),
          ),
          Assignment(
            id: 'mock_assignment_10',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Assignment 6',
            description: 'Mock assignment',
            startDate: now,
            deadline: now.add(const Duration(days: 70)),
          ),
          Assignment(
            id: 'mock_assignment_11',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Quiz 4',
            description: 'Mock quiz',
            startDate: now,
            deadline: now.add(const Duration(days: 77)),
          ),
          Assignment(
            id: 'mock_assignment_12',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Assignment 7',
            description: 'Mock assignment',
            startDate: now,
            deadline: now.add(const Duration(days: 84)),
          ),
          Assignment(
            id: 'mock_assignment_13',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Final Exam',
            description: 'Mock exam',
            startDate: now,
            deadline: now.add(const Duration(days: 91)),
          ),
          Assignment(
            id: 'mock_assignment_14',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Assignment 8',
            description: 'Mock assignment',
            startDate: now,
            deadline: now.add(const Duration(days: 98)),
          ),
          Assignment(
            id: 'mock_assignment_15',
            courseId: widget.course.id,
            semesterId: widget.course.semester,
            title: 'Quiz 5',
            description: 'Mock quiz',
            startDate: now,
            deadline: now.add(const Duration(days: 105)),
          ),
        ];
      }
      _generateMockData();
      _applyFilters();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _generateMockData() {
    final groups = ['Group A', 'Group B', 'Group C', 'Group D'];
    
    _mockGradeData = [];
    
    List<Assignment> assignmentsToUse = _assignments;
    if (assignmentsToUse.isEmpty) {
      final now = DateTime.now();
      assignmentsToUse = [
        Assignment(
          id: 'mock_assignment_1',
          courseId: widget.course.id,
          semesterId: widget.course.semester,
          title: 'Assignment 1',
          description: 'Mock assignment',
          startDate: now,
          deadline: now.add(const Duration(days: 7)),
        ),
        Assignment(
          id: 'mock_assignment_2',
          courseId: widget.course.id,
          semesterId: widget.course.semester,
          title: 'Assignment 2',
          description: 'Mock assignment',
          startDate: now,
          deadline: now.add(const Duration(days: 14)),
        ),
        Assignment(
          id: 'mock_assignment_3',
          courseId: widget.course.id,
          semesterId: widget.course.semester,
          title: 'Quiz 1',
          description: 'Mock quiz',
          startDate: now,
          deadline: now.add(const Duration(days: 21)),
        ),
        Assignment(
          id: 'mock_assignment_4',
          courseId: widget.course.id,
          semesterId: widget.course.semester,
          title: 'Assignment 3',
          description: 'Mock assignment',
          startDate: now,
          deadline: now.add(const Duration(days: 28)),
        ),
        Assignment(
          id: 'mock_assignment_5',
          courseId: widget.course.id,
          semesterId: widget.course.semester,
          title: 'Quiz 2',
          description: 'Mock quiz',
          startDate: now,
          deadline: now.add(const Duration(days: 35)),
        ),
        Assignment(
          id: 'mock_assignment_6',
          courseId: widget.course.id,
          semesterId: widget.course.semester,
          title: 'Assignment 4',
          description: 'Mock assignment',
          startDate: now,
          deadline: now.add(const Duration(days: 42)),
        ),
        Assignment(
          id: 'mock_assignment_7',
          courseId: widget.course.id,
          semesterId: widget.course.semester,
          title: 'Midterm Exam',
          description: 'Mock exam',
          startDate: now,
          deadline: now.add(const Duration(days: 49)),
        ),
        Assignment(
          id: 'mock_assignment_8',
          courseId: widget.course.id,
          semesterId: widget.course.semester,
          title: 'Assignment 5',
          description: 'Mock assignment',
          startDate: now,
          deadline: now.add(const Duration(days: 56)),
        ),
        Assignment(
          id: 'mock_assignment_9',
          courseId: widget.course.id,
          semesterId: widget.course.semester,
          title: 'Quiz 3',
          description: 'Mock quiz',
          startDate: now,
          deadline: now.add(const Duration(days: 63)),
        ),
        Assignment(
          id: 'mock_assignment_10',
          courseId: widget.course.id,
          semesterId: widget.course.semester,
          title: 'Assignment 6',
          description: 'Mock assignment',
          startDate: now,
          deadline: now.add(const Duration(days: 70)),
        ),
        Assignment(
          id: 'mock_assignment_11',
          courseId: widget.course.id,
          semesterId: widget.course.semester,
          title: 'Quiz 4',
          description: 'Mock quiz',
          startDate: now,
          deadline: now.add(const Duration(days: 77)),
        ),
        Assignment(
          id: 'mock_assignment_12',
          courseId: widget.course.id,
          semesterId: widget.course.semester,
          title: 'Assignment 7',
          description: 'Mock assignment',
          startDate: now,
          deadline: now.add(const Duration(days: 84)),
        ),
        Assignment(
          id: 'mock_assignment_13',
          courseId: widget.course.id,
          semesterId: widget.course.semester,
          title: 'Final Exam',
          description: 'Mock exam',
          startDate: now,
          deadline: now.add(const Duration(days: 91)),
        ),
        Assignment(
          id: 'mock_assignment_14',
          courseId: widget.course.id,
          semesterId: widget.course.semester,
          title: 'Assignment 8',
          description: 'Mock assignment',
          startDate: now,
          deadline: now.add(const Duration(days: 98)),
        ),
        Assignment(
          id: 'mock_assignment_15',
          courseId: widget.course.id,
          semesterId: widget.course.semester,
          title: 'Quiz 5',
          description: 'Mock quiz',
          startDate: now,
          deadline: now.add(const Duration(days: 105)),
        ),
      ];
    }
    
    final studentsToUse = _students.isNotEmpty ? _students : null;
    final studentCount = studentsToUse?.length ?? 15;
    
    for (int i = 0; i < studentCount; i++) {
      final student = studentsToUse != null && i < studentsToUse.length 
          ? studentsToUse[i] 
          : null;
      
      String groupName;
      if (student?.groupId?.isNotEmpty == true) {
        final groupIndex = student!.groupId!.hashCode % groups.length;
        groupName = groups[groupIndex.abs()];
      } else {
        groupName = groups[i % groups.length];
      }
      
      final submissions = <String, MockSubmissionData>{};
      
      for (int j = 0; j < assignmentsToUse.length; j++) {
        final assignment = assignmentsToUse[j];
        SubmissionModel? realSubmission;
        if (student != null && _gradebook.containsKey(student.userId)) {
          final studentSubmissions = _gradebook[student.userId];
          if (studentSubmissions != null) {
            realSubmission = studentSubmissions[assignment.id];
          }
        }
        
        if (realSubmission != null && realSubmission.isGraded) {
          submissions[assignment.id] = MockSubmissionData(
            score: realSubmission.score,
            maxScore: realSubmission.maxScore ?? 100.0,
            status: realSubmission.isLate ? 'late' : 'submitted',
            attemptNumber: realSubmission.attemptNumber,
            submittedAt: realSubmission.submittedAt,
            files: realSubmission.attachments.map((a) => a.name).toList(),
            feedback: realSubmission.feedback,
            isPublished: false,
          );
        } else {
          final pattern = (i + j) % 5; 
          String status;
          double? score;
          int attemptNumber;
          DateTime? submittedAt;
          List<String> files;
          String? feedback;
          
          switch (pattern) {
            case 0:
              status = 'submitted';
              score = 85.0 + (i * 2.0) % 15;
              attemptNumber = 1;
              submittedAt = assignment.deadline.subtract(Duration(days: 2));
              files = ['assignment_${assignment.id}_student_$i.pdf'];
              feedback = 'Excellent work! Well done.';
              break;
              
            case 1:
              status = 'submitted';
              score = 70.0 + (i * 3.0) % 15;
              attemptNumber = 1;
              submittedAt = assignment.deadline.subtract(Duration(days: 1));
              files = ['homework_${assignment.id}_student_$i.docx'];
              feedback = 'Good effort. Consider reviewing the concepts.';
              break;
              
            case 2:
              status = 'late';
              score = 65.0 + (i * 2.5) % 20;
              attemptNumber = 1;
              submittedAt = assignment.deadline.add(Duration(days: 1));
              files = ['late_submission_${assignment.id}_student_$i.pdf'];
              feedback = 'Submitted late. Points deducted.';
              break;
              
            case 3:
              status = 'submitted';
              score = 75.0 + (i * 2.0) % 20;
              attemptNumber = 2 + (i % 2);
              submittedAt = assignment.deadline.subtract(Duration(hours: 12));
              files = [
                'attempt1_${assignment.id}_student_$i.pdf',
                'attempt2_${assignment.id}_student_$i.pdf',
              ];
              feedback = 'Improved on second attempt. Keep it up!';
              break;
              
            default:
              status = 'not_submitted';
              score = null;
              attemptNumber = 0;
              submittedAt = null;
              files = [];
              feedback = null;
              break;
          }
          
          submissions[assignment.id] = MockSubmissionData(
            score: score,
            maxScore: 100.0,
            status: status,
            attemptNumber: attemptNumber,
            submittedAt: submittedAt,
            files: files,
            feedback: feedback,
            isPublished: false,
          );
        }
      }
      
      _mockGradeData.add(MockGradeData(
        studentId: student?.userId ?? 'mock_user_$i',
        studentName: student?.studentName ?? 'Student ${i + 1}',
        studentEmail: student?.studentEmail ?? 'student${i + 1}@example.com',
        groupId: groupName,
        groupName: groupName,
        submissions: submissions,
      ));
    }
  }

  void _applyFilters() {
    _filteredGradeData = List.from(_mockGradeData);
    _cachedFilteredAssignments = _getFilteredAssignments();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      if (q.isNotEmpty) {
        _filteredGradeData = _filteredGradeData.where((data) {
          final studentName = data.studentName.toLowerCase();
          final studentId = data.studentId.toLowerCase();
          final groupName = data.groupName.toLowerCase();
          
          if (studentId.contains(q)) {
            return true;
          }
          
          if (groupName.contains(q)) {
            return true;
          }
          
          final nameWords = studentName.split(' ').where((w) => w.isNotEmpty).toList();
          for (final word in nameWords) {
            if (word == q || word.contains(q)) {
              if (RegExp(r'^\d+$').hasMatch(q)) {
                final numbersInWord = RegExp(r'\d+').allMatches(word);
                for (final match in numbersInWord) {
                  if (match.group(0) == q) {
                    return true;
                  }
                }
              } else {
                if (word.contains(q)) {
                  return true;
                }
              }
            }
          }
          
          final queryWords = q.split(' ').where((w) => w.isNotEmpty).toList();
          if (queryWords.length > 1) {
            int matchedWords = 0;
            for (final queryWord in queryWords) {
              bool found = false;
              for (final nameWord in nameWords) {
                if (RegExp(r'^\d+$').hasMatch(queryWord)) {
                  final numbersInWord = RegExp(r'\d+').allMatches(nameWord);
                  for (final match in numbersInWord) {
                    if (match.group(0) == queryWord) {
                      found = true;
                      break;
                    }
                  }
                } else {
                  if (nameWord.contains(queryWord)) {
                    found = true;
                    break;
                  }
                }
              }
              if (found) {
                matchedWords++;
              }
            }
            if (matchedWords == queryWords.length) {
              return true;
            }
          }
          
          return false;
        }).toList();
      }
    }

    if (_selectedItemId != null && _selectedItemId!.isNotEmpty) {
      _filteredGradeData = _filteredGradeData.where((data) {
        return data.submissions.containsKey(_selectedItemId);
      }).toList();
    }

    if (_selectedGroup != null && _selectedGroup!.isNotEmpty) {
      _filteredGradeData = _filteredGradeData.where((data) {
        return data.groupName == _selectedGroup;
      }).toList();
    }

    if (_selectedStatus != null && 
        _selectedStatus != 'all' && 
        _selectedItemId != null && 
        _selectedItemId!.isNotEmpty) {
      _filteredGradeData = _filteredGradeData.where((data) {
        final submission = data.submissions[_selectedItemId];
        if (submission == null) return false;
        return submission.status == _selectedStatus;
      }).toList();
    }

    if (_minScore != null || _maxScore != null) {
      _filteredGradeData = _filteredGradeData.where((data) {
        if (_selectedItemId == null || _selectedItemId!.isEmpty) return true;
        final submission = data.submissions[_selectedItemId];
        if (submission?.score == null) return false;
        final score = submission!.score!;
        if (_minScore != null && score < _minScore!) return false;
        if (_maxScore != null && score > _maxScore!) return false;
        return true;
      }).toList();
    }

    _filteredGradeData.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          return _sortAscending 
              ? a.studentName.compareTo(b.studentName)
              : b.studentName.compareTo(a.studentName);
        case 'group':
          return _sortAscending
              ? a.groupName.compareTo(b.groupName)
              : b.groupName.compareTo(a.groupName);
        case 'score':
          final scoreA = _selectedItemId != null 
              ? (a.submissions[_selectedItemId]?.score ?? 0.0)
              : _calculateTotalScore(a);
          final scoreB = _selectedItemId != null
              ? (b.submissions[_selectedItemId]?.score ?? 0.0)
              : _calculateTotalScore(b);
          return _sortAscending
              ? scoreA.compareTo(scoreB)
              : scoreB.compareTo(scoreA);
        default:
          return 0;
      }
    });
  }

  double _calculateTotalScore(MockGradeData data) {
    double total = 0;
    int count = 0;
    for (final submission in data.submissions.values) {
      if (submission.score != null) {
        total += submission.score!;
        count++;
      }
    }
    return count > 0 ? total / count : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final bool _shouldShowGradebook =
        _selectedType != null && _selectedItemId != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmall = screenWidth < 600;
        final padding = isSmall 
            ? const EdgeInsets.all(12)
            : const EdgeInsets.all(16);
        final spacing = isSmall ? 12.0 : 16.0;
        
        return Padding(
          padding: padding,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isSmall),
                SizedBox(height: spacing),
                
                GradeFilterBar(
              searchQuery: _searchQuery,
              selectedGroup: _selectedGroup,
              selectedType: _selectedType,
              selectedItemId: _selectedItemId,
              selectedStatus: _selectedStatus,
              assignments: _assignments,
              availableGroups: _getAvailableGroups(),
              availableItems: _getAvailableItems(),
              isItemDisabled: _selectedType == null || _selectedType == 'All',
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
              onGroupChanged: (value) {
                setState(() {
                  _selectedGroup = value == 'All' ? null : value;
                  _selectedStatus = null;
                  _applyFilters();
                });
              },
              onTypeChanged: (value) {
                setState(() {
                  _selectedType = value == 'All' ? null : value;
                  _selectedItemId = null;
                  _selectedGroup = null;
                  _selectedStatus = null;
                  _applyFilters();
                });
              },
              onItemChanged: (value) {
                setState(() {
                  _selectedItemId = value == 'All' ? null : value;
                  _selectedGroup = null;
                  _selectedStatus = null;
                  _applyFilters();
                });
              },
              onStatusChanged: (value) {
                setState(() {
                  _selectedStatus = value == 'all' ? null : value;
                  _applyFilters();
                });
              },
              onReset: () {
                setState(() {
                  _searchQuery = '';
                  _selectedGroup = null;
                  _selectedType = null;
                  _selectedItemId = null;
                  _selectedStatus = null;
                  _minScore = null;
                  _maxScore = null;
                  _applyFilters();
                });
              },
            ),
                SizedBox(height: spacing),
                
                if (!_shouldShowGradebook) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmall ? 12 : 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        'Select Type and Item above to load the gradebook for a specific assignment or quiz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: isSmall ? 12 : 14,
                        ),
                      ),
                    ),
                  ),
                ],

                if (_shouldShowGradebook) ...[
                  _buildStatisticsBar(isSmall),
                  SizedBox(height: spacing),
            
            GradebookTable(
              gradeData: _filteredGradeData,
              assignments: _cachedFilteredAssignments,
              horizontalScrollController: _horizontalScrollController,
              selectedStudentIds: _selectedStudentIds,
              onSelectionChanged: (selectedIds) {
                setState(() {
                  _selectedStudentIds = selectedIds;
                });
              },
              onGradeUpdated: (studentId, assignmentId, score, feedback) {
                setState(() {
                  final studentIndex = _mockGradeData.indexWhere((data) => data.studentId == studentId);
                  if (studentIndex != -1) {
                    final student = _mockGradeData[studentIndex];
                    final oldSubmission = student.submissions[assignmentId];
                    if (oldSubmission != null) {
                      final updatedSubmission = MockSubmissionData(
                        score: score,
                        maxScore: oldSubmission.maxScore,
                        status: oldSubmission.status,
                        attemptNumber: oldSubmission.attemptNumber,
                        submittedAt: oldSubmission.submittedAt,
                        files: oldSubmission.files,
                        feedback: feedback,
                        isPublished: oldSubmission.isPublished,
                      );
                      
                      final updatedSubmissions = Map<String, MockSubmissionData>.from(student.submissions);
                      updatedSubmissions[assignmentId] = updatedSubmission;
                      
                      _mockGradeData[studentIndex] = MockGradeData(
                        studentId: student.studentId,
                        studentName: student.studentName,
                        studentEmail: student.studentEmail,
                        groupId: student.groupId,
                        groupName: student.groupName,
                        submissions: updatedSubmissions,
                      );
                      
                      _applyFilters();
                    }
                  }
                });
              },
              onGradeSent: (studentId, assignmentId) {
                setState(() {
                  final studentIndex = _mockGradeData.indexWhere((data) => data.studentId == studentId);
                  if (studentIndex != -1) {
                    final student = _mockGradeData[studentIndex];
                    final oldSubmission = student.submissions[assignmentId];
                    if (oldSubmission != null) {
                      final updatedSubmission = MockSubmissionData(
                        score: oldSubmission.score,
                        maxScore: oldSubmission.maxScore,
                        status: oldSubmission.status,
                        attemptNumber: oldSubmission.attemptNumber,
                        submittedAt: oldSubmission.submittedAt,
                        files: oldSubmission.files,
                        feedback: oldSubmission.feedback,
                        isPublished: true,
                      );
                      
                      final updatedSubmissions = Map<String, MockSubmissionData>.from(student.submissions);
                      updatedSubmissions[assignmentId] = updatedSubmission;
                      
                      _mockGradeData[studentIndex] = MockGradeData(
                        studentId: student.studentId,
                        studentName: student.studentName,
                        studentEmail: student.studentEmail,
                        groupId: student.groupId,
                        groupName: student.groupName,
                        submissions: updatedSubmissions,
                      );
                      
                      _applyFilters();
                    }
                  }
                });
                
                // TODO: Gọi API để gửi điểm về cho học sinh
                // Ví dụ: await SubmissionRepository.publishGrade(studentId, assignmentId);
              },
            ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isSmall) {
    final iconSize = isSmall ? 20.0 : 24.0;
    final buttonSpacing = isSmall ? 6.0 : 8.0;
    final fontSize = isSmall ? 13.0 : 14.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox.shrink(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _exportToCSV,
              icon: Icon(
                Icons.download, 
                color: AppColors.textSecondary,
                size: iconSize,
              ),
              tooltip: 'Export to CSV',
              padding: EdgeInsets.all(isSmall ? 4 : 8),
              constraints: BoxConstraints(
                minWidth: isSmall ? 32 : 48,
                minHeight: isSmall ? 32 : 48,
              ),
            ),
            SizedBox(width: buttonSpacing),
            TextButton.icon(
              onPressed: _returnGradesToStudents,
              icon: Icon(
                Icons.send, 
                size: isSmall ? 16 : 18, 
                color: AppColors.primary,
              ),
              label: Text(
                'Return',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: fontSize,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 8 : 12,
                  vertical: isSmall ? 6 : 8,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _returnGradesToStudents() {
    if (_selectedItemId == null || _selectedItemId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Type and Item before returning grades'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final targetStudentIds = _selectedStudentIds.isNotEmpty
        ? _selectedStudentIds
        : _filteredGradeData.map((d) => d.studentId).toSet();

    if (targetStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students to return grades for'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final itemId = _selectedItemId!;

    setState(() {
      for (int i = 0; i < _mockGradeData.length; i++) {
        final student = _mockGradeData[i];
        if (!targetStudentIds.contains(student.studentId)) continue;

        final submission = student.submissions[itemId];
        if (submission == null || submission.score == null) continue;

        final updatedSubmission = MockSubmissionData(
          score: submission.score,
          maxScore: submission.maxScore,
          status: submission.status,
          attemptNumber: submission.attemptNumber,
          submittedAt: submission.submittedAt,
          files: submission.files,
          feedback: submission.feedback,
          isPublished: true,
        );

        final updatedSubmissions =
            Map<String, MockSubmissionData>.from(student.submissions);
        updatedSubmissions[itemId] = updatedSubmission;

        _mockGradeData[i] = MockGradeData(
          studentId: student.studentId,
          studentName: student.studentName,
          studentEmail: student.studentEmail,
          groupId: student.groupId,
          groupName: student.groupName,
          submissions: updatedSubmissions,
        );
      }

      _applyFilters();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Returned grades for ${targetStudentIds.length} student(s)',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _exportToCSV() async {
    await GradebookExport.exportToCSV(
      context: context,
      gradeData: _filteredGradeData,
      assignments: _cachedFilteredAssignments,
      selectedStudentIds: _selectedStudentIds,
    );
  }

  List<Assignment> _getAvailableItems() {
    if (_selectedType == null || _selectedType == 'All') {
      return [];
    }
    
    return _assignments.where((assignment) {
      final titleLower = assignment.title.toLowerCase();
      if (_selectedType == 'quiz') {
        return titleLower.contains('quiz') || titleLower.contains('exam');
      } else if (_selectedType == 'assignment') {
        return !titleLower.contains('quiz') && !titleLower.contains('exam');
      }
      return true;
    }).toList();
  }

  List<Assignment> _getFilteredAssignments() {
    if (_selectedItemId != null && _selectedItemId!.isNotEmpty) {
      return _assignments.where((assignment) {
        return assignment.id == _selectedItemId;
      }).toList();
    }
    
    if (_selectedType == null || _selectedType == 'All') {
      return _assignments;
    }
    
    return _assignments.where((assignment) {
      final titleLower = assignment.title.toLowerCase();
      if (_selectedType == 'quiz') {
        return titleLower.contains('quiz') || titleLower.contains('exam');
      } else if (_selectedType == 'assignment') {
        return !titleLower.contains('quiz') && !titleLower.contains('exam');
      }
      return true;
    }).toList();
  }

  List<String> _getAvailableGroups() {
    final groupNames = <String>{};
    List<MockGradeData> dataToUse = _mockGradeData;
    
    if (_selectedItemId != null && _selectedItemId!.isNotEmpty) {
      dataToUse = dataToUse.where((data) {
        return data.submissions.containsKey(_selectedItemId);
      }).toList();
    }
    
    for (final data in dataToUse) {
      groupNames.add(data.groupName);
    }
    
    final list = groupNames.toList()..sort();
    return ['All', ...list];
  }

  List<MockGradeData> _getDataForStatistics() {
    List<MockGradeData> data = List.from(_mockGradeData);
    
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      if (q.isNotEmpty) {
        data = data.where((data) {
          final studentName = data.studentName.toLowerCase();
          final studentId = data.studentId.toLowerCase();
          
          if (studentId.contains(q)) {
            return true;
          }
          
          final nameWords = studentName.split(' ').where((w) => w.isNotEmpty).toList();
          for (final word in nameWords) {
            if (word == q || word.contains(q)) {
              if (RegExp(r'^\d+$').hasMatch(q)) {
                final numbersInWord = RegExp(r'\d+').allMatches(word);
                for (final match in numbersInWord) {
                  if (match.group(0) == q) {
                    return true;
                  }
                }
              } else {
                if (word.contains(q)) {
                  return true;
                }
              }
            }
          }
          
          final queryWords = q.split(' ').where((w) => w.isNotEmpty).toList();
          if (queryWords.length > 1) {
            int matchedWords = 0;
            for (final queryWord in queryWords) {
              bool found = false;
              for (final nameWord in nameWords) {
                if (RegExp(r'^\d+$').hasMatch(queryWord)) {
                  final numbersInWord = RegExp(r'\d+').allMatches(nameWord);
                  for (final match in numbersInWord) {
                    if (match.group(0) == queryWord) {
                      found = true;
                      break;
                    }
                  }
                } else {
                  if (nameWord.contains(queryWord)) {
                    found = true;
                    break;
                  }
                }
              }
              if (found) {
                matchedWords++;
              }
            }
            if (matchedWords == queryWords.length) {
              return true;
            }
          }
          
          return false;
        }).toList();
      }
    }

    if (_selectedItemId != null && _selectedItemId!.isNotEmpty) {
      data = data.where((data) {
        return data.submissions.containsKey(_selectedItemId);
      }).toList();
    }

    if (_selectedGroup != null && _selectedGroup!.isNotEmpty) {
      data = data.where((data) {
        return data.groupName == _selectedGroup;
      }).toList();
    }

    return data;
  }

  Widget _buildStatisticsBar(bool isSmall) {
    final dataForStats = _getDataForStatistics();
    int totalStudents = dataForStats.length;
    
    final filteredAssignments = _cachedFilteredAssignments;
    int totalAssignments = filteredAssignments.length;
    
    int submittedCount = 0;
    int lateCount = 0;
    int notSubmittedCount = 0;
    
    final filteredAssignmentIds = filteredAssignments.map((a) => a.id).toSet();
    
    for (final data in dataForStats) {
      for (final assignmentId in filteredAssignmentIds) {
        final submission = data.submissions[assignmentId];
        
        if (submission != null) {
          switch (submission.status) {
            case 'submitted':
              submittedCount++;
              break;
            case 'late':
              lateCount++;
              break;
            case 'not_submitted':
              notSubmittedCount++;
              break;
          }
        } else {
          notSubmittedCount++;
        }
      }
    }

    final padding = isSmall 
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
        : const EdgeInsets.all(16);
    final spacing = isSmall ? 10.0 : 12.0;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: isSmall
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatItem('Students', totalStudents.toString(), Icons.people, isSmall),
                SizedBox(height: spacing),
                _buildStatItem('Assignments', totalAssignments.toString(), Icons.assignment, isSmall),
                SizedBox(height: spacing),
                _buildStatItem('Submitted', '$submittedCount', Icons.check_circle, isSmall, Colors.green),
                SizedBox(height: spacing),
                _buildStatItem('Late', '$lateCount', Icons.warning, isSmall, Colors.orange),
                SizedBox(height: spacing),
                _buildStatItem('Not Submitted', '$notSubmittedCount', Icons.cancel, isSmall, Colors.red),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildStatItem('Students', totalStudents.toString(), Icons.people, isSmall),
                ),
                Expanded(
                  child: _buildStatItem('Assignments', totalAssignments.toString(), Icons.assignment, isSmall),
                ),
                Expanded(
                  child: _buildStatItem('Submitted', '$submittedCount', Icons.check_circle, isSmall, Colors.green),
                ),
                Expanded(
                  child: _buildStatItem('Late', '$lateCount', Icons.warning, isSmall, Colors.orange),
                ),
                Expanded(
                  child: _buildStatItem('Not Submitted', '$notSubmittedCount', Icons.cancel, isSmall, Colors.red),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isSmall, [Color? iconColor]) {
    final iconSize = isSmall ? 16.0 : 20.0;
    final valueSize = isSmall ? 16.0 : 18.0;
    final labelSize = isSmall ? 11.0 : 12.0;
    final spacing = isSmall ? 6.0 : 8.0;
    
    if (isSmall) {
      // On small screens: align everything to the right
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: iconColor ?? AppColors.primary),
          SizedBox(width: spacing),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.right,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: labelSize,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ],
      );
    }
    
    // On large screens: center align
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: iconColor ?? AppColors.primary),
          SizedBox(width: spacing),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: valueSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: labelSize,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
