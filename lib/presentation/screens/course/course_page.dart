import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/presentation/widgets/course/course_card_widget.dart';
import 'package:elearning_management_app/presentation/widgets/course/course_detail.dart';
import 'package:elearning_management_app/presentation/widgets/course/course_tabs_widget.dart';
import 'package:elearning_management_app/presentation/widgets/course/course_filter_widget.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';
import 'package:elearning_management_app/presentation/widgets/common/sidebar_model.dart';
import 'package:elearning_management_app/application/controllers/course/course_provider.dart';

class CoursePage extends ConsumerStatefulWidget {
  final bool showSidebar;
  const CoursePage({super.key, this.showSidebar = true});

  @override
  ConsumerState<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends ConsumerState<CoursePage>
    with SingleTickerProviderStateMixin {
  bool isDetailView = false;
  CourseModel? selectedCourse;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load courses when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courseProvider.notifier).loadCourses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void openCourse(CourseModel course) {
    setState(() {
      isDetailView = true;
      selectedCourse = course;
    });
  }

  void backToList() {
    setState(() {
      isDetailView = false;
      selectedCourse = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseState = ref.watch(courseProvider);
    final courses = courseState.filteredCourses.isNotEmpty 
        ? courseState.filteredCourses 
        : courseState.courses;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: widget.showSidebar
          ? AppBar(
        backgroundColor: AppColors.bgAppbar,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.indigo[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu_book, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('E-Learning',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          SizedBox(
            width: 280,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search courses, materials...',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: AppColors.bgInput,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none,
                  color: Colors.white)),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.indigo, Colors.purple]),
                      shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('Jara Khan'),
            ]),
          )
        ],
      ) : null,
      body: Row(
        children: [
          // Sidebar
          if (widget.showSidebar && MediaQuery.of(context).size.width > 800)
            SidebarWidget(),

          // Main Content
          Expanded(
            child: GestureDetector(
              onTap: () {}, // Ngăn chặn tap events lan truyền
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: isDetailView
                    ? CourseDetailView(
                        course: selectedCourse!,
                        tabController: _tabController,
                        onBack: backToList,
                      )
                    : Column(
                        children: [
                          CourseFilterWidget(),
                          Expanded(
                            child: CourseListView(
                              courses: courses,
                              onCourseSelect: openCourse,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedTileColor: Colors.indigo.withOpacity(0.3),
      leading: Icon(icon, color: selected ? Colors.indigo : Colors.grey[400]),
      title: Text(label,
          style: TextStyle(
              color: selected ? Colors.indigo[200] : Colors.grey[300],
              fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

class CourseListView extends StatelessWidget {
  final List<CourseModel> courses;
  final void Function(CourseModel) onCourseSelect;

  const CourseListView({
    super.key,
    required this.courses,
    required this.onCourseSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Không có khóa học nào',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Thử thay đổi bộ lọc để xem thêm khóa học',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: courses.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.25,
        ),
        itemBuilder: (context, i) => CourseCardWidget(
          course: courses[i],
          onTap: () => onCourseSelect(courses[i]),
        ),
      ),
    );
  }
}

class CourseDetailView extends StatelessWidget {
  final CourseModel course;
  final TabController tabController;
  final VoidCallback? onBack;

  const CourseDetailView({
    super.key,
    required this.course,
    required this.tabController,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CourseDetailHeader(course: course, onBack: onBack),
        Expanded(
          child: CourseTabsWidget(
            course: course,
            tabController: tabController,
          ),
        ),
      ],
    );
  }
}


