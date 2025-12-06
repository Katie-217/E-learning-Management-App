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
import '../../../application/controllers/instructor/instructor_kpi_provider.dart';
import '../../../data/repositories/semester/semester_repository.dart';

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

      // Nếu là instructor, preload data NGAY LẬP TỨC trong lúc đang check auth
      if (role == 'teacher' || role == 'instructor') {
        print('DEBUG: 🔄 AuthWrapper - Preloading instructor data during auth check...');
        await _preloadInstructorData();
        setState(() {
          _dataPreloaded = true;
        });
        print('DEBUG: ✅ AuthWrapper - Data preloaded before showing dashboard');
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
      print('DEBUG: 🔄 Starting comprehensive data preload for all semesters...');
      
      // Preload courses
      await ref.read(courseInstructorProvider.notifier).loadInstructorCourses();
      print('DEBUG: ✅ Courses preloaded');

      // Lấy tất cả semesters
      final semesterRepo = SemesterRepository();
      final semesters = await semesterRepo.getAllSemesters();
      
      final now = DateTime.now();
      final monthKey = DateTime(now.year, now.month);
      
      // Preload tasks cho các tháng gần đây (3 tháng trước, hiện tại, 3 tháng sau)
      final monthsToPreload = <DateTime>[];
      for (int i = -3; i <= 3; i++) {
        final month = DateTime(now.year, now.month + i, 1);
        monthsToPreload.add(month);
      }

      // Tạo danh sách tất cả futures cần preload
      final preloadFutures = <Future>[];
      
      // Preload với 'All' semester
      preloadFutures.addAll([
        ref.read(instructorKPIStatsProvider('All').future),
        ref.read(instructorAssignmentSubmissionStatsProvider('All').future),
        ref.read(instructorQuizCompletionStatsProvider('All').future),
      ]);
      
      // Preload với TẤT CẢ semesters
      for (final semester in semesters) {
        final semesterName = semester.name;
        print('DEBUG: 🔄 Preloading data for semester: $semesterName');
        
        preloadFutures.addAll([
          ref.read(instructorKPIStatsProvider(semesterName).future),
          ref.read(instructorAssignmentSubmissionStatsProvider(semesterName).future),
          ref.read(instructorQuizCompletionStatsProvider(semesterName).future),
        ]);
        
        // Preload tasks cho current month với mỗi semester
        preloadFutures.add(
          ref.read(instructorTasksForMonthProvider(
            InstructorTaskMonthKey(monthKey, semesterName)
          ).future)
        );
        
        preloadFutures.add(
          ref.read(instructorTasksForDateProvider(
            InstructorTaskKey(now, semesterName)
          ).future)
        );
        
        // Preload tasks cho các tháng khác với mỗi semester
        for (final month in monthsToPreload) {
          if (month != monthKey) {
            preloadFutures.add(
              ref.read(instructorTasksForMonthProvider(
                InstructorTaskMonthKey(month, semesterName)
              ).future)
            );
          }
        }
      }

      // Preload tất cả song song
      print('DEBUG: 🔄 Preloading ${preloadFutures.length} data sources...');
      await Future.wait(preloadFutures);
      
      print('DEBUG: ✅ All instructor data preloaded for all semesters');
    } catch (e) {
      print('DEBUG: ⚠️ Error preloading instructor data: $e');
      // Không throw, để UI vẫn có thể hiển thị
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
                  ? 'Đang kiểm tra đăng nhập...' 
                  : 'Đang tải dữ liệu...',
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
