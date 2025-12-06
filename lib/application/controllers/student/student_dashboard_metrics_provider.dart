import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/domain/models/submission_model.dart';
import 'package:elearning_management_app/domain/models/task_model.dart';
import 'package:elearning_management_app/data/repositories/course/course_student_repository.dart';
import 'package:elearning_management_app/data/repositories/assignment/assignment_repository.dart';
import 'package:elearning_management_app/data/repositories/submission/submission_repository.dart';
import 'package:elearning_management_app/domain/models/submission_model.dart' show SubmissionStatus;
import 'package:elearning_management_app/presentation/widgets/student/dashboard/common/student_dashboard_models.dart';
import 'package:intl/intl.dart';

class StudentDashboardMetrics {
  final int coursesCount;
  final int assignmentsCount;
  final int pendingLateCount;
  final int quizzesCount;
  final double assignmentsCompleted;
  final double assignmentsPending;
  final double quizzesCompleted;
  final double quizzesPending;

  const StudentDashboardMetrics({
    required this.coursesCount,
    required this.assignmentsCount,
    required this.pendingLateCount,
    required this.quizzesCount,
    required this.assignmentsCompleted,
    required this.assignmentsPending,
    required this.quizzesCompleted,
    required this.quizzesPending,
  });

  static const empty = StudentDashboardMetrics(
    coursesCount: 0,
    assignmentsCount: 0,
    pendingLateCount: 0,
    quizzesCount: 0,
    assignmentsCompleted: 0,
    assignmentsPending: 0,
    quizzesCompleted: 0,
    quizzesPending: 0,
  );
}

const String studentSemesterKeySeparator = '__@@__';

String buildStudentSemesterKey(String semesterId, String semesterLabel) {
  return '$semesterId$studentSemesterKeySeparator$semesterLabel';
}

final studentDashboardMetricsProvider =
    FutureProvider.family<StudentDashboardMetrics, String>(
  (ref, semesterKey) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return StudentDashboardMetrics.empty;
    }

    final allCourses =
        await CourseStudentRepository.getUserCourses(user.uid);
    final semesterTokens = _extractSemesterTokens(semesterKey);
    final filterVariants = _buildNormalizedVariants(semesterTokens);

    List<CourseModel> coursesForMetrics = _filterCoursesBySemester(
      allCourses,
      filterVariants,
    );

    // Fallback: if no course matched, use all courses to avoid empty UI
    if (coursesForMetrics.isEmpty) {
      coursesForMetrics = allCourses;
    }

    final List<Assignment> allAssignments = [];
    final Map<String, String> assignmentCourseMap = {};

    for (final course in coursesForMetrics) {
      final assignments =
          await AssignmentRepository.getAssignmentsByCourse(course.id);
      allAssignments.addAll(assignments);
      for (final assignment in assignments) {
        assignmentCourseMap[assignment.id] = course.id;
      }
    }

    // Lấy submissions của student để tính completed assignments
    final allSubmissions = await SubmissionRepository.getSubmissionsForStudent(user.uid);
    
    // Lọc submissions theo các assignments trong courses đã chọn
    final relevantSubmissions = allSubmissions.where((submission) {
      return assignmentCourseMap.containsKey(submission.assignmentId);
    }).toList();

    // Tính assignments completed (có submission với status submitted hoặc graded)
    final completedAssignmentIds = relevantSubmissions
        .where((s) => s.status == SubmissionStatus.submitted || 
                     s.status == SubmissionStatus.graded)
        .map((s) => s.assignmentId)
        .toSet();
    
    final assignmentsCompleted = completedAssignmentIds.length;
    final assignmentsPending = allAssignments.length - assignmentsCompleted;
    
    // Tính pending/late (submissions có isLate = true hoặc assignments chưa nộp nhưng đã quá deadline)
    final now = DateTime.now();
    final lateAssignments = allAssignments.where((assignment) {
      if (completedAssignmentIds.contains(assignment.id)) {
        // Đã nộp, kiểm tra xem có nộp muộn không
        final submission = relevantSubmissions
            .where((s) => s.assignmentId == assignment.id)
            .firstOrNull;
        return submission?.isLate ?? false;
      } else {
        // Chưa nộp, kiểm tra deadline
        return now.isAfter(assignment.deadline);
      }
    }).length;

    // Tạm thời quizzes = 0 (có thể cần collection riêng hoặc field type trong Assignment)
    // TODO: Implement quiz logic nếu có collection quizzes riêng

    return StudentDashboardMetrics(
      coursesCount: coursesForMetrics.length,
      assignmentsCount: allAssignments.length,
      pendingLateCount: lateAssignments,
      quizzesCount: 0,
      assignmentsCompleted: assignmentsCompleted.toDouble(),
      assignmentsPending: assignmentsPending.toDouble(),
      quizzesCompleted: 0,
      quizzesPending: 0,
    );
  },
);

