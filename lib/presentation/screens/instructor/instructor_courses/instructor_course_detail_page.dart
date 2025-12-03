import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ 1. Thêm thư viện Auth
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/presentation/screens/student/course/course_detail.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/widget_course/instructor_course_tabs_widget.dart';
import 'package:elearning_management_app/application/controllers/course/course_detail_provider.dart';

class InstructorCourseDetailPage extends StatelessWidget {
  final String courseId;

  const InstructorCourseDetailPage({
    super.key,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      body: InstructorCourseDetailContent(
        courseId: courseId,
        onBack: () => Navigator.pop(context),
      ),
    );
  }
}

class InstructorCourseDetailContent extends ConsumerStatefulWidget {
  final String courseId;
  final VoidCallback? onBack;

  const InstructorCourseDetailContent({
    super.key,
    required this.courseId,
    this.onBack,
  });

  @override
  ConsumerState<InstructorCourseDetailContent> createState() =>
      _InstructorCourseDetailContentState();
}

class _InstructorCourseDetailContentState
    extends ConsumerState<InstructorCourseDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 4 tabs: Stream, Classwork, People, Grade
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin khóa học từ Provider
    final courseAsyncValue = ref.watch(courseDetailProvider(widget.courseId));
    
    // ✅ 2. Lấy thông tin Giảng viên đang đăng nhập (Current User)
    // Chúng ta dùng cái này vì CourseModel không lưu instructorId
    final currentUser = FirebaseAuth.instance.currentUser;
    final String currentUserId = currentUser?.uid ?? '';
    final String currentUserName = currentUser?.displayName ?? 'Instructor';

    return courseAsyncValue.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.indigo),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading course',
              style: TextStyle(color: Colors.red[300], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                error.toString().replaceAll('Exception:', '').trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.refresh(courseDetailProvider(widget.courseId));
              },
              child: const Text('Retry'),
            )
          ],
        ),
      ),
      data: (course) {
        if (course == null) {
          return const Center(
            child: Text(
              'Course not found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return Column(
          children: [
            CourseDetailHeader(
              course: course,
              onBack: widget.onBack,
            ),
            Expanded(
              child: InstructorCourseTabsWidget(
                tabController: _tabController,
                course: course,
                instructorId: currentUserId,
                instructorName: course.instructor.isNotEmpty 
                    ? course.instructor 
                    : currentUserName,
              ),
            ),
          ],
        );
      },
    );
  }
}