import 'package:elearning_management_app/presentation/widgets/common/role_based_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/auth/user_session_service.dart';

import '../presentation/screens/auth/auth_overlay_screen.dart';
import '../core/config/users-role.dart';
import '../presentation/screens/instructor/instructor_dashboard.dart';
import '../presentation/screens/instructor/instructor_students_page.dart';
import '../presentation/screens/instructor/instructor_grades_page.dart';
import '../presentation/screens/profile/profile_view.dart';
import '../presentation/screens/course/course_page.dart';
import '../presentation/screens/assignment/assignments_page.dart';
// import '../../presentation/screens/semester_page.dart';
// import '../../presentation/screens/course/course_page.dart';
// import '../../presentation/screens/group/group_page.dart';
// import '../../presentation/screens/student_page.dart';
// import '../../presentation/screens/csv_import_preview.dart';
// import '../../presentation/screens/announcement/announcements_page.dart';
// import '../../presentation/screens/assignment/assignments_page.dart';
// import '../../presentation/screens/quiz/quizzes_page.dart';
// import '../../presentation/screens/material/materials_page.dart';
// import '../../presentation/screens/forum_page.dart';
// import '../../presentation/screens/chat_page.dart';
// import '../../presentation/screens/notification/notification_page.dart';
// import '../../presentation/screens/analytics_page.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/auth',
    redirect: (context, state) async {
      final isLoggingIn = state.matchedLocation == '/auth';
      
      // Kiểm tra Firebase Auth trước
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        print('DEBUG: 🔍 Firebase user found: ${firebaseUser.email}');
        if (isLoggingIn) return '/dashboard';
        return null;
      }
      
      // Nếu không có Firebase user, kiểm tra SharedPreferences
      final hasSession = await UserSessionService.isUserLoggedIn();
      print('DEBUG: 🔍 SharedPreferences session: $hasSession');
      
      if (!hasSession && !isLoggingIn) {
        print('DEBUG: ❌ No session found, redirecting to auth');
        return '/auth';
      }
      
      if (hasSession && isLoggingIn) {
        print('DEBUG: ✅ Session found, redirecting to dashboard');
        return '/dashboard';
      }
      
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthOverlayScreen(initialRole: UserRole.student),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const RoleBasedDashboard(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileView(),
      ),
      GoRoute(
        path: '/courses',
        name: 'courses',
        builder: (context, state) => const CoursePage(),
      ),
      // Instructor routes
      GoRoute(
        path: '/instructor',
        redirect: (context, state) => '/instructor/dashboard',
      ),
      GoRoute(
        path: '/instructor/dashboard',
        name: 'instructor-dashboard',
        builder: (context, state) => const InstructorDashboard(),
      ),
      GoRoute(
        path: '/instructor/students',
        name: 'instructor-students',
        builder: (context, state) => const InstructorStudentsPage(),
      ),
      GoRoute(
        path: '/instructor/courses',
        name: 'instructor-courses',
        builder: (context, state) => const CoursePage(),
      ),
      GoRoute(
        path: '/instructor/assignments',
        name: 'instructor-assignments',
        builder: (context, state) => const AssignmentsPage(),
      ),
      GoRoute(
        path: '/instructor/grades',
        name: 'instructor-grades',
        builder: (context, state) => const InstructorGradesPage(),
      ),
      // GoRoute(path: '/semesters', builder: (c, s) => const SemesterPage()),
      // GoRoute(path: '/groups', builder: (c, s) => const GroupPage()),
      // GoRoute(path: '/students', builder: (c, s) => const StudentPage()),
      // GoRoute(path: '/csv-import', builder: (c, s) => const CsvImportPreviewPage()),
      // GoRoute(path: '/announcements', builder: (c, s) => const AnnouncementsPage()),
      // GoRoute(path: '/quizzes', builder: (c, s) => const QuizzesPage()),
      // GoRoute(path: '/materials', builder: (c, s) => const MaterialsPage()),
      // GoRoute(path: '/forum', builder: (c, s) => const ForumPage()),
      // GoRoute(path: '/chat', builder: (c, s) => const ChatPage()),
      // GoRoute(path: '/notifications', builder: (c, s) => const NotificationsView()),
      // GoRoute(path: '/analytics', builder: (c, s) => const AnalyticsPage()),
    ],
  // static const String auth = '/auth';
  // static const String dashboard = '/dashboard';
  // static const String profile = '/profile';
  // static const String content = '/content';
  // static const String forum = '/forum';
  // static const String notifications = '/notifications';
  // static const String analytics = '/analytics';
  );
}


