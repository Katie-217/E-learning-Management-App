import 'package:elearning_management_app/presentation/widgets/common/role_based_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/auth/user_session_service.dart';

import '../presentation/screens/auth/auth_overlay_screen.dart';
import '../core/config/users-role.dart';
import '../presentation/screens/instructor/instructor_dashboard.dart';
import '../presentation/screens/instructor/instructor_students_page.dart';
// import '../presentation/screens/instructor/instructor_grades_page.dart';
import '../presentation/screens/profile/profile_view.dart';
import '../presentation/screens/course/course_page.dart';
import '../presentation/screens/instructor/instructor_courses/instructor_courses_page.dart';
import '../presentation/screens/instructor/instructor_courses/instructor_course_detail_page.dart';
import '../presentation/screens/assignment/assignments_page.dart';
import '../presentation/screens/instructor/instructor_student_create.dart';

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
        builder: (context, state) =>
            const AuthOverlayScreen(initialRole: UserRole.student),
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
// Thêm route để điều hướng đến CreateStudentPage
      GoRoute(
        path: '/instructor/students/create',
        name: 'create-student',
        builder: (context, state) => const CreateStudentPage(),
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
        builder: (context, state) => const InstructorCoursesPage(),
      ),
      GoRoute(
        path: '/instructor/courses/:courseId',
        name: 'instructor-course-detail',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return InstructorCourseDetailPage(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/instructor/assignments',
        name: 'instructor-assignments',
        builder: (context, state) => const AssignmentsPage(),
      ),
      // GoRoute(
      //   path: '/instructor/grades',
      //   name: 'instructor-grades',
      //   builder: (context, state) => const InstructorGradesPage(),
      // ),
    ],
  );
}