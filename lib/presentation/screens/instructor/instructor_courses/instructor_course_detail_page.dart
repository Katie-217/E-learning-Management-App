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

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmall = screenWidth < 600;
        
        return courseAsyncValue.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: Colors.indigo),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: EdgeInsets.all(isSmall ? 16 : 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline, 
                    color: Colors.red, 
                    size: isSmall ? 40 : 48,
                  ),
                  SizedBox(height: isSmall ? 12 : 16),
                  Text(
                    'Error loading course',
                    style: TextStyle(
                      color: Colors.red[300], 
                      fontSize: isSmall ? 16 : 18,
                    ),
                  ),
                  SizedBox(height: isSmall ? 6 : 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isSmall ? 16.0 : 32.0),
                    child: Text(
                      error.toString().replaceAll('Exception:', '').trim(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: isSmall ? 12 : 14,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmall ? 16 : 24),
                  ElevatedButton(
                    onPressed: () {
                      ref.refresh(courseDetailProvider(widget.courseId));
                    },
                    child: Text(
                      'Retry',
                      style: TextStyle(fontSize: isSmall ? 14 : 16),
                    ),
                  )
                ],
              ),
            ),
          ),
          data: (course) {
            if (course == null) {
              return Center(
                child: Text(
                  'Course not found',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmall ? 16 : 18,
                  ),
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
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}