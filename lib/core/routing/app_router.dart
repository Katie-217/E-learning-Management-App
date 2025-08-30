import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_overlay_screen.dart';
import '../../core/enums/user_role.dart';
import '../../features/dashboard/presentation/dashboard_view.dart';
import '../../features/profile/presentation/profile_view.dart';
import '../../features/semester_course_group_student/semester_page.dart';
import '../../features/semester_course_group_student/course_page.dart';
import '../../features/semester_course_group_student/group_page.dart';
import '../../features/semester_course_group_student/student_page.dart';
import '../../features/semester_course_group_student/csv_import_preview.dart';
import '../../features/content/announcements_page.dart';
import '../../features/content/assignments_page.dart';
import '../../features/content/quizzes_page.dart';
import '../../features/content/materials_page.dart';
import '../../features/forum_chat/forum_page.dart';
import '../../features/forum_chat/chat_page.dart';
import '../../features/notifications/notification_page.dart';
import '../../features/analytics/analytics_page.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/auth',
    routes: <RouteBase>[
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => AuthOverlayScreen(userRole: UserRole.student),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardView(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileView(),
      ),
      GoRoute(path: '/semesters', builder: (c, s) => const SemesterPage()),
      GoRoute(path: '/courses', builder: (c, s) => const CoursePage()),
      GoRoute(path: '/groups', builder: (c, s) => const GroupPage()),
      GoRoute(path: '/students', builder: (c, s) => const StudentPage()),
      GoRoute(path: '/csv-import', builder: (c, s) => const CsvImportPreviewPage()),
      GoRoute(path: '/announcements', builder: (c, s) => const AnnouncementsPage()),
      GoRoute(path: '/assignments', builder: (c, s) => const AssignmentsPage()),
      GoRoute(path: '/quizzes', builder: (c, s) => const QuizzesPage()),
      GoRoute(path: '/materials', builder: (c, s) => const MaterialsPage()),
      GoRoute(path: '/forum', builder: (c, s) => const ForumPage()),
      GoRoute(path: '/chat', builder: (c, s) => const ChatPage()),
      GoRoute(path: '/notifications', builder: (c, s) => const NotificationPage()),
      GoRoute(path: '/analytics', builder: (c, s) => const AnalyticsPage()),
    ],
  );
}


