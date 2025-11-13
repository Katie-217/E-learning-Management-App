import 'package:elearning_management_app/presentation/widgets/common/role_based_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_session_manager.dart';

import '../presentation/screens/auth/auth_overlay_screen.dart';
import '../core/config/users-role.dart';
import '../presentation/screens/instructor/instructor_dashboard.dart';
import '../presentation/screens/instructor/instructor_students_page.dart';
import '../presentation/screens/instructor/instructor_grades_page.dart';
import '../presentation/screens/profile/profile_view.dart';
import '../presentation/screens/course/course_page.dart';
import '../presentation/screens/assignment/assignments_page.dart';
import '../presentation/widgets/common/main_shell.dart';
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

      final session = await AuthSessionManager.restoreSession();
      final hasSession = session != null && !session.isExpired;

      if (!hasSession && !isLoggingIn) {
        return '/auth';
      }

      if (hasSession && isLoggingIn) {
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
        path: '/student/dashboard',
        name: 'student-dashboard',
        builder: (context, state) => const MainShell(),
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
    ],
  );
}