/// Extract raw semester strings (id + label) from the combined key.
List<String> _extractSemesterTokens(String semesterKey) {
  if (semesterKey.contains(studentSemesterKeySeparator)) {
    final parts = semesterKey.split(studentSemesterKeySeparator);
    return [parts.first, parts.length > 1 ? parts[1] : ''];
  }
  return [semesterKey];
}

/// Build a set of normalized variants for flexible semester comparison.
Set<String> _buildNormalizedVariants(List<String> tokens) {
  final variants = <String>{};
  for (final token in tokens) {
    if (token.isEmpty) continue;
    variants.addAll(_normalizedForms(token));
  }
  variants.removeWhere((element) => element.isEmpty);
  return variants;
}

/// Filter courses by comparing normalized semester strings.
List<CourseModel> _filterCoursesBySemester(
  List<CourseModel> courses,
  Set<String> filterVariants,
) {
  if (filterVariants.isEmpty) {
    return courses;
  }

  return courses.where((course) {
    final courseVariants = _normalizedForms(course.semester);
    return courseVariants.any(filterVariants.contains);
  }).toList();
}

/// Produce normalized string variants (exact + expanded/truncated year forms).
Set<String> _normalizedForms(String input) {
  final sanitized = _normalizeToken(input);
  if (sanitized.isEmpty) return {sanitized};

  final variants = <String>{sanitized};

  // If already ends with 4 digits, add truncated (last 2 digits) variant
  final fourDigitMatch = RegExp(r'(\d{4})$').firstMatch(sanitized);
  if (fourDigitMatch != null) {
    final suffix = fourDigitMatch.group(1)!;
    final truncated = sanitized.substring(
          0,
          sanitized.length - suffix.length,
        ) +
        suffix.substring(2); // keep last two digits
    variants.add(truncated);
  } else {
    // If ends with 2 digits, add expanded 4-digit variant (prepend 20)
    final twoDigitMatch = RegExp(r'(\d{2})$').firstMatch(sanitized);
    if (twoDigitMatch != null) {
      final suffix = twoDigitMatch.group(1)!;
      final prefix =
          sanitized.substring(0, sanitized.length - suffix.length);
      variants.add('${prefix}20$suffix');
    }
  }

  return variants;
}

String _normalizeToken(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
}

// ========================================
// PROVIDER: Recent Submissions
// ========================================
final studentRecentSubmissionsProvider = FutureProvider<List<SubmissionModel>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return [];
  }

  try {
    final submissions = await SubmissionRepository.getSubmissionsForStudent(user.uid);
    // Sắp xếp theo thời gian submit mới nhất, lấy 5 cái đầu
    submissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return submissions.take(5).toList();
  } catch (e) {
    print('DEBUG: ❌ Error fetching recent submissions: $e');
    return [];
  }
});

// ========================================
// PROVIDER: Completed Quizzes (submissions đã được chấm điểm)
// ========================================
final studentCompletedQuizzesProvider = FutureProvider<List<SubmissionModel>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return [];
  }

  try {
    final submissions = await SubmissionRepository.getSubmissionsForStudent(user.uid);
    // Lọc các submissions đã được chấm điểm (có score)
    final gradedSubmissions = submissions
        .where((s) => s.status == SubmissionStatus.graded && s.score != null)
        .toList();
    
    // Sắp xếp theo thời gian chấm điểm mới nhất
    gradedSubmissions.sort((a, b) {
      final aTime = a.gradedAt ?? a.submittedAt;
      final bTime = b.gradedAt ?? b.submittedAt;
      return bTime.compareTo(aTime);
    });
    
    return gradedSubmissions.take(5).toList();
  } catch (e) {
    print('DEBUG: ❌ Error fetching completed quizzes: $e');
    return [];
  }
});

