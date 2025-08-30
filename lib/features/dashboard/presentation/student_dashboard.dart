import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/course.dart';
import '../../../core/providers/course_provider.dart';
import '../../../core/providers/semester_provider.dart';
import '../../../core/widgets/course_card.dart';
import '../../../core/widgets/semester_switcher.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/utils/responsive_helper.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courseProvider.notifier).loadCourses();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseState = ref.watch(courseProvider);
    final currentSemester = ref.watch(semesterProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
      drawer: ResponsiveHelper.isMobile(context) ? _buildDrawer() : null,
      body: ResponsiveHelper.isDesktop(context)
          ? _buildDesktopLayout(courseState, currentSemester)
          : _buildMobileLayout(courseState, currentSemester),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      title: Row(
        children: [
          if (!ResponsiveHelper.isMobile(context))
            Icon(Icons.school, size: 28),
          if (!ResponsiveHelper.isMobile(context))
            SizedBox(width: 12),
          Text(
            'Student Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.isMobile(context) ? 20 : 24,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showNotifications(),
          icon: Badge(
            label: Text('3'),
            child: Icon(Icons.notifications_outlined),
          ),
        ),
        SizedBox(width: 8),
        PopupMenuButton<String>(
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            PopupMenuItem(value: 'profile', child: Text('Hồ sơ')),
            PopupMenuItem(value: 'settings', child: Text('Cài đặt')),
            PopupMenuDivider(),
            PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
          ],
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text('S', style: TextStyle(color: Colors.white)),
          ),
        ),
        SizedBox(width: 16),
      ],
    );
  }

  Widget _buildDesktopLayout(CourseState courseState, String currentSemester) {
    return Row(
      children: [
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: _buildSidebar(),
        ),
        Expanded(
          child: _buildMainContent(courseState, currentSemester),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(CourseState courseState, String currentSemester) {
    return _buildMainContent(courseState, currentSemester);
  }

  Widget _buildSidebar() {
    return Column(
      children: [
        SizedBox(height: 24),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text('ST', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nguyễn Văn Student',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                      'student@university.edu',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 8),
            children: [
              _buildSidebarItem(Icons.dashboard, 'Dashboard', true),
              _buildSidebarItem(Icons.book, 'Courses', false),
              _buildSidebarItem(Icons.assignment, 'Assignments', false),
              _buildSidebarItem(Icons.grade, 'Grades', false),
              _buildSidebarItem(Icons.calendar_today, 'Schedule', false),
              Divider(height: 32),
              _buildSidebarItem(Icons.settings, 'Settings', false),
              _buildSidebarItem(Icons.help, 'Help', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, bool isActive) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        title: Text(title,
            style: TextStyle(
              color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            )),
        selected: isActive,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {},
      ),
    );
  }

  Widget _buildDrawer() => Drawer(child: _buildSidebar());

  Widget _buildMainContent(CourseState courseState, String currentSemester) {
    return RefreshIndicator(
      onRefresh: () async => await ref.read(courseProvider.notifier).refreshCourses(),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(ResponsiveHelper.getHorizontalPadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  _buildWelcomeSection(),
                  SizedBox(height: 24),
                  SemesterSwitcher(),
                  SizedBox(height: 24),
                  _buildStatsCards(),
                  SizedBox(height: 24),
                  _buildSectionHeader('My Courses', courseState.courses.length),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getHorizontalPadding(context)),
            sliver: _buildCoursesGrid(courseState),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, Student!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ready to continue your learning journey?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.school,
            size: 48,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Active Courses', '6', Icons.book, Colors.blue)),
        SizedBox(width: 16),
        Expanded(child: _buildStatCard('Assignments', '12', Icons.assignment, Colors.orange)),
        SizedBox(width: 16),
        Expanded(child: _buildStatCard('Completed', '8', Icons.check_circle, Colors.green)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesGrid(CourseState courseState) {
    if (courseState.isLoading) {
      return _buildLoadingGrid();
    }

    if (courseState.error != null) {
      return _buildErrorWidget(courseState.error!);
    }

    if (courseState.courses.isEmpty) {
      return _buildEmptyWidget();
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
        childAspectRatio: ResponsiveHelper.isMobile(context) ? 0.8 : 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final course = courseState.courses[index];
          return CourseCard(
            course: course,
            onTap: () => _openCourseDetail(course),
          );
        },
        childCount: courseState.courses.length,
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
        childAspectRatio: ResponsiveHelper.isMobile(context) ? 0.8 : 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => SkeletonLoader(),
        childCount: 6,
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(courseProvider.notifier).refreshCourses(),
              child: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No courses found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You haven\'t enrolled in any courses yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notifications'),
        content: Text('You have 3 new notifications'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'profile':
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening profile...')));
        break;
      case 'settings':
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening settings...')));
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logged out successfully')));
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _openCourseDetail(Course course) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening ${course.name}...')));
  }
}
