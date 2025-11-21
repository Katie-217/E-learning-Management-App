import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/presentation/screens/student/course/course_detail.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/widget_course/instructor_course_tabs_widget.dart';
// ✅ Import Provider mới tạo
import 'package:elearning_management_app/application/controllers/course/course_detail_provider.dart';

class InstructorCourseDetailPage extends ConsumerStatefulWidget {
  final String courseId;

  const InstructorCourseDetailPage({
    super.key,
    required this.courseId,
  });

  @override
  ConsumerState<InstructorCourseDetailPage> createState() =>
      _InstructorCourseDetailPageState();
}

class _InstructorCourseDetailPageState
    extends ConsumerState<InstructorCourseDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 1. Lắng nghe dữ liệu từ Provider
    final courseAsyncValue = ref.watch(courseDetailProvider(widget.courseId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      // ✅ 2. Xử lý 3 trạng thái: Loading, Error, Data
      body: courseAsyncValue.when(
        // Trạng thái đang tải
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
        
        // Trạng thái lỗi (ví dụ: không tìm thấy course hoặc không phải giảng viên của course này)
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
                  // Thử tải lại
                  ref.refresh(courseDetailProvider(widget.courseId));
                },
                child: const Text('Retry'),
              )
            ],
          ),
        ),

        // Trạng thái có dữ liệu
        data: (course) {
          if (course == null) {
             return const Center(child: Text('Course not found', style: TextStyle(color: Colors.white)));
          }

          return Column(
            children: [
              // Course Header
              CourseDetailHeader(
                course: course, // ✅ Truyền data thật
                onBack: () => Navigator.pop(context),
              ),

              // Course Tabs (Stream, Classwork, People)
              Expanded(
                child: InstructorCourseTabsWidget(
                  tabController: _tabController,
                  course: course, // ✅ Truyền data thật xuống các tab con
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}