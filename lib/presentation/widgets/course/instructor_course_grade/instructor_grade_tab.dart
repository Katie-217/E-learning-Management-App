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
  
  // Mock data for UI/UX
  List<MockGradeData> _mockGradeData = [];
  List<MockGradeData> _filteredGradeData = [];
  
  // Cache filtered assignments để đảm bảo cùng instance được dùng
  List<Assignment> _cachedFilteredAssignments = [];
  
  // Selected students for export
  Set<String> _selectedStudentIds = {};
  
  // Scroll controllers
  final ScrollController _horizontalScrollController = ScrollController();
  
  // Filter and search
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
      // Load real data
      final enrollmentRepo = EnrollmentRepository();
      _students = await enrollmentRepo.getStudentsInCourse(widget.course.id);
      _assignments = await AssignmentRepository.getAssignmentsByCourse(widget.course.id);
      _assignments.sort((a, b) => a.deadline.compareTo(b.deadline));
      final submissions = await SubmissionRepository.getSubmissionsByCourse(widget.course.id);

      // Build gradebook map
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

      // Ensure we have at least some assignments for display
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

      // Generate mock data 
      _generateMockData();
      _applyFilters();
    } catch (e) {
      print('DEBUG: ❌ Error loading gradebook: $e');
      // Use mock data even if real data fails
      // Ensure we have at least some assignments for display
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
    
    // Ensure we have at least some assignments for mock data
    List<Assignment> assignmentsToUse = _assignments;
    if (assignmentsToUse.isEmpty) {
      // Create mock assignments if none exist
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
    
    // Use real students if available, otherwise create mock students with graded submissions
    final studentsToUse = _students.isNotEmpty ? _students : null;
    final studentCount = studentsToUse?.length ?? 15;
    
    for (int i = 0; i < studentCount; i++) {
      final student = studentsToUse != null && i < studentsToUse.length 
          ? studentsToUse[i] 
          : null;
      
      // Use group name instead of ID - map groupId to readable name
      String groupName;
      if (student?.groupId?.isNotEmpty == true) {
        // Map groupId to readable name (e.g., "hRzv0Nssv8BdL TnvLra1" -> "Group A")
        final groupIndex = student!.groupId!.hashCode % groups.length;
        groupName = groups[groupIndex.abs()];
      } else {
        groupName = groups[i % groups.length];
      }
      
      final submissions = <String, MockSubmissionData>{};
      
      // Generate mock submissions with various scenarios
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
          // Use real graded submission
          submissions[assignment.id] = MockSubmissionData(
            score: realSubmission.score,
            maxScore: realSubmission.maxScore ?? 100.0,
            status: realSubmission.isLate ? 'late' : 'submitted',
            attemptNumber: realSubmission.attemptNumber,
            submittedAt: realSubmission.submittedAt,
            files: realSubmission.attachments.map((a) => a.name).toList(),
            feedback: realSubmission.feedback,
            isPublished: false, // Mặc định chưa gửi
          );
        } else {
          // Generate mock graded submissions with variety
          final pattern = (i + j) % 5; 
          String status;
          double? score;
          int attemptNumber;
          DateTime? submittedAt;
          List<String> files;
          String? feedback;
          
          switch (pattern) {
            case 0: // Submitted on time, graded (high score)
              status = 'submitted';
              score = 85.0 + (i * 2.0) % 15; // 85-100
              attemptNumber = 1;
              submittedAt = assignment.deadline.subtract(Duration(days: 2));
              files = ['assignment_${assignment.id}_student_$i.pdf'];
              feedback = 'Excellent work! Well done.';
              break;
              
            case 1: // Submitted on time, graded (medium score)
              status = 'submitted';
              score = 70.0 + (i * 3.0) % 15; // 70-85
              attemptNumber = 1;
              submittedAt = assignment.deadline.subtract(Duration(days: 1));
              files = ['homework_${assignment.id}_student_$i.docx'];
              feedback = 'Good effort. Consider reviewing the concepts.';
              break;
              
            case 2: // Late submission, graded
              status = 'late';
              score = 65.0 + (i * 2.5) % 20; // 65-85
              attemptNumber = 1;
              submittedAt = assignment.deadline.add(Duration(days: 1));
              files = ['late_submission_${assignment.id}_student_$i.pdf'];
              feedback = 'Submitted late. Points deducted.';
              break;
              
            case 3: // Multiple attempts, graded
              status = 'submitted';
              score = 75.0 + (i * 2.0) % 20; // 75-95
              attemptNumber = 2 + (i % 2); // 2 or 3 attempts
              submittedAt = assignment.deadline.subtract(Duration(hours: 12));
              files = [
                'attempt1_${assignment.id}_student_$i.pdf',
                'attempt2_${assignment.id}_student_$i.pdf',
              ];
              feedback = 'Improved on second attempt. Keep it up!';
              break;
              
            default: // Not submitted
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
            isPublished: false, // Mặc định chưa gửi
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
    
    // Cache filtered assignments để đảm bảo cùng instance được dùng
    _cachedFilteredAssignments = _getFilteredAssignments();

    // 1. Search filter - tìm theo tên (bất kỳ phần nào của tên) và ID
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      if (q.isNotEmpty) {
        _filteredGradeData = _filteredGradeData.where((data) {
          final studentName = data.studentName.toLowerCase();
          final studentId = data.studentId.toLowerCase();
          
          // Tìm theo ID - ID chứa query như một phần hoàn chỉnh
          if (studentId.contains(q)) {
            return true;
          }
          
          // Tìm theo tên - kiểm tra từng từ trong tên có chứa query không
          final nameWords = studentName.split(' ').where((w) => w.isNotEmpty).toList();
          for (final word in nameWords) {
            if (word == q || word.contains(q)) {
              // Kiểm tra thêm: nếu query là số, chỉ match khi nó xuất hiện như một số hoàn chỉnh
              if (RegExp(r'^\d+$').hasMatch(q)) {
                // Query là số, kiểm tra xem word có chứa số này như một phần hoàn chỉnh không
                final numbersInWord = RegExp(r'\d+').allMatches(word);
                for (final match in numbersInWord) {
                  if (match.group(0) == q) {
                    return true;
                  }
                }
              } else {
                // Query không phải là số, match bình thường
                if (word.contains(q)) {
                  return true;
                }
              }
            }
          }
          
          // Nếu query có nhiều từ, kiểm tra xem các từ trong query có xuất hiện trong tên không
          final queryWords = q.split(' ').where((w) => w.isNotEmpty).toList();
          if (queryWords.length > 1) {
            // Kiểm tra xem tất cả các từ trong query có xuất hiện trong tên không
            int matchedWords = 0;
            for (final queryWord in queryWords) {
              // Kiểm tra queryWord có xuất hiện trong bất kỳ từ nào của tên
              bool found = false;
              for (final nameWord in nameWords) {
                if (RegExp(r'^\d+$').hasMatch(queryWord)) {
                  // Query word là số, kiểm tra chính xác
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
            // Nếu tất cả các từ trong query đều xuất hiện trong tên thì return true
            if (matchedWords == queryWords.length) {
              return true;
            }
          }
          
          return false;
        }).toList();
      }
    }

    // 2. Item filter (bài tập đầu tiên) - filter students có submission cho Item đã chọn
    if (_selectedItemId != null && _selectedItemId!.isNotEmpty) {
      _filteredGradeData = _filteredGradeData.where((data) {
        // Chỉ giữ sinh viên có entry cho bài này (kể cả chưa nộp)
        return data.submissions.containsKey(_selectedItemId);
      }).toList();
    }

    // 3. Group filter (sau Item) - filter students theo Group đã chọn
    // Chỉ áp dụng trên kết quả đã được filter bởi Item (nếu có)
    if (_selectedGroup != null && _selectedGroup!.isNotEmpty) {
      _filteredGradeData = _filteredGradeData.where((data) {
        return data.groupName == _selectedGroup;
      }).toList();
    }

    // 4. Status filter (sau Group) - filter students theo Status của Item đã chọn
    // Chỉ áp dụng khi đã chọn Item và trên kết quả đã được filter bởi Item + Group
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

    // 5. Score range filter
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

    // 6. Sort
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 16),
            
            // Search and Filters
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
                  // Reset Status khi chọn Group mới
                  _selectedStatus = null;
                  _applyFilters();
                });
              },
              onTypeChanged: (value) {
                setState(() {
                  _selectedType = value == 'All' ? null : value;
                  // Reset Item, Group và Status khi chọn Type mới
                  _selectedItemId = null;
                  _selectedGroup = null;
                  _selectedStatus = null;
                  _applyFilters();
                });
              },
              onItemChanged: (value) {
                setState(() {
                  _selectedItemId = value == 'All' ? null : value;
                  // Reset Group và Status khi chọn Item mới
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
          const SizedBox(height: 16),
          
            // Statistics Bar
            _buildStatisticsBar(),
            const SizedBox(height: 16),
            
            // Gradebook table - with fixed student column and scrollable columns
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
                // Cập nhật mock data với score và feedback mới
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
                        isPublished: oldSubmission.isPublished, // Giữ nguyên trạng thái published
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
                      
                      // Re-apply filters để cập nhật filtered data
                      _applyFilters();
                    }
                  }
                });
              },
              onGradeSent: (studentId, assignmentId) {
                // Cập nhật trạng thái published trong mock data
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
                        isPublished: true, // Đánh dấu đã gửi
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
                      
                      // Re-apply filters để cập nhật filtered data
                      _applyFilters();
                    }
                  }
                });
                
                // TODO: Gọi API để gửi điểm về cho học sinh
                // Ví dụ: await SubmissionRepository.publishGrade(studentId, assignmentId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox.shrink(), // Xóa chữ "Grades"
        // Export CSV button
        IconButton(
          onPressed: _exportToCSV,
          icon: const Icon(Icons.download, color: AppColors.textSecondary),
          tooltip: 'Export to CSV',
        ),
      ],
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


  // Helper: Lấy danh sách Items (Assignments) - filter theo Type (cho dropdown)
  List<Assignment> _getAvailableItems() {
    if (_selectedType == null || _selectedType == 'All') {
      return [];
    }
    
    // Filter assignments theo type dựa trên title
    // Nếu title chứa "Quiz" hoặc "quiz" thì là quiz, còn lại là assignment
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

  // Helper: Lấy danh sách Assignments đã filter theo Type và Item (cho gradebook table)
  List<Assignment> _getFilteredAssignments() {
    // Nếu đã chọn Item, chỉ hiển thị cột của Item đó
    if (_selectedItemId != null && _selectedItemId!.isNotEmpty) {
      return _assignments.where((assignment) {
        return assignment.id == _selectedItemId;
      }).toList();
    }
    
    // Nếu chưa chọn Type, hiển thị tất cả assignments
    if (_selectedType == null || _selectedType == 'All') {
      return _assignments;
    }
    
    // Filter assignments theo type dựa trên title
    // Nếu title chứa "Quiz" hoặc "quiz" thì là quiz, còn lại là assignment
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

  // Helper: Lấy danh sách Group dựa trên Item đã chọn - filter phụ thuộc
  List<String> _getAvailableGroups() {
    final groupNames = <String>{};
    
    // Bắt đầu từ filtered data (đã được filter bởi search và item)
    List<MockGradeData> dataToUse = _mockGradeData;
    
    // Nếu đã chọn Item, chỉ lấy groups có students với submission cho Item đó
    if (_selectedItemId != null && _selectedItemId!.isNotEmpty) {
      dataToUse = dataToUse.where((data) {
        return data.submissions.containsKey(_selectedItemId);
      }).toList();
    }
    
    // Lấy groups từ students đã được filter
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

  Widget _buildStatisticsBar() {
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildStatItem('Students', totalStudents.toString(), Icons.people),
          ),
          Expanded(
            child: _buildStatItem('Assignments', totalAssignments.toString(), Icons.assignment),
          ),
          Expanded(
            child: _buildStatItem('Submitted', '$submittedCount', Icons.check_circle, Colors.green),
          ),
          Expanded(
            child: _buildStatItem('Late', '$lateCount', Icons.warning, Colors.orange),
          ),
          Expanded(
            child: _buildStatItem('Not Submitted', '$notSubmittedCount', Icons.cancel, Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, [Color? iconColor]) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
