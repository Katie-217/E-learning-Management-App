# Riverpod Implementation Guide - E-learning Management App

## 🚀 Bước 1: Tạo Auth Provider (Priority cao)

### File: `lib/core/providers/auth_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_session_service.dart';
import '../services/auth_api_service.dart';

// Auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).asData?.value;
});

// User session data provider  
final userSessionProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  return UserSessionService.getUserFromFirestore(user.uid);
});

// User role provider
final userRoleProvider = Provider<String?>((ref) {
  final session = ref.watch(userSessionProvider).asData?.value;
  return session?['role'] ?? 'student';
});

// Authentication status provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// Login state provider
final loginStateProvider = StateNotifierProvider<LoginStateNotifier, AsyncValue<void>>((ref) {
  return LoginStateNotifier();
});

class LoginStateNotifier extends StateNotifier<AsyncValue<void>> {
  LoginStateNotifier() : super(const AsyncValue.data(null));
  
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      // Implement Google sign in logic
      await Future.delayed(Duration(seconds: 2)); // Placeholder
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await FirebaseAuth.instance.signOut();
      await UserSessionService.clearUserSession();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
```

## 🚀 Bước 2: Enhanced Course Provider

### File: `lib/core/providers/enhanced_course_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/course_model.dart';
import '../services/firestore_course_service.dart';
import 'auth_provider.dart';

// Search query provider
final courseSearchQueryProvider = StateProvider<String>((ref) => '');

// Selected semester filter
final selectedSemesterProvider = StateProvider<String>((ref) => 'All');

// Course status filter  
final courseStatusFilterProvider = StateProvider<String>((ref) => 'All');

// All courses stream
final allCoursesStreamProvider = StreamProvider<List<CourseModel>>((ref) {
  return FirestoreCourseService.getCoursesStream();
});

// User-specific courses
final userCoursesProvider = Provider<AsyncValue<List<CourseModel>>>((ref) {
  final allCoursesAsync = ref.watch(allCoursesStreamProvider);
  final userRole = ref.watch(userRoleProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  return allCoursesAsync.when(
    data: (courses) {
      if (userRole == 'teacher' && currentUser != null) {
        final teacherCourses = courses.where(
          (course) => course.instructorId == currentUser.uid
        ).toList();
        return AsyncValue.data(teacherCourses);
      } else if (userRole == 'student' && currentUser != null) {
        final studentCourses = courses.where(
          (course) => course.students.contains(currentUser.uid)
        ).toList();
        return AsyncValue.data(studentCourses);
      }
      return AsyncValue.data(courses);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Filtered courses based on search and filters
final filteredCoursesProvider = Provider<AsyncValue<List<CourseModel>>>((ref) {
  final userCoursesAsync = ref.watch(userCoursesProvider);
  final searchQuery = ref.watch(courseSearchQueryProvider).toLowerCase();
  final selectedSemester = ref.watch(selectedSemesterProvider);
  final statusFilter = ref.watch(courseStatusFilterProvider);
  
  return userCoursesAsync.when(
    data: (courses) {
      var filtered = courses;
      
      // Apply search filter
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((course) =>
          course.title.toLowerCase().contains(searchQuery) ||
          course.description.toLowerCase().contains(searchQuery)
        ).toList();
      }
      
      // Apply semester filter
      if (selectedSemester != 'All') {
        filtered = filtered.where((course) => 
          course.semester == selectedSemester
        ).toList();
      }
      
      // Apply status filter
      if (statusFilter != 'All') {
        filtered = filtered.where((course) => 
          course.status == statusFilter
        ).toList();
      }
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Course count by status
final courseCountByStatusProvider = Provider<Map<String, int>>((ref) {
  final userCoursesAsync = ref.watch(userCoursesProvider);
  
  return userCoursesAsync.when(
    data: (courses) {
      final counts = <String, int>{
        'Active': 0,
        'Completed': 0,
        'Draft': 0,
        'All': courses.length,
      };
      
      for (final course in courses) {
        counts[course.status] = (counts[course.status] ?? 0) + 1;
      }
      
      return counts;
    },
    loading: () => <String, int>{},
    error: (_, __) => <String, int>{},
  );
});
```

## 🚀 Bước 3: Assignment Management Provider

### File: `lib/features/assignments/providers/assignment_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/auth_provider.dart';
import '../models/assignment_model.dart';

// Assignment stream for a specific course
final assignmentsByCourseProvider = StreamProvider.family<List<Assignment>, String>((ref, courseId) {
  return FirebaseFirestore.instance
    .collection('assignments')
    .where('courseId', isEqualTo: courseId)
    .orderBy('dueDate', descending: false)
    .snapshots()
    .map((snapshot) => 
      snapshot.docs.map((doc) => Assignment.fromFirestore(doc)).toList()
    );
});

// All assignments for current user
final userAssignmentsProvider = StreamProvider<List<Assignment>>((ref) {
  final userRole = ref.watch(userRoleProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    return Stream.value(<Assignment>[]);
  }
  
  if (userRole == 'teacher') {
    // Get assignments created by teacher
    return FirebaseFirestore.instance
      .collection('assignments')
      .where('createdBy', isEqualTo: currentUser.uid)
      .snapshots()
      .map((snapshot) => 
        snapshot.docs.map((doc) => Assignment.fromFirestore(doc)).toList()
      );
  } else {
    // Get assignments for student's courses
    return FirebaseFirestore.instance
      .collection('assignments')
      .where('students', arrayContains: currentUser.uid)
      .snapshots()
      .map((snapshot) => 
        snapshot.docs.map((doc) => Assignment.fromFirestore(doc)).toList()
      );
  }
});

// Upcoming assignments (due within 7 days)
final upcomingAssignmentsProvider = Provider<List<Assignment>>((ref) {
  final assignmentsAsync = ref.watch(userAssignmentsProvider);
  
  return assignmentsAsync.when(
    data: (assignments) {
      final now = DateTime.now();
      final weekFromNow = now.add(Duration(days: 7));
      
      return assignments.where((assignment) =>
        assignment.dueDate.isAfter(now) &&
        assignment.dueDate.isBefore(weekFromNow)
      ).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Overdue assignments
final overdueAssignmentsProvider = Provider<List<Assignment>>((ref) {
  final assignmentsAsync = ref.watch(userAssignmentsProvider);
  
  return assignmentsAsync.when(
    data: (assignments) {
      final now = DateTime.now();
      
      return assignments.where((assignment) =>
        assignment.dueDate.isBefore(now) &&
        assignment.status != 'submitted'
      ).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Assignment submission provider
final assignmentSubmissionProvider = StateNotifierProvider.family<
  AssignmentSubmissionNotifier, 
  AsyncValue<void>, 
  String
>((ref, assignmentId) {
  return AssignmentSubmissionNotifier(assignmentId);
});

class AssignmentSubmissionNotifier extends StateNotifier<AsyncValue<void>> {
  final String assignmentId;
  
  AssignmentSubmissionNotifier(this.assignmentId) : super(const AsyncValue.data(null));
  
  Future<void> submitAssignment({
    required String content,
    List<String>? attachments,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      // Implement submission logic
      await FirebaseFirestore.instance.collection('submissions').add({
        'assignmentId': assignmentId,
        'content': content,
        'attachments': attachments ?? [],
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
      });
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
```

## 🚀 Bước 4: Progress Tracking Provider

### File: `lib/features/analytics/providers/progress_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../models/progress_model.dart';
import '../services/analytics_service.dart';

// Student progress for a specific course
final studentProgressProvider = FutureProvider.family<StudentProgress, String>((ref, courseId) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) throw Exception('User not authenticated');
  
  return AnalyticsService.getStudentProgress(currentUser.uid, courseId);
});

// Overall student progress (all courses)
final overallProgressProvider = FutureProvider<OverallProgress>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) throw Exception('User not authenticated');
  
  return AnalyticsService.getOverallProgress(currentUser.uid);
});

// Class analytics for teachers
final classAnalyticsProvider = FutureProvider.family<ClassAnalytics, String>((ref, courseId) async {
  final userRole = ref.watch(userRoleProvider);
  if (userRole != 'teacher') throw Exception('Unauthorized access');
  
  return AnalyticsService.getClassAnalytics(courseId);
});

// Progress statistics
final progressStatsProvider = Provider<ProgressStats>((ref) {
  final overallProgressAsync = ref.watch(overallProgressProvider);
  
  return overallProgressAsync.when(
    data: (progress) => ProgressStats(
      completionRate: progress.completionRate,
      averageGrade: progress.averageGrade,
      totalCourses: progress.totalCourses,
      completedCourses: progress.completedCourses,
    ),
    loading: () => ProgressStats.empty(),
    error: (_, __) => ProgressStats.empty(),
  );
});
```

## 🚀 Bước 5: Notification Provider

### File: `lib/features/notifications/providers/notification_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/auth_provider.dart';
import '../models/notification_model.dart';

// User notifications stream
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value(<AppNotification>[]);
  }
  
  return FirebaseFirestore.instance
    .collection('notifications')
    .where('userId', isEqualTo: currentUser.uid)
    .orderBy('createdAt', descending: true)
    .limit(50)
    .snapshots()
    .map((snapshot) =>
      snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList()
    );
});

// Unread notifications
final unreadNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  
  return notificationsAsync.when(
    data: (notifications) => notifications.where((n) => !n.isRead).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Unread count
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(unreadNotificationsProvider).length;
});

// Notification actions
final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref);
});

class NotificationActions {
  final Ref ref;
  
  NotificationActions(this.ref);
  
  Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
      .collection('notifications')
      .doc(notificationId)
      .update({'isRead': true});
  }
  
  Future<void> markAllAsRead() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    final batch = FirebaseFirestore.instance.batch();
    final notifications = await FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: currentUser.uid)
      .where('isRead', isEqualTo: false)
      .get();
    
    for (final doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    await batch.commit();
  }
  
  Future<void> deleteNotification(String notificationId) async {
    await FirebaseFirestore.instance
      .collection('notifications')
      .doc(notificationId)
      .delete();
  }
}
```

## 🚀 Bước 6: Settings Provider

### File: `lib/core/providers/settings_provider.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }
  
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('theme_mode') ?? 0;
    state = ThemeMode.values[themeModeIndex];
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }
}

// Language provider
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('vi') {
    _loadLanguage();
  }
  
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('language') ?? 'vi';
  }
  
  Future<void> setLanguage(String language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }
}

// App settings provider
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(AppSettings.defaultSettings()) {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      notifications: prefs.getBool('notifications') ?? true,
      emailNotifications: prefs.getBool('email_notifications') ?? true,
      pushNotifications: prefs.getBool('push_notifications') ?? true,
      autoSync: prefs.getBool('auto_sync') ?? true,
      offlineMode: prefs.getBool('offline_mode') ?? false,
    );
  }
  
  Future<void> updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    switch (key) {
      case 'notifications':
        state = state.copyWith(notifications: value);
        break;
      case 'email_notifications':
        state = state.copyWith(emailNotifications: value);
        break;
      case 'push_notifications':
        state = state.copyWith(pushNotifications: value);
        break;
      case 'auto_sync':
        state = state.copyWith(autoSync: value);
        break;
      case 'offline_mode':
        state = state.copyWith(offlineMode: value);
        break;
    }
  }
}

