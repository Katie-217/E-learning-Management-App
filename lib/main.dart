import 'package:elearning_management_app/features/courses/presentation/pages/course_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/student/presentation/pages/student_dashboard_page.dart';
import 'core/widgets/main_shell.dart';
import 'features/instructor/presentation/pages/instructor_dashboard.dart';
import 'features/auth/presentation/pages/auth_overlay_screen.dart';
import 'core/config/users-role.dart';
import 'data/models/course_model.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Khởi tạo Hive Database
  // Thiết lập cơ sở dữ liệu local
  // await Hive.initFlutter();
  // if (!Hive.isAdapterRegistered(0)) {
  //   Hive.registerAdapter(CourseAdapter());
  // }
  // if (!Hive.isAdapterRegistered(1)) {
  //   Hive.registerAdapter(CourseStatusAdapter());
  // }
  // await Hive.openBox<Course>('courses');
  // await Hive.openBox('app_cache');

  runApp(
    const ProviderScope(
      child: ClassroomApp(),
    ),
  );
}

class ClassroomApp extends StatelessWidget {
  const ClassroomApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Dashboard',
      themeMode: ThemeMode.dark,

      // // Cấu hình Theme sáng
       theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
    ),
  ),

      // PHẦN: Cấu hình Theme tối
    darkTheme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A), // 🔹 nền tối hơn
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


      //Màn hình khởi đầu
      // home: AuthOverlayScreen(),
      home: const MainShell(),
      debugShowCheckedModeBanner: false,

      // Định tuyến ứng dụng
      routes: {
        '/role-selection': (context) => const AuthOverlayScreen(),
        '/teacher-login': (context) => const AuthOverlayScreen(initialRole: UserRole.teacher),
        '/student-login': (context) => const AuthOverlayScreen(initialRole: UserRole.student),
        '/teacher-dashboard': (context) => const InstructorDashboard(),
        '/instructor-dashboard': (context) => const InstructorDashboard(),
        '/student-dashboard': (context) => const StudentDashboardPage(),
        '/course': (context) => const CoursePage(),
      },
    );
  }
}
