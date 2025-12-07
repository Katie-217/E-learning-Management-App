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
      
      print('DEBUG: 🔄 Priority 2: Preloading ALL dashboard data for ALL semesters...');
      
      // PRIORITY 2: Preload TẤT CẢ data cho TẤT CẢ semesters (để user chọn bất kỳ gì cũng có data sẵn)
      final allPreloadFutures = <Future>[];
      
      // Preload với 'All' semester
      allPreloadFutures.addAll([
        ref.read(instructorKPIStatsProvider('All').future),
        ref.read(instructorAssignmentSubmissionStatsProvider('All').future),
        ref.read(instructorQuizCompletionStatsProvider('All').future),
      ]);
      
      // Preload tasks cho các tháng gần đây (3 tháng trước, hiện tại, 3 tháng sau)
      final monthsToPreload = <DateTime>[];
      for (int i = -3; i <= 3; i++) {
        final month = DateTime(now.year, now.month + i, 1);
        monthsToPreload.add(month);
      }
      
      // Preload với TẤT CẢ semesters
      for (final semester in semesters) {
        final semesterName = semester.name;
        
        // Preload stats cho mỗi semester
        allPreloadFutures.addAll([
          ref.read(instructorKPIStatsProvider(semesterName).future),
          ref.read(instructorAssignmentSubmissionStatsProvider(semesterName).future),
          ref.read(instructorQuizCompletionStatsProvider(semesterName).future),
        ]);
        
        // Preload tasks cho các tháng gần đây với mỗi semester
        for (final month in monthsToPreload) {
          allPreloadFutures.add(
            ref.read(instructorTasksForMonthProvider(
              InstructorTaskMonthKey(month, semesterName)
            ).future)
          );
        }
        
        // Preload tasks cho today với mỗi semester
        allPreloadFutures.add(
          ref.read(instructorTasksForDateProvider(
            InstructorTaskKey(now, semesterName)
          ).future)
        );
      }

      // Preload tất cả song song và await để đảm bảo hoàn thành trước khi hiển thị dashboard
      print('DEBUG: 🔄 Preloading ${allPreloadFutures.length} data sources for all semesters...');
      await Future.wait(allPreloadFutures, eagerError: false);
      
      print('DEBUG: ✅ Priority 2 completed: ALL dashboard data preloaded for ALL semesters');
      
      // PRIORITY 3: Preload tasks cho các tháng xa hơn (background, không block)
      print('DEBUG: 🔄 Priority 3: Preloading tasks for distant months (background)...');
      final backgroundPreloadFutures = <Future>[];
      
      // Preload tasks cho các tháng xa hơn (4-6 tháng trước/sau) với tất cả semesters
      for (int i = -6; i <= 6; i++) {
        if (i >= -3 && i <= 3) continue; // Đã preload ở priority 2
        final month = DateTime(now.year, now.month + i, 1);
        for (final semester in semesters) {
          backgroundPreloadFutures.add(
            ref.read(instructorTasksForMonthProvider(
              InstructorTaskMonthKey(month, semester.name)
            ).future)
          );
        }
      }

      // Chạy background preload song song, không await để không block UI
      Future.wait(backgroundPreloadFutures, eagerError: false).then((_) {
        print('DEBUG: ✅ Priority 3 completed: Distant months data preloaded (${backgroundPreloadFutures.length} sources)');
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
      
      print('DEBUG: 🔄 Priority 1: Preloading ALL dashboard data for ALL semesters...');
      
      // PRIORITY 1: Preload TẤT CẢ data cho TẤT CẢ semesters (để user chọn bất kỳ gì cũng có data sẵn)
      final prevMonthKey = DateTime(now.year, now.month - 1);
      final nextMonthKey = DateTime(now.year, now.month + 1);
      
      // Tạo danh sách tất cả futures cần preload
      final allPreloadFutures = <Future>[];
      
      // Preload Recent submissions và completed quizzes (chung cho tất cả semesters)
      allPreloadFutures.addAll([
        ref.read(studentRecentSubmissionsItemProvider.future),
        ref.read(studentCompletedQuizzesItemProvider.future),
      ]);
      
      // Preload data cho TẤT CẢ semesters
      for (final semester in semesters) {
        final semesterKeyForLoop = buildStudentSemesterKey(semester.id, semester.name);
        
        // Metrics cho mỗi semester
        allPreloadFutures.add(
          ref.read(studentDashboardMetricsProvider(semesterKeyForLoop).future)
        );
        
        // Tasks cho các tháng (prev, current, next) với mỗi semester
        allPreloadFutures.addAll([
          ref.read(studentTasksForMonthProvider(
            StudentTaskMonthKey(month: prevMonthKey, semesterKey: semesterKeyForLoop)
          ).future),
          ref.read(studentTasksForMonthProvider(
            StudentTaskMonthKey(month: monthKey, semesterKey: semesterKeyForLoop)
          ).future),
          ref.read(studentTasksForMonthProvider(
            StudentTaskMonthKey(month: nextMonthKey, semesterKey: semesterKeyForLoop)
          ).future),
          ref.read(studentTasksForDateProvider(
            StudentTaskDateKey(date: now, semesterKey: semesterKeyForLoop)
          ).future),
        ]);
      }
      
      // Preload tất cả song song và await để đảm bảo hoàn thành trước khi hiển thị dashboard
      print('DEBUG: 🔄 Preloading ${allPreloadFutures.length} data sources for all semesters...');
      await Future.wait(allPreloadFutures, eagerError: false);
      
      print('DEBUG: ✅ Priority 1 completed: ALL dashboard data preloaded for ALL semesters');
      
      // PRIORITY 2: Preload tasks cho các tháng xa hơn (background, không block)
      print('DEBUG: 🔄 Priority 2: Preloading tasks for distant months (background)...');
      final backgroundPreloadFutures = <Future>[];
      
      // Preload tasks cho các tháng xa hơn (3 tháng trước, 3 tháng sau) với tất cả semesters
      for (int i = -3; i <= 3; i++) {
        if (i == -1 || i == 0 || i == 1) continue; // Đã preload ở priority 1
        final month = DateTime(now.year, now.month + i, 1);
        for (final semester in semesters) {
          final semesterKeyForLoop = buildStudentSemesterKey(semester.id, semester.name);
          backgroundPreloadFutures.add(
            ref.read(studentTasksForMonthProvider(
              StudentTaskMonthKey(month: month, semesterKey: semesterKeyForLoop)
            ).future)
          );
        }
      }
      
      // Chạy background preload song song, không await để không block UI
      Future.wait(backgroundPreloadFutures, eagerError: false).then((_) {
        print('DEBUG: ✅ Priority 2 completed: Distant months data preloaded (${backgroundPreloadFutures.length} sources)');
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
