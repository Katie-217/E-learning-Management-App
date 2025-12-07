// ========================================
// FILE: instructor_kpi_provider.dart
// MÔ TẢ: Provider cho KPI stats của instructor dashboard - Load dữ liệu thật từ repositories
// ========================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/application/controllers/course/course_instructor_provider.dart';
import 'package:elearning_management_app/data/repositories/course/course_instructor_repository.dart';
import 'package:elearning_management_app/data/repositories/assignment/assignment_repository.dart';
import 'package:elearning_management_app/data/repositories/submission/submission_repository.dart';
import 'package:elearning_management_app/data/repositories/course/enrollment_repository.dart';
import 'package:elearning_management_app/data/repositories/group/group_repository.dart';
import 'package:elearning_management_app/data/repositories/semester/semester_repository.dart';
import 'package:elearning_management_app/domain/models/task_model.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/domain/models/submission_model.dart' show SubmissionStatus;

// KPI Stats Model
class InstructorKPIStats {
  final int coursesCount;
  final int groupsCount;
  final int studentsCount;
  final int assignmentsCount;
  final int quizzesCount;

  const InstructorKPIStats({
    required this.coursesCount,
    required this.groupsCount,
    required this.studentsCount,
    required this.assignmentsCount,
    required this.quizzesCount,
  });
}

