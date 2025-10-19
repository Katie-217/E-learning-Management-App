import 'package:flutter/material.dart';
import '../../../../data/models/course_model.dart';
import '../widgets/course_card_widget.dart';
import '../widgets/course_detail.dart';
import '../widgets/course_tabs_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/sidebar_model.dart';

class CoursePage extends StatefulWidget {
  final bool showSidebar;
  const CoursePage({super.key, this.showSidebar = true});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage>
    with SingleTickerProviderStateMixin {
  bool isDetailView = false;
  CourseModel? selectedCourse;
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

  void openCourse(CourseModel course) {
    setState(() {
      isDetailView = true;
      selectedCourse = course;
    });
  }

  // void backToList() {
  //   setState(() {
  //     isDetailView = false;
  //     selectedCourse = null;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final courses = CourseModel.mockCourses;

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
            const SidebarWidget(),

          // Main Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: isDetailView
                  ? CourseDetailView(
                      course: selectedCourse!,
                      tabController: _tabController,)
                  : CourseListView(
                      courses: courses,
                      onCourseSelect: openCourse,
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

  const CourseDetailView({
    super.key,
    required this.course,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CourseDetailHeader(course: course),
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
