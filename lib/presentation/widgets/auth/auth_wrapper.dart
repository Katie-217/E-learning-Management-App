import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/auth/user_session_service.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/user_model.dart';
import '../../../core/config/users-role.dart';
import '../../screens/auth/auth_overlay_screen.dart';
import '../common/role_based_dashboard.dart';
import '../../../application/controllers/course/course_instructor_provider.dart';
import '../../../application/controllers/instructor/instructor_kpi_provider.dart'
    show instructorKPIStatsProvider, instructorAssignmentSubmissionStatsProvider,
         instructorQuizCompletionStatsProvider, instructorTasksForMonthProvider,
         instructorTasksForDateProvider, InstructorTaskMonthKey, InstructorTaskKey;
import '../../../application/controllers/student/student_dashboard_metrics_provider.dart'
    show studentDashboardMetricsProvider, studentRecentSubmissionsItemProvider, 
         studentCompletedQuizzesItemProvider, studentTasksForMonthProvider, 
         studentTasksForDateProvider, StudentTaskMonthKey, StudentTaskDateKey, 
         buildStudentSemesterKey;
import '../../../data/repositories/semester/semester_repository.dart';
import '../../../domain/models/semester_model.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _dataPreloaded = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkAuthStatusAndPreload();
  }

  Future<void> _checkAuthStatusAndPreload() async {
    try {
      // Check if user has valid session in SharedPreferences
      final hasSession = await UserSessionService.hasValidSession();
      
      if (hasSession) {
        // Nếu có session, lấy role và preload data
        await _getRoleAndPreload();
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
        return;
      }
      
      // Check current Firebase Auth user and get UserModel
      final authRepository = AuthRepository.defaultClient();
      final userModel = await authRepository.checkUserSession();
      
      if (userModel != null) {
        // Save session to SharedPreferences
        await UserSessionService.saveUserSession(userModel);
        // Lấy role và preload data
        await _getRoleAndPreload();
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error checking auth status: $e');
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _getRoleAndPreload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Lấy role từ Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first;
      final data = doc.data();
      final role = (data['role'] ?? '').toString().toLowerCase();
      
      setState(() {
        _userRole = role;
      });

      // Preload data NGAY LẬP TỨC trong lúc đang check auth
      if (role == 'teacher' || role == 'instructor') {
        print('DEBUG: 🔄 AuthWrapper - Preloading instructor data during auth check...');
        await _preloadInstructorData();
        setState(() {
          _dataPreloaded = true;
        });
        print('DEBUG: ✅ AuthWrapper - Instructor data preloaded before showing dashboard');
      } else if (role == 'student') {
        print('DEBUG: 🔄 AuthWrapper - Preloading student data during auth check...');
        await _preloadStudentData();
        setState(() {
          _dataPreloaded = true;
        });
        print('DEBUG: ✅ AuthWrapper - Student data preloaded before showing dashboard');
      } else {
        setState(() {
          _dataPreloaded = true;
        });
      }
    } catch (e) {
      print('DEBUG: ❌ Error getting role and preloading: $e');
      setState(() {
        _dataPreloaded = true;
      });
    }
  }

  Future<void> _preloadInstructorData() async {
    try {
      print('DEBUG: 🔄 Starting comprehensive data preload for instructor...');
      
      // PRIORITY 0: Preload semesters trước (cần thiết để xác định current semester)
      final semesterRepo = SemesterRepository();
      final semesters = await semesterRepo.getAllSemesters();
      print('DEBUG: ✅ Priority 0: Semesters preloaded (${semesters.length} semesters)');
      
      // PRIORITY 1: Preload courses trước (cần thiết cho tất cả data khác)
      await ref.read(courseInstructorProvider.notifier).loadInstructorCourses();
      print('DEBUG: ✅ Priority 1: Courses preloaded');
      
      if (semesters.isEmpty) {
        print('DEBUG: ⚠️ No semesters found, skipping preload');
        return;
      }
      
      final now = DateTime.now();
      final monthKey = DateTime(now.year, now.month);
      
      // Tìm học kì hiện tại (dựa vào isCurrentSemester)
      SemesterModel? currentSemester;
      for (final semester in semesters) {
        if (semester.isCurrentSemester) {
          currentSemester = semester;
          break;
        }
      }
      
      // Nếu không tìm thấy, chọn học kì đầu tiên
      final activeSemester = currentSemester ?? semesters.first;
      final activeSemesterName = activeSemester.name;
      
      print('DEBUG: 🔄 Priority 2: Preloading dashboard data for current semester: $activeSemesterName');
      
      // PRIORITY 2: Preload dashboard data cho học kì hiện tại trước
      await Future.wait([
        // KPI stats cho học kì hiện tại
        ref.read(instructorKPIStatsProvider(activeSemesterName).future),
        ref.read(instructorAssignmentSubmissionStatsProvider(activeSemesterName).future),
        ref.read(instructorQuizCompletionStatsProvider(activeSemesterName).future),
        // Tasks cho current month và today
        ref.read(instructorTasksForMonthProvider(
          InstructorTaskMonthKey(monthKey, activeSemesterName)
        ).future),
        ref.read(instructorTasksForDateProvider(
          InstructorTaskKey(now, activeSemesterName)
        ).future),
      ], eagerError: false);
      
      print('DEBUG: ✅ Priority 2 completed: Dashboard data preloaded');
      
      // PRIORITY 3: Preload data cho các semesters khác và các tháng khác (song song, không block)
      print('DEBUG: 🔄 Priority 3: Preloading data for other semesters and months...');
      final backgroundPreloadFutures = <Future>[];
      
      // Preload với 'All' semester
      backgroundPreloadFutures.addAll([
        ref.read(instructorKPIStatsProvider('All').future),
        ref.read(instructorAssignmentSubmissionStatsProvider('All').future),
        ref.read(instructorQuizCompletionStatsProvider('All').future),
      ]);
      
      // Preload tasks cho các tháng gần đây (3 tháng trước, 3 tháng sau)
      final monthsToPreload = <DateTime>[];
      for (int i = -3; i <= 3; i++) {
        if (i == 0) continue; // Đã preload ở priority 2
        final month = DateTime(now.year, now.month + i, 1);
        monthsToPreload.add(month);
      }
      
      // Preload với TẤT CẢ semesters (bao gồm cả active semester cho các tháng khác)
      for (final semester in semesters) {
        final semesterName = semester.name;
        
        // Preload stats cho các semesters khác
        if (semesterName != activeSemesterName) {
          backgroundPreloadFutures.addAll([
            ref.read(instructorKPIStatsProvider(semesterName).future),
            ref.read(instructorAssignmentSubmissionStatsProvider(semesterName).future),
            ref.read(instructorQuizCompletionStatsProvider(semesterName).future),
          ]);
        }
        
        // Preload tasks cho các tháng khác với mỗi semester
        for (final month in monthsToPreload) {
          backgroundPreloadFutures.add(
            ref.read(instructorTasksForMonthProvider(
              InstructorTaskMonthKey(month, semesterName)
            ).future)
          );
        }
        
        // Preload tasks cho current month với các semesters khác
        if (semesterName != activeSemesterName) {
          backgroundPreloadFutures.add(
            ref.read(instructorTasksForMonthProvider(
              InstructorTaskMonthKey(monthKey, semesterName)
            ).future)
          );
        }
      }

      // Chạy background preload song song, không await để không block UI
      Future.wait(backgroundPreloadFutures, eagerError: false).then((_) {
        print('DEBUG: ✅ Priority 3 completed: All other data preloaded (${backgroundPreloadFutures.length} sources)');
      }).catchError((e) {
        print('DEBUG: ⚠️ Error in background preload: $e');
      });
      
      print('DEBUG: ✅ Instructor data preload strategy completed');
    } catch (e, stackTrace) {
      print('DEBUG: ⚠️ Error preloading instructor data: $e');
      print('DEBUG: Stack trace: $stackTrace');
      // Không throw error để không block UI, nhưng log đầy đủ để debug
    }
  }

  Future<void> _preloadStudentData() async {
    try {
      print('DEBUG: 🔄 Starting comprehensive data preload for student...');
      
      // PRIORITY 0: Preload semesters trước (cần thiết để xác định current semester)
      final semesterRepo = SemesterRepository();
      final semesters = await semesterRepo.getAllSemesters();
      print('DEBUG: ✅ Priority 0: Semesters preloaded (${semesters.length} semesters)');
      
      if (semesters.isEmpty) {
        print('DEBUG: ⚠️ No semesters found, skipping preload');
        return;
      }
      
      final now = DateTime.now();
      final monthKey = DateTime(now.year, now.month);
      
      // Tìm học kì hiện tại (dựa vào isCurrentSemester)
      SemesterModel? currentSemester;
      for (final semester in semesters) {
        if (semester.isCurrentSemester) {
          currentSemester = semester;
          break;
        }
      }
      
      // Nếu không tìm thấy, tìm học kì có today trong range
      if (currentSemester == null) {
        for (final semester in semesters) {
          final todayInRange = now.isBefore(semester.endDate.add(const Duration(days: 1))) &&
                              now.isAfter(semester.startDate.subtract(const Duration(days: 1)));
          if (todayInRange) {
            currentSemester = semester;
            break;
          }
        }
      }
      
      // Nếu vẫn không tìm thấy, chọn học kì active đầu tiên
      final activeSemester = currentSemester ?? semesters.first;
      final semesterKey = buildStudentSemesterKey(activeSemester.id, activeSemester.name);
      
      print('DEBUG: 🔄 Priority 1: Preloading dashboard data for current semester: ${activeSemester.name} (key: $semesterKey)');
      
      // PRIORITY 1: Preload dashboard data trước (current semester)
      final prevMonthKey = DateTime(now.year, now.month - 1);
      final nextMonthKey = DateTime(now.year, now.month + 1);
      
      await Future.wait([
        // Dashboard metrics (quan trọng nhất)
        ref.read(studentDashboardMetricsProvider(semesterKey).future),
        // Recent submissions và completed quizzes (cho dashboard)
        ref.read(studentRecentSubmissionsItemProvider.future),
        ref.read(studentCompletedQuizzesItemProvider.future),
        // Tasks cho calendar (prev, current, next month)
        ref.read(studentTasksForMonthProvider(
          StudentTaskMonthKey(month: prevMonthKey, semesterKey: semesterKey)
        ).future),
        ref.read(studentTasksForMonthProvider(
          StudentTaskMonthKey(month: monthKey, semesterKey: semesterKey)
        ).future),
        ref.read(studentTasksForMonthProvider(
          StudentTaskMonthKey(month: nextMonthKey, semesterKey: semesterKey)
        ).future),
        ref.read(studentTasksForDateProvider(
          StudentTaskDateKey(date: now, semesterKey: semesterKey)
        ).future),
      ], eagerError: false);
      
      print('DEBUG: ✅ Priority 1 completed: Dashboard data preloaded');
      
      // PRIORITY 2: Preload data cho các semesters khác và các tháng khác (song song, không block)
      print('DEBUG: 🔄 Priority 2: Preloading data for other semesters and months...');
      final backgroundPreloadFutures = <Future>[];
      
      // Preload tasks cho các tháng xa hơn (2 tháng trước, 2 tháng sau)
      for (int i = -2; i <= 2; i++) {
        if (i == -1 || i == 0 || i == 1) continue; // Đã preload ở priority 1
        final month = DateTime(now.year, now.month + i, 1);
        backgroundPreloadFutures.add(
          ref.read(studentTasksForMonthProvider(
            StudentTaskMonthKey(month: month, semesterKey: semesterKey)
          ).future)
        );
      }
      
      // Preload metrics cho các semesters khác
      for (final semester in semesters) {
        if (semester.id == activeSemester.id) continue; // Đã preload ở priority 1
        final otherSemesterKey = buildStudentSemesterKey(semester.id, semester.name);
        backgroundPreloadFutures.add(
          ref.read(studentDashboardMetricsProvider(otherSemesterKey).future)
        );
        
        // Preload tasks cho current month với các semesters khác
        backgroundPreloadFutures.add(
          ref.read(studentTasksForMonthProvider(
            StudentTaskMonthKey(month: monthKey, semesterKey: otherSemesterKey)
          ).future)
        );
      }
      
      // Chạy background preload song song, không await để không block UI
      Future.wait(backgroundPreloadFutures, eagerError: false).then((_) {
        print('DEBUG: ✅ Priority 2 completed: All other data preloaded');
      }).catchError((e) {
        print('DEBUG: ⚠️ Error in background preload: $e');
      });
      
      print('DEBUG: ✅ Student data preload strategy completed');
    } catch (e, stackTrace) {
      print('DEBUG: ⚠️ Error preloading student data: $e');
      print('DEBUG: Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Dashboard',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: _buildCurrentScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _buildCurrentScreen() {
    if (_isLoading || (_isAuthenticated && !_dataPreloaded)) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                _isLoading 
                  ? 'Loading...'
                  : 'Data loading...',
              ),
            ],
          ),
        ),
      );
    }

    if (_isAuthenticated) {
      return RoleBasedDashboard();
    } else {
      return AuthOverlayScreen(initialRole: UserRole.student);
    }
  }
}