// Provider để lấy KPI stats - Load dữ liệu thật từ repositories
final instructorKPIStatsProvider = FutureProvider.family<InstructorKPIStats, String>(
  (ref, semesterName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const InstructorKPIStats(
        coursesCount: 0,
        groupsCount: 0,
        studentsCount: 0,
        assignmentsCount: 0,
        quizzesCount: 0,
      );
    }

    try {
      // 1. Lấy controller từ provider để gọi repository methods
      final courseController = ref.read(courseInstructorControllerProvider);
      
      // 2. Lấy courses của instructor - sử dụng controller method để filter theo semester
      List<CourseModel> coursesForMetrics;
      
      if (semesterName.isNotEmpty && semesterName != 'All') {
        print('DEBUG: 🔍 Loading courses for semester: "$semesterName"');
        
        // Tìm semester từ repository để lấy semester string chính xác
        String? actualSemesterString;
        dynamic matchedSemester; // Lưu matched semester để dùng trong fallback
        
        try {
          final semesterRepo = SemesterRepository();
          final allSemesters = await semesterRepo.getAllSemesters();
          
          // Tìm semester match với semesterName
          matchedSemester = allSemesters.firstWhere(
            (s) => s.name.toLowerCase().trim() == semesterName.toLowerCase().trim() ||
                   s.code.toLowerCase().trim() == semesterName.toLowerCase().trim() ||
                   s.id.toLowerCase().trim() == semesterName.toLowerCase().trim(),
            orElse: () {
              // Nếu không tìm thấy exact match, thử tìm partial match
              try {
                return allSemesters.firstWhere(
                  (s) => s.name.toLowerCase().contains(semesterName.toLowerCase()) ||
                         semesterName.toLowerCase().contains(s.name.toLowerCase()) ||
                         s.code.toLowerCase().contains(semesterName.toLowerCase()) ||
                         semesterName.toLowerCase().contains(s.code.toLowerCase()),
                );
              } catch (e) {
                // Nếu vẫn không tìm thấy, return first semester
                return allSemesters.isNotEmpty ? allSemesters.first : throw Exception('No semesters found');
              }
            },
          );
          
          // Sử dụng semester name từ matched semester để query courses
          actualSemesterString = matchedSemester.name;
          print('DEBUG: 🔍 Found semester: ID="${matchedSemester.id}", Code="${matchedSemester.code}", Name="${matchedSemester.name}"');
          print('DEBUG: 📚 Using semester name for query: "$actualSemesterString"');
        } catch (e) {
          print('DEBUG: ⚠️ Could not find semester from repository: $e');
          // Fallback: dùng semesterName trực tiếp
          actualSemesterString = semesterName;
          matchedSemester = null;
        }
        
        // Sử dụng controller method để lấy courses theo semester
        try {
          coursesForMetrics = await courseController.getInstructorCoursesBySemester(actualSemesterString!);
          print('DEBUG: ✅ Loaded ${coursesForMetrics.length} courses for semester "$actualSemesterString" via repository');
          
          // Nếu repository trả về empty (do exact match không khớp), dùng fallback filter thủ công
          if (coursesForMetrics.isEmpty) {
            print('DEBUG: ⚠️ Repository returned 0 courses (exact match failed), using flexible filter');
            final allCourses = await courseController.getInstructorCourses();
            print('DEBUG: 📚 Available courses: ${allCourses.length}');
            
            // Flexible matching: so sánh nhiều cách
            coursesForMetrics = allCourses.where((course) {
              final courseSemester = course.semester.toLowerCase().trim();
              final filterSemester = actualSemesterString!.toLowerCase().trim();
              
              // Normalize: bỏ ký tự đặc biệt và khoảng trắng thừa
              final normalizedCourseSemester = courseSemester.replaceAll(RegExp(r'[_\s-]+'), ' ').trim();
              final normalizedFilter = filterSemester.replaceAll(RegExp(r'[_\s-]+'), ' ').trim();
              
              // Kiểm tra nhiều cách match
              bool matches = 
                  normalizedCourseSemester == normalizedFilter ||
                  normalizedCourseSemester.contains(normalizedFilter) ||
                  normalizedFilter.contains(normalizedCourseSemester);
              
              // Nếu có matchedSemester, thử match với name và code
              if (!matches && matchedSemester != null) {
                final matchedSemesterName = matchedSemester.name.toLowerCase().trim();
                final matchedSemesterCode = matchedSemester.code.toLowerCase().trim();
                final normalizedMatchedName = matchedSemesterName.replaceAll(RegExp(r'[_\s-]+'), ' ').trim();
                final normalizedMatchedCode = matchedSemesterCode.replaceAll(RegExp(r'[_\s-]+'), ' ').trim();
                
                matches = 
                    normalizedCourseSemester == normalizedMatchedName ||
                    normalizedCourseSemester.contains(normalizedMatchedName) ||
                    normalizedMatchedName.contains(normalizedCourseSemester) ||
                    normalizedCourseSemester.contains(normalizedMatchedCode) ||
                    normalizedMatchedCode.contains(normalizedCourseSemester);
              }
              
              if (!matches) {
                print('DEBUG: ❌ Course "${course.name}" does NOT match semester filter');
                print('DEBUG:   - Course semester: "${course.semester}"');
                print('DEBUG:   - Filter semester: "$actualSemesterString"');
                if (matchedSemester != null) {
                  print('DEBUG:   - Matched semester name: "${matchedSemester.name}"');
                  print('DEBUG:   - Matched semester code: "${matchedSemester.code}"');
                }
              } else {
                print('DEBUG: ✅ Course "${course.name}" matches semester filter (${course.semester})');
              }
              
              return matches;
            }).toList();
            
            print('DEBUG: ✅ Filtered courses count: ${coursesForMetrics.length}');
          }
        } catch (e) {
          print('DEBUG: ⚠️ Error loading courses by semester, falling back to flexible filter: $e');
          // Fallback: lấy tất cả courses và filter thủ công
          final allCourses = await courseController.getInstructorCourses();
          coursesForMetrics = allCourses.where((course) {
            final courseSemester = course.semester.toLowerCase().trim();
            final filterSemester = actualSemesterString!.toLowerCase().trim();
            return courseSemester.contains(filterSemester) || 
                   filterSemester.contains(courseSemester);
          }).toList();
        }
      } else {
        // Lấy tất cả courses nếu không có semester filter
        print('DEBUG: 📋 Loading all courses (no semester filter)');
        coursesForMetrics = await courseController.getInstructorCourses();
      }

      // KHÔNG dùng fallback nữa - nếu không có courses thì trả về 0
      // Điều này đảm bảo KPI cards hiển thị đúng số courses đã filter
      print('DEBUG: 📊 Final courses for metrics: ${coursesForMetrics.length}');
      
      print('DEBUG: 📊 Final courses for metrics: ${coursesForMetrics.length}');

      final coursesCount = coursesForMetrics.length;
      print('DEBUG: 📊 Courses for metrics: $coursesCount');

      // 3. Lấy students count - CHỈ đếm từ courses đã filter (đồng bộ với coursesCount)
      int studentsCount = 0;
      final enrollmentRepo = EnrollmentRepository();
      print('DEBUG: 👥 Counting students for ${coursesForMetrics.length} courses');
      for (final course in coursesForMetrics) {
        try {
          final count = await enrollmentRepo.countStudentsInCourse(course.id);
          studentsCount += count;
          print('DEBUG: 👥 Course "${course.name}": $count students');
        } catch (e) {
          print('DEBUG: ❌ Error counting students for course ${course.id}: $e');
        }
      }
      print('DEBUG: ✅ Total students count: $studentsCount');

      // 4. Lấy groups count - gọi repository trực tiếp (GroupRepository là static methods)
      int totalGroups = 0;
      for (final course in coursesForMetrics) {
        final groups = await GroupRepository.getGroupsByCourse(course.id);
        totalGroups += groups.length;
      }

      // 5. Lấy assignments count - gọi repository trực tiếp (AssignmentRepository là static methods)
      int totalAssignments = 0;
      print('DEBUG: 📊 Counting assignments for ${coursesForMetrics.length} courses');
      for (final course in coursesForMetrics) {
        try {
          final assignments = await AssignmentRepository.getAssignmentsByCourse(course.id);
          print('DEBUG: 📝 Course "${course.name}" (${course.id}): ${assignments.length} assignments');
          totalAssignments += assignments.length;
        } catch (e) {
          print('DEBUG: ❌ Error loading assignments for course ${course.id}: $e');
        }
      }
      print('DEBUG: ✅ Total assignments count: $totalAssignments');

      // 5. Tạm thời quizzes = 0 (tương tự student dashboard)
      // TODO: Implement quiz logic nếu có collection quizzes riêng

      return InstructorKPIStats(
        coursesCount: coursesCount,
        groupsCount: totalGroups,
        studentsCount: studentsCount,
        assignmentsCount: totalAssignments,
        quizzesCount: 0,
      );
    } catch (e) {
      print('DEBUG: ❌ Error fetching instructor KPI stats: $e');
      return const InstructorKPIStats(
        coursesCount: 0,
        groupsCount: 0,
        studentsCount: 0,
        assignmentsCount: 0,
        quizzesCount: 0,
      );
    }
  },
);

