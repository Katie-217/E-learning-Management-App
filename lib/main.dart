// ========================================
// FILE: main.dart
// MÔ TẢ: File khởi tạo ứng dụng chính
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/dashboard/presentation/student_dashboard.dart';
import 'features/dashboard/presentation/dashboard_view.dart';
import 'features/role_selection/legacy/role_selection_screen.dart';
import 'features/auth/legacy/login_screen.dart';
import 'features/auth/presentation/auth_overlay_screen.dart';
import 'core/enums/user_role.dart';
import 'core/models/course.dart';

// ========================================
// HÀM: main()
// MÔ TẢ: Hàm khởi tạo ứng dụng
// ========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ========================================
  // PHẦN: Khởi tạo Hive Database
  // MÔ TẢ: Thiết lập cơ sở dữ liệu local
  // ========================================
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(CourseAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(CourseStatusAdapter());
  }
  await Hive.openBox<Course>('courses');
  await Hive.openBox('app_cache');
  
  // ========================================
  // PHẦN: Chạy ứng dụng
  // MÔ TẢ: Khởi động ứng dụng với ProviderScope
  // ========================================
  runApp(
    ProviderScope(
      child: ClassroomApp(),
    ),
  );
}

// ========================================
// CLASS: ClassroomApp
// MÔ TẢ: Widget chính của ứng dụng
// ========================================
class ClassroomApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Dashboard',
      // ========================================
      // PHẦN: Cấu hình Theme sáng
      // MÔ TẢ: Thiết lập giao diện cho chế độ sáng
      // ========================================
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      // ========================================
      // PHẦN: Cấu hình Theme tối
      // MÔ TẢ: Thiết lập giao diện cho chế độ tối
      // ========================================
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      // ========================================
      // PHẦN: Màn hình khởi đầu
      // MÔ TẢ: Màn hình đầu tiên khi mở ứng dụng
      // ========================================
      // home: StudentDashboard(),
      // debugShowCheckedModeBanner: false,
      home: RoleSelectionScreen(),
      // ========================================
      // PHẦN: Định tuyến ứng dụng
      // MÔ TẢ: Cấu hình các đường dẫn điều hướng
      // ========================================
      routes: {
        '/role-selection': (context) => RoleSelectionScreen(),
        '/teacher-login': (context) => AuthOverlayScreen(userRole: UserRole.teacher),
        '/student-login': (context) => AuthOverlayScreen(userRole: UserRole.student),
        '/teacher-dashboard': (context) => DashboardView(),
        '/student-dashboard': (context) => StudentDashboard(),
        // Legacy demo screens (optional routes)
        '/legacy/role-selection': (context) => RoleSelectionScreen(),
      },
    );
  }
}