// ========================================
// PROVIDER: Recent Submissions as SubmissionItem (for UI)
// ========================================
final studentRecentSubmissionsItemProvider = FutureProvider<List<SubmissionItem>>((ref) async {
  final submissionsAsync = ref.watch(studentRecentSubmissionsProvider);
  
  return await submissionsAsync.when(
    data: (submissions) async {
      final List<SubmissionItem> items = [];
      
      for (final submission in submissions) {
        try {
          // Lấy assignment để có title
          final assignment = await AssignmentRepository.getAssignmentById(submission.assignmentId);
          if (assignment == null) continue;
          
          // Tính time ago
          final now = DateTime.now();
          final submittedAt = submission.submittedAt;
          final difference = now.difference(submittedAt);
          
          String timeLabel;
          if (difference.inHours < 1) {
            timeLabel = 'Submitted ${difference.inMinutes}m ago';
          } else if (difference.inHours < 24) {
            timeLabel = 'Submitted ${difference.inHours}h ago';
          } else if (difference.inDays == 1) {
            timeLabel = 'Submitted yesterday';
          } else {
            timeLabel = 'Submitted ${difference.inDays} days ago';
          }
          
          // Xác định status
          DashboardSubmissionStatus status;
          if (submission.isLate) {
            status = DashboardSubmissionStatus.late;
          } else if (difference.inDays > 1) {
            status = DashboardSubmissionStatus.early;
          } else {
            status = DashboardSubmissionStatus.onTime;
          }
          
          items.add(SubmissionItem(
            title: assignment.title,
            timeLabel: timeLabel,
            type: DashboardSubmissionType.assignment, // Tạm thời, có thể cần field type trong Assignment
            status: status,
          ));
        } catch (e) {
          print('DEBUG: ⚠️ Error converting submission to item: $e');
        }
      }
      
      return items;
    },
    loading: () async => [],
    error: (_, __) async => [],
  );
});

// ========================================
// PROVIDER: Completed Quizzes as CompletedQuizItem (for UI)
// ========================================
final studentCompletedQuizzesItemProvider = FutureProvider<List<CompletedQuizItem>>((ref) async {
  final submissionsAsync = ref.watch(studentCompletedQuizzesProvider);
  
  return await submissionsAsync.when(
    data: (submissions) async {
      final List<CompletedQuizItem> items = [];
      
      for (final submission in submissions) {
        try {
          // Lấy assignment để có title
          final assignment = await AssignmentRepository.getAssignmentById(submission.assignmentId);
          if (assignment == null) continue;
          
          // Lấy course để có course name
          final course = await CourseStudentRepository.getCourseById(submission.courseId);
          final courseName = course?.name ?? 'Unknown Course';
          
          // Format date
          final dateFormat = DateFormat('yyyy-MM-dd');
          final completedDate = dateFormat.format(submission.gradedAt ?? submission.submittedAt);
          
          items.add(CompletedQuizItem(
            title: assignment.title,
            courseName: courseName,
            score: (submission.score ?? 0).toInt(),
            maxScore: (submission.maxScore ?? assignment.maxPoints).toInt(),
            completedDate: completedDate,
          ));
        } catch (e) {
          print('DEBUG: ⚠️ Error converting submission to quiz item: $e');
        }
      }
      
      return items;
    },
    loading: () async => [],
    error: (_, __) async => [],
  );
});