// ========================================
// PROVIDER: Instructor Tasks for Calendar (convert from Assignments)
// ========================================
// Key class để combine date và semester
class InstructorTaskKey {
  final DateTime date;
  final String semesterName;
  
  const InstructorTaskKey(this.date, this.semesterName);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstructorTaskKey &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          semesterName == other.semesterName;
  
  @override
  int get hashCode => date.hashCode ^ semesterName.hashCode;
}

final instructorTasksForDateProvider = FutureProvider.family<List<TaskModel>, InstructorTaskKey>((ref, key) async {
  final date = key.date;
  final semesterName = key.semesterName;
  
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return [];
  }

  try {
    // Lấy controller từ provider để gọi repository methods
    final courseController = ref.read(courseInstructorControllerProvider);
    
    // Lấy courses của instructor - filter theo semester giống như KPI stats
    List<CourseModel> coursesForTasks;
    
    if (semesterName.isNotEmpty && semesterName != 'All') {
      print('DEBUG: 🔍 Loading tasks for date ${date.toString()} with semester: "$semesterName"');
      
      // Tìm semester từ repository để lấy semester string chính xác
      String? actualSemesterString;
      try {
        final semesterRepo = SemesterRepository();
        final allSemesters = await semesterRepo.getAllSemesters();
        
        final matchedSemester = allSemesters.firstWhere(
          (s) => s.name.toLowerCase().trim() == semesterName.toLowerCase().trim() ||
                 s.code.toLowerCase().trim() == semesterName.toLowerCase().trim() ||
                 s.id.toLowerCase().trim() == semesterName.toLowerCase().trim(),
          orElse: () {
            try {
              return allSemesters.firstWhere(
                (s) => s.name.toLowerCase().contains(semesterName.toLowerCase()) ||
                       semesterName.toLowerCase().contains(s.name.toLowerCase()) ||
                       s.code.toLowerCase().contains(semesterName.toLowerCase()) ||
                       semesterName.toLowerCase().contains(s.code.toLowerCase()),
              );
            } catch (e) {
              return allSemesters.isNotEmpty ? allSemesters.first : throw Exception('No semesters found');
            }
          },
        );
        
        actualSemesterString = matchedSemester.name;
      } catch (e) {
        actualSemesterString = semesterName;
      }
      
      // Sử dụng controller method để lấy courses theo semester
      try {
        coursesForTasks = await courseController.getInstructorCoursesBySemester(actualSemesterString);
      } catch (e) {
        // Fallback: lấy tất cả courses và filter thủ công
        final allCourses = await courseController.getInstructorCourses();
        coursesForTasks = allCourses.where((course) {
          final courseSemester = course.semester.toLowerCase().trim();
          final filterSemester = actualSemesterString!.toLowerCase().trim();
          return courseSemester.contains(filterSemester) || 
                 filterSemester.contains(courseSemester);
        }).toList();
      }
    } else {
      // Lấy tất cả courses nếu không có semester filter
      coursesForTasks = await courseController.getInstructorCourses();
    }
    
    if (coursesForTasks.isEmpty) return [];

    // Lấy tất cả assignments từ các courses - gọi repository trực tiếp (AssignmentRepository là static methods)
    final List<Assignment> allAssignments = [];
    final Map<String, CourseModel> assignmentCourseMap = {};
    
    for (final course in coursesForTasks) {
      final assignments = await AssignmentRepository.getAssignmentsByCourse(course.id);
      allAssignments.addAll(assignments);
      for (final assignment in assignments) {
        assignmentCourseMap[assignment.id] = course;
      }
    }

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
        if (course == null) continue; // Skip nếu không tìm thấy course
        
        // Lấy số lượng students trong course - gọi repository trực tiếp (EnrollmentRepository là instance methods)
        final enrollmentRepo = EnrollmentRepository();
        final totalStudents = await enrollmentRepo.countStudentsInCourse(course.id);
        
        // Lấy submissions cho assignment này - gọi repository trực tiếp (SubmissionRepository là static methods)
        final submissions = await SubmissionRepository.getSubmissionsForAssignment(assignment.id);
        final submittedCount = submissions.length;
        final lateCount = submissions.where((s) => s.isLate).length;
        final notSubmittedCount = totalStudents > submittedCount ? totalStudents - submittedCount : 0;
        
        // Lấy groups được assign (nếu có) - cast thành List<String>
        final groupsApplied = assignment.groupIds.isNotEmpty 
            ? assignment.groupIds.map((id) => id.toString()).toList()
            : <String>[];

        tasks.add(TaskModel(
          id: assignment.id,
          title: assignment.title,
          description: assignment.description,
          dateTime: assignment.deadline,
          type: TaskType.assignment,
          courseName: course.name,
          courseId: course.id,
          isCompleted: false, // Instructor view không có completed concept
          isPriority: assignment.deadline.difference(DateTime.now()).inDays <= 1,
          groupsApplied: groupsApplied,
          submittedCount: submittedCount,
          totalCount: totalStudents,
          lateCount: lateCount,
          notSubmittedCount: notSubmittedCount,
        ));
      }
    }

    return tasks;
  } catch (e) {
    print('DEBUG: ❌ Error fetching instructor tasks for date: $e');
    return [];
  }
});