class AppSettings {
  final bool notifications;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool autoSync;
  final bool offlineMode;
  
  AppSettings({
    required this.notifications,
    required this.emailNotifications,
    required this.pushNotifications,
    required this.autoSync,
    required this.offlineMode,
  });
  
  static AppSettings defaultSettings() => AppSettings(
    notifications: true,
    emailNotifications: true,
    pushNotifications: true,
    autoSync: true,
    offlineMode: false,
  );
  
  AppSettings copyWith({
    bool? notifications,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? autoSync,
    bool? offlineMode,
  }) => AppSettings(
    notifications: notifications ?? this.notifications,
    emailNotifications: emailNotifications ?? this.emailNotifications,
    pushNotifications: pushNotifications ?? this.pushNotifications,
    autoSync: autoSync ?? this.autoSync,
    offlineMode: offlineMode ?? this.offlineMode,
  );
}
```

## 🚀 Bước 7: Update AuthWrapper để sử dụng Riverpod

### File: `lib/core/widgets/riverpod_auth_wrapper.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../../features/auth/presentation/pages/auth_overlay_screen.dart';
import 'main_shell.dart';

class RiverpodAuthWrapper extends ConsumerWidget {
  const RiverpodAuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp(
      title: 'E-Learning Management',
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const MainShell();
          } else {
            return const AuthOverlayScreen();
          }
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(authStateProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

## 🚀 Bước 8: Update main.dart

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/widgets/riverpod_auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: RiverpodAuthWrapper(),
    ),
  );
}
```

## ✅ Migration Checklist

- [ ] Tạo `auth_provider.dart`
- [ ] Tạo `enhanced_course_provider.dart` 
- [ ] Tạo `assignment_provider.dart`
- [ ] Tạo `progress_provider.dart`
- [ ] Tạo `notification_provider.dart`
- [ ] Tạo `settings_provider.dart`
- [ ] Update `AuthWrapper` thành `RiverpodAuthWrapper`
- [ ] Update `main.dart`
- [ ] Test authentication flow
- [ ] Test course management
- [ ] Test assignments
- [ ] Test notifications
- [ ] Test settings

## 🎯 Performance Considerations

1. **Use `.select()` cho selective updates**
2. **Implement caching strategies**  
3. **Use `.family` providers cho parameterized data**
4. **Implement proper error boundaries**
5. **Add loading states cho UX tốt hơn**

Các provider này sẽ giúp dự án của bạn có state management mạnh mẽ, type-safe và dễ maintain hơn rất nhiều!