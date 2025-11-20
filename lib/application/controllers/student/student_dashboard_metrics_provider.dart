import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/domain/models/submission_model.dart';
import 'package:elearning_management_app/data/repositories/course/course_student_repository.dart';
import 'package:elearning_management_app/data/repositories/assignment/assignment_repository.dart';
import 'package:elearning_management_app/data/repositories/submission/submission_repository.dart';

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

    int assignmentsCompleted = 0;
    int assignmentsPending = 0;

    for (final assignment in allAssignments) {
      final courseId = assignmentCourseMap[assignment.id];
      if (courseId == null) continue;

      final submission =
          await SubmissionRepository.getUserSubmissionForAssignment(
        courseId,
        assignment.id,
      );

      final isSubmitted = submission != null &&
          (submission.status == SubmissionStatus.submitted ||
              submission.status == SubmissionStatus.graded ||
              submission.status == SubmissionStatus.returned);

      if (isSubmitted) {
        assignmentsCompleted++;
      } else {
        assignmentsPending++;
      }
    }

    return StudentDashboardMetrics(
      coursesCount: coursesForMetrics.length,
      assignmentsCount: allAssignments.length,
      pendingLateCount: assignmentsPending,
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