// ========================================
// PROVIDER: Instructor Tasks for Month (convert from Assignments)
// ========================================
// Key class để combine month và semester
class InstructorTaskMonthKey {
  final DateTime month;
  final String semesterName;
  
  const InstructorTaskMonthKey(this.month, this.semesterName);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstructorTaskMonthKey &&
          runtimeType == other.runtimeType &&
          month == other.month &&
          semesterName == other.semesterName;
  
  @override
  int get hashCode => month.hashCode ^ semesterName.hashCode;
}

final instructorTasksForMonthProvider = FutureProvider.family<List<TaskModel>, InstructorTaskMonthKey>((ref, key) async {
  final month = key.month;
  final semesterName = key.semesterName;
  
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return [];
  }

  try {
    // Lấy controller từ provider để gọi repository methods
    final courseController = ref.read(courseInstructorControllerProvider);
    
    // Lấy courses của instructor - filter theo semester giống như KPI stats
    List<CourseModel> coursesForTasks;
    
    if (semesterName.isNotEmpty && semesterName != 'All') {
      print('DEBUG: 🔍 Loading tasks for month ${month.toString()} with semester: "$semesterName"');
      
      // Tìm semester từ repository để lấy semester string chính xác
      String? actualSemesterString;
      dynamic matchedSemester; // Lưu matched semester để dùng trong fallback
      
      try {
        final semesterRepo = SemesterRepository();
        final allSemesters = await semesterRepo.getAllSemesters();
        
        matchedSemester = allSemesters.firstWhere(
          (s) => s.name.toLowerCase().trim() == semesterName.toLowerCase().trim() ||
                 s.code.toLowerCase().trim() == semesterName.toLowerCase().trim() ||
                 s.id.toLowerCase().trim() == semesterName.toLowerCase().trim(),
          orElse: () {
            try {
              return allSemesters.firstWhere(
                (s) => s.name.toLowerCase().contains(semesterName.toLowerCase()) ||
                       semesterName.toLowerCase().contains(s.name.toLowerCase()) ||
                       s.code.toLowerCase().contains(semesterName.toLowerCase()) ||
                       semesterName.toLowerCase().contains(s.code.toLowerCase()),
              );
            } catch (e) {
              return allSemesters.isNotEmpty ? allSemesters.first : throw Exception('No semesters found');
            }
          },
        );
        
        actualSemesterString = matchedSemester.name;
      } catch (e) {
        actualSemesterString = semesterName;
        matchedSemester = null;
      }
      
      // Sử dụng controller method để lấy courses theo semester
      try {
        coursesForTasks = await courseController.getInstructorCoursesBySemester(actualSemesterString!);
        
        // Nếu repository trả về empty (do exact match không khớp), dùng fallback filter thủ công
        if (coursesForTasks.isEmpty) {
          print('DEBUG: ⚠️ Repository returned 0 courses for tasks (exact match failed), using flexible filter');
          final allCourses = await courseController.getInstructorCourses();
          
          // Flexible matching: so sánh nhiều cách
          coursesForTasks = allCourses.where((course) {
            final courseSemester = course.semester.toLowerCase().trim();
            final filterSemester = actualSemesterString!.toLowerCase().trim();
            
            // Normalize: bỏ ký tự đặc biệt và khoảng trắng thừa
            final normalizedCourseSemester = courseSemester.replaceAll(RegExp(r'[_\s-]+'), ' ').trim();
            final normalizedFilter = filterSemester.replaceAll(RegExp(r'[_\s-]+'), ' ').trim();
            
            // Kiểm tra nhiều cách match
            bool matches = 
                normalizedCourseSemester == normalizedFilter ||
                normalizedCourseSemester.contains(normalizedFilter) ||
                normalizedFilter.contains(normalizedCourseSemester);
            
            // Nếu có matchedSemester, thử match với name và code
            if (!matches && matchedSemester != null) {
              final matchedSemesterName = matchedSemester.name.toLowerCase().trim();
              final matchedSemesterCode = matchedSemester.code.toLowerCase().trim();
              final normalizedMatchedName = matchedSemesterName.replaceAll(RegExp(r'[_\s-]+'), ' ').trim();
              final normalizedMatchedCode = matchedSemesterCode.replaceAll(RegExp(r'[_\s-]+'), ' ').trim();
              
              matches = 
                  normalizedCourseSemester == normalizedMatchedName ||
                  normalizedCourseSemester.contains(normalizedMatchedName) ||
                  normalizedMatchedName.contains(normalizedCourseSemester) ||
                  normalizedCourseSemester.contains(normalizedMatchedCode) ||
                  normalizedMatchedCode.contains(normalizedCourseSemester);
            }
            
            return matches;
          }).toList();
        }
      } catch (e) {
        // Fallback: lấy tất cả courses và filter thủ công
        final allCourses = await courseController.getInstructorCourses();
        coursesForTasks = allCourses.where((course) {
          final courseSemester = course.semester.toLowerCase().trim();
          final filterSemester = actualSemesterString!.toLowerCase().trim();
          return courseSemester.contains(filterSemester) || 
                 filterSemester.contains(courseSemester);
        }).toList();
      }
    } else {
      // Lấy tất cả courses nếu không có semester filter
      coursesForTasks = await courseController.getInstructorCourses();
    }
    
    // KHÔNG dùng fallback - nếu không có courses thì trả về empty tasks
    if (coursesForTasks.isEmpty) {
      print('DEBUG: ⚠️ No courses found for semester "$semesterName", returning empty tasks');
      return [];
    }

    // Lấy tất cả assignments từ các courses - gọi repository trực tiếp (AssignmentRepository là static methods)
    final List<Assignment> allAssignments = [];
    final Map<String, CourseModel> assignmentCourseMap = {};
    
    for (final course in coursesForTasks) {
      final assignments = await AssignmentRepository.getAssignmentsByCourse(course.id);
      allAssignments.addAll(assignments);
      for (final assignment in assignments) {
        assignmentCourseMap[assignment.id] = course;
      }
    }

    // Filter assignments trong tháng được chọn và convert sang TaskModel
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final tasks = <TaskModel>[];

    for (final assignment in allAssignments) {
      // Chỉ lấy assignments có deadline trong tháng được chọn
      if (assignment.deadline.isAfter(monthStart.subtract(const Duration(days: 1))) &&
          assignment.deadline.isBefore(monthEnd.add(const Duration(days: 1)))) {
        final course = assignmentCourseMap[assignment.id];
        if (course == null) continue; // Skip nếu không tìm thấy course
        
        // Lấy số lượng students trong course - gọi repository trực tiếp (EnrollmentRepository là instance methods)
        final enrollmentRepo = EnrollmentRepository();
        final totalStudents = await enrollmentRepo.countStudentsInCourse(course.id);
        
        // Lấy submissions cho assignment này - gọi repository trực tiếp (SubmissionRepository là static methods)
        final submissions = await SubmissionRepository.getSubmissionsForAssignment(assignment.id);
        final submittedCount = submissions.length;
        final lateCount = submissions.where((s) => s.isLate).length;
        final notSubmittedCount = totalStudents > submittedCount ? totalStudents - submittedCount : 0;
        
        // Lấy groups được assign (nếu có) - cast thành List<String>
        final groupsApplied = assignment.groupIds.isNotEmpty 
            ? assignment.groupIds.map((id) => id.toString()).toList()
            : <String>[];

        tasks.add(TaskModel(
          id: assignment.id,
          title: assignment.title,
          description: assignment.description,
          dateTime: assignment.deadline,
          type: TaskType.assignment,
          courseName: course.name,
          courseId: course.id,
          isCompleted: false,
          isPriority: assignment.deadline.difference(DateTime.now()).inDays <= 1,
          groupsApplied: groupsApplied,
          submittedCount: submittedCount,
          totalCount: totalStudents,
          lateCount: lateCount,
          notSubmittedCount: notSubmittedCount,
        ));
      }
    }

    return tasks;
  } catch (e) {
    print('DEBUG: ❌ Error fetching instructor tasks for month: $e');
    return [];
  }
});