// ========================================
// PROVIDER: Student Tasks for Calendar (convert from Assignments)
// ========================================
final studentTasksForDateProvider = FutureProvider.family<List<TaskModel>, DateTime>((ref, date) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return [];
  }

  try {
    // Lấy tất cả courses của student
    final allCourses = await CourseStudentRepository.getUserCourses(user.uid);
    if (allCourses.isEmpty) return [];

    // Lấy tất cả assignments từ các courses
    final List<Assignment> allAssignments = [];
    final Map<String, CourseModel> assignmentCourseMap = {};
    
    for (final course in allCourses) {
      final assignments = await AssignmentRepository.getAssignmentsByCourse(course.id);
      allAssignments.addAll(assignments);
      for (final assignment in assignments) {
        assignmentCourseMap[assignment.id] = course;
      }
    }

    // Lấy submissions để check completed status
    final allSubmissions = await SubmissionRepository.getSubmissionsForStudent(user.uid);
    final completedAssignmentIds = allSubmissions
        .where((s) => (s.status == SubmissionStatus.submitted || s.status == SubmissionStatus.graded) &&
                     assignmentCourseMap.containsKey(s.assignmentId))
        .map((s) => s.assignmentId)
        .toSet();

    // Filter assignments cho ngày được chọn và convert sang TaskModel
    final selectedDateKey = DateTime(date.year, date.month, date.day);
    final tasks = <TaskModel>[];

    for (final assignment in allAssignments) {
      final assignmentDateKey = DateTime(
        assignment.deadline.year,
        assignment.deadline.month,
        assignment.deadline.day,
      );
      
      // Chỉ lấy assignments có deadline trong ngày được chọn
      if (assignmentDateKey == selectedDateKey) {
        final course = assignmentCourseMap[assignment.id];
        final isCompleted = completedAssignmentIds.contains(assignment.id);
        final now = DateTime.now();
        final isLate = !isCompleted && assignment.deadline.isBefore(now);
        final isPriority = isLate || (assignment.deadline.difference(now).inDays <= 1);

        tasks.add(TaskModel(
          id: assignment.id,
          title: assignment.title,
          description: assignment.description,
          dateTime: assignment.deadline,
          type: TaskType.assignment,
          courseName: course?.name ?? 'Unknown Course',
          isCompleted: isCompleted,
          isPriority: isPriority,
        ));
      }
    }

    return tasks;
  } catch (e) {
    print('DEBUG: ❌ Error fetching tasks for date: $e');
    return [];
  }
});

// ========================================
// PROVIDER: Student Tasks for Month (convert from Assignments)
// ========================================
final studentTasksForMonthProvider = FutureProvider.family<List<TaskModel>, DateTime>((ref, month) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return [];
  }

  try {
    // Lấy tất cả courses của student
    final allCourses = await CourseStudentRepository.getUserCourses(user.uid);
    if (allCourses.isEmpty) return [];

    // Lấy tất cả assignments từ các courses
    final List<Assignment> allAssignments = [];
    final Map<String, CourseModel> assignmentCourseMap = {};
    
    for (final course in allCourses) {
      final assignments = await AssignmentRepository.getAssignmentsByCourse(course.id);
      allAssignments.addAll(assignments);
      for (final assignment in assignments) {
        assignmentCourseMap[assignment.id] = course;
      }
    }

    // Lấy submissions để check completed status
    final allSubmissions = await SubmissionRepository.getSubmissionsForStudent(user.uid);
    final completedAssignmentIds = allSubmissions
        .where((s) => (s.status == SubmissionStatus.submitted || s.status == SubmissionStatus.graded) &&
                     assignmentCourseMap.containsKey(s.assignmentId))
        .map((s) => s.assignmentId)
        .toSet();

    // Filter assignments trong tháng được chọn và convert sang TaskModel
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final tasks = <TaskModel>[];

    for (final assignment in allAssignments) {
      // Chỉ lấy assignments có deadline trong tháng được chọn
      if (assignment.deadline.isAfter(monthStart.subtract(const Duration(days: 1))) &&
          assignment.deadline.isBefore(monthEnd.add(const Duration(days: 1)))) {
        final course = assignmentCourseMap[assignment.id];
        final isCompleted = completedAssignmentIds.contains(assignment.id);
        final now = DateTime.now();
        final isLate = !isCompleted && assignment.deadline.isBefore(now);
        final isPriority = isLate || (assignment.deadline.difference(now).inDays <= 1);

        tasks.add(TaskModel(
          id: assignment.id,
          title: assignment.title,
          description: assignment.description,
          dateTime: assignment.deadline,
          type: TaskType.assignment,
          courseName: course?.name ?? 'Unknown Course',
          isCompleted: isCompleted,
          isPriority: isPriority,
        ));
      }
    }

    return tasks;
  } catch (e) {
    print('DEBUG: ❌ Error fetching tasks for month: $e');
    return [];
  }
});