// ========================================
// PROVIDER: Instructor Assignment Submission Stats (for pie chart)
// ========================================
final instructorAssignmentSubmissionStatsProvider = FutureProvider.family<Map<String, int>, String>(
  (ref, semesterName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {
        'notSubmitted': 0,
        'submitted': 0,
        'late': 0,
        'graded': 0,
      };
    }

    try {
      // Lấy controller từ provider để gọi repository methods
      final courseController = ref.read(courseInstructorControllerProvider);
      
      // Lấy courses của instructor - sử dụng controller method để filter theo semester
      List<CourseModel> coursesForMetrics;
      
      if (semesterName.isNotEmpty && semesterName != 'All') {
        // Tìm semester từ repository để lấy semester string chính xác
        String? actualSemesterString;
        try {
          final semesterRepo = SemesterRepository();
          final allSemesters = await semesterRepo.getAllSemesters();
          final matchedSemester = allSemesters.firstWhere(
            (s) => s.name.toLowerCase().trim() == semesterName.toLowerCase().trim() ||
                   s.code.toLowerCase().trim() == semesterName.toLowerCase().trim() ||
                   s.id.toLowerCase().trim() == semesterName.toLowerCase().trim(),
            orElse: () {
              try {
                return allSemesters.firstWhere(
                  (s) => s.name.toLowerCase().contains(semesterName.toLowerCase()) ||
                         semesterName.toLowerCase().contains(s.name.toLowerCase()) ||
                         s.code.toLowerCase().contains(semesterName.toLowerCase()) ||
                         semesterName.toLowerCase().contains(s.code.toLowerCase()),
                );
              } catch (e) {
                return allSemesters.isNotEmpty ? allSemesters.first : throw Exception('No semesters found');
              }
            },
          );
          actualSemesterString = matchedSemester.name;
        } catch (e) {
          actualSemesterString = semesterName;
        }
        
        // Sử dụng controller method để lấy courses theo semester
        try {
          coursesForMetrics = await courseController.getInstructorCoursesBySemester(actualSemesterString);
        } catch (e) {
          // Fallback: lấy tất cả courses và filter thủ công
          final allCourses = await courseController.getInstructorCourses();
          coursesForMetrics = allCourses.where((course) {
            final courseSemester = course.semester.toLowerCase().trim();
            final filterSemester = actualSemesterString!.toLowerCase().trim();
            return courseSemester.contains(filterSemester) || 
                   filterSemester.contains(courseSemester);
          }).toList();
        }
      } else {
        coursesForMetrics = await courseController.getInstructorCourses();
      }

      // KHÔNG dùng fallback - nếu không có courses thì trả về 0 stats
      if (coursesForMetrics.isEmpty) {
        print('DEBUG: ⚠️ No courses found for semester "$semesterName", returning empty stats');
        return {
          'notSubmitted': 0,
          'submitted': 0,
          'late': 0,
          'graded': 0,
        };
      }

      int notSubmitted = 0;
      int submitted = 0;
      int late = 0;
      int graded = 0;

      // Duyệt qua tất cả courses và assignments
      final enrollmentRepo = EnrollmentRepository();
      for (final course in coursesForMetrics) {
        // Gọi repository trực tiếp (AssignmentRepository là static methods)
        final assignments = await AssignmentRepository.getAssignmentsByCourse(course.id);
        final totalStudents = await enrollmentRepo.countStudentsInCourse(course.id);

        for (final assignment in assignments) {
          // Lấy submissions cho assignment này - gọi repository trực tiếp (SubmissionRepository là static methods)
          final submissions = await SubmissionRepository.getSubmissionsForAssignment(assignment.id);
          
          // Tính số students đã nộp
          final submittedCount = submissions.length;
          final notSubmittedCount = totalStudents > submittedCount ? totalStudents - submittedCount : 0;
          
          // Phân loại submissions:
          // - graded: đã được chấm điểm (bao gồm cả late và on-time)
          final gradedCount = submissions.where((s) => 
            s.status == SubmissionStatus.graded
          ).length;
          
          // - late: nộp muộn nhưng chưa graded
          final lateCount = submissions.where((s) => 
            s.isLate && s.status != SubmissionStatus.graded
          ).length;
          
          // - submitted: đã nộp, chưa graded, không late
          final submittedNotGraded = submissions.where((s) => 
            s.status == SubmissionStatus.submitted && !s.isLate
          ).length;

          notSubmitted += notSubmittedCount;
          submitted += submittedNotGraded;
          late += lateCount;
          graded += gradedCount;
        }
      }

      return {
        'notSubmitted': notSubmitted,
        'submitted': submitted,
        'late': late,
        'graded': graded,
      };
    } catch (e) {
      print('DEBUG: ❌ Error fetching assignment submission stats: $e');
      return {
        'notSubmitted': 0,
        'submitted': 0,
        'late': 0,
        'graded': 0,
      };
    }
  },
);

// ========================================
// PROVIDER: Instructor Quiz Completion Stats (for pie chart)
// ========================================
final instructorQuizCompletionStatsProvider = FutureProvider.family<Map<String, int>, String>(
  (ref, semesterName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {
        'completed': 0,
        'passed': 0,
        'failed': 0,
      };
    }

    try {
      // Lấy controller từ provider để gọi repository methods
      final courseController = ref.read(courseInstructorControllerProvider);
      
      // Lấy courses của instructor - sử dụng controller method để filter theo semester
      List<CourseModel> coursesForMetrics;
      
      if (semesterName.isNotEmpty && semesterName != 'All') {
        // Tìm semester từ repository để lấy semester string chính xác
        String? actualSemesterString;
        dynamic matchedSemester; // Lưu matched semester để dùng trong fallback
        
        try {
          final semesterRepo = SemesterRepository();
          final allSemesters = await semesterRepo.getAllSemesters();
          
          matchedSemester = allSemesters.firstWhere(
            (s) => s.name.toLowerCase().trim() == semesterName.toLowerCase().trim() ||
                   s.code.toLowerCase().trim() == semesterName.toLowerCase().trim() ||
                   s.id.toLowerCase().trim() == semesterName.toLowerCase().trim(),
            orElse: () {
              try {
                return allSemesters.firstWhere(
                  (s) => s.name.toLowerCase().contains(semesterName.toLowerCase()) ||
                         semesterName.toLowerCase().contains(s.name.toLowerCase()) ||
                         s.code.toLowerCase().contains(semesterName.toLowerCase()) ||
                         semesterName.toLowerCase().contains(s.code.toLowerCase()),
                );
              } catch (e) {
                return allSemesters.isNotEmpty ? allSemesters.first : throw Exception('No semesters found');
              }
            },
          );
          
          actualSemesterString = matchedSemester.name;
        } catch (e) {
          actualSemesterString = semesterName;
          matchedSemester = null;
        }
        
        // Sử dụng controller method để lấy courses theo semester
        try {
          coursesForMetrics = await courseController.getInstructorCoursesBySemester(actualSemesterString!);
          
          // Nếu repository trả về empty (do exact match không khớp), dùng fallback filter thủ công
          if (coursesForMetrics.isEmpty) {
            print('DEBUG: ⚠️ Repository returned 0 courses for quiz stats (exact match failed), using flexible filter');
            final allCourses = await courseController.getInstructorCourses();
            
            // Flexible matching: so sánh nhiều cách
            coursesForMetrics = allCourses.where((course) {
              final courseSemester = course.semester.toLowerCase().trim();
              final filterSemester = actualSemesterString!.toLowerCase().trim();
              
              // Normalize: bỏ ký tự đặc biệt và khoảng trắng thừa
              final normalizedCourseSemester = courseSemester.replaceAll(RegExp(r'[_\s-]+'), ' ').trim();
              final normalizedFilter = filterSemester.replaceAll(RegExp(r'[_\s-]+'), ' ').trim();
              
              // Kiểm tra nhiều cách match
              bool matches = 
                  normalizedCourseSemester == normalizedFilter ||
                  normalizedCourseSemester.contains(normalizedFilter) ||
                  normalizedFilter.contains(normalizedCourseSemester);
              
              // Nếu có matchedSemester, thử match với name và code
              if (!matches && matchedSemester != null) {
                final matchedSemesterName = matchedSemester.name.toLowerCase().trim();
                final matchedSemesterCode = matchedSemester.code.toLowerCase().trim();
                final normalizedMatchedName = matchedSemesterName.replaceAll(RegExp(r'[_\s-]+'), ' ').trim();
                final normalizedMatchedCode = matchedSemesterCode.replaceAll(RegExp(r'[_\s-]+'), ' ').trim();
                
                matches = 
                    normalizedCourseSemester == normalizedMatchedName ||
                    normalizedCourseSemester.contains(normalizedMatchedName) ||
                    normalizedMatchedName.contains(normalizedCourseSemester) ||
                    normalizedCourseSemester.contains(normalizedMatchedCode) ||
                    normalizedMatchedCode.contains(normalizedCourseSemester);
              }
              
              return matches;
            }).toList();
          }
        } catch (e) {
          // Fallback: lấy tất cả courses và filter thủ công
          final allCourses = await courseController.getInstructorCourses();
          coursesForMetrics = allCourses.where((course) {
            final courseSemester = course.semester.toLowerCase().trim();
            final filterSemester = actualSemesterString!.toLowerCase().trim();
            return courseSemester.contains(filterSemester) || 
                   filterSemester.contains(courseSemester);
          }).toList();
        }
      } else {
        coursesForMetrics = await courseController.getInstructorCourses();
      }

      int completed = 0;
      int passed = 0;
      int failed = 0;

      // Duyệt qua tất cả courses và assignments (tạm thời coi assignments là quizzes)
      for (final course in coursesForMetrics) {
        // Gọi repository trực tiếp (AssignmentRepository là static methods)
        final assignments = await AssignmentRepository.getAssignmentsByCourse(course.id);

        for (final assignment in assignments) {
          // Lấy submissions cho assignment này - gọi repository trực tiếp (SubmissionRepository là static methods)
          final submissions = await SubmissionRepository.getSubmissionsForAssignment(assignment.id);
          
          // Tính số submissions đã completed (submitted hoặc graded)
          final completedCount = submissions.where((s) => 
            s.status == SubmissionStatus.submitted || s.status == SubmissionStatus.graded
          ).length;
          
          // Tính số submissions đã passed (graded với score >= passing score)
          // Tạm thời coi graded là passed, có thể cần logic phức tạp hơn
          final passedCount = submissions.where((s) => 
            s.status == SubmissionStatus.graded && (s.score ?? 0) >= (assignment.maxPoints * 0.5)
          ).length;
          
          // Tính số submissions đã failed (graded với score < passing score)
          final failedCount = submissions.where((s) => 
            s.status == SubmissionStatus.graded && (s.score ?? 0) < (assignment.maxPoints * 0.5)
          ).length;

          completed += completedCount;
          passed += passedCount;
          failed += failedCount;
        }
      }

      return {
        'completed': completed,
        'passed': passed,
        'failed': failed,
      };
    } catch (e) {
      print('DEBUG: ❌ Error fetching quiz completion stats: $e');
      return {
        'completed': 0,
        'passed': 0,
        'failed': 0,
      };
    }
  },
);

