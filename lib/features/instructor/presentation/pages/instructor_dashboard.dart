import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../providers/instructor_profile_provider.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/task_list_widget.dart';

class InstructorDashboard extends ConsumerWidget {
  const InstructorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(instructorProfileProvider);
    return Theme(
      data: ThemeData(
        primaryColor: Colors.blue[800],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue[800],
          secondary: Colors.teal[300],
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          bodySmall: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine screen size
          final isLargeScreen = constraints.maxWidth > 1200;
          final isMediumScreen = constraints.maxWidth > 800 && constraints.maxWidth <= 1200;
          final isSmallScreen = constraints.maxWidth <= 800;

          // Sidebar width
          final sidebarWidth = isLargeScreen ? 200.0 : (isMediumScreen ? 150.0 : 0.0);

          // Calendar/Tasks panel width (only show on large screens)
          final calendarPanelWidth = isLargeScreen ? 400.0 : 0.0;

          // GridView crossAxisCount
          final crossAxisCount = isLargeScreen ? 3 : (isMediumScreen ? 2 : 1);

          // AppBar with menu button for small screens
          final appBar = AppBar(
            title: const Text('Teacher Dashboard'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildProfileButton(context, profileAsync),
              ),
              if (isSmallScreen)
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
            ],
          );

          return Scaffold(
            appBar: appBar,
            drawer: isSmallScreen
                ? Drawer(
                    child: _buildSidebar(context),
                  )
                : null,
            body: Row(
              children: [
                // Sidebar for medium and large screens
                if (!isSmallScreen)
                  Container(
                    width: sidebarWidth,
                    color: Colors.blue[50],
                    child: _buildSidebar(context),
                  ),
                // Main Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome Banner
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[800]!, Colors.blue[400]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back, Dr. Johnson!',
                                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                              fontSize: isSmallScreen ? 20 : 24,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Ready to inspire and educate your students?',
                                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                              fontSize: isSmallScreen ? 14 : 16,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.school, size: isSmallScreen ? 32 : 40, color: Colors.white),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Stats Section
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              _buildStatCard(context, 'Students', '156', Icons.people, isSmallScreen),
                              _buildStatCard(context, 'Groups', '8', Icons.group, isSmallScreen),
                              _buildStatCard(context, 'Courses', '50', Icons.book, isSmallScreen),
                              _buildStatCard(context, 'New Assignments', '23', Icons.assignment, isSmallScreen),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Progress Charts Section
                          const Text(
                            'Progress Overview',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: isSmallScreen ? 400 : 200, // Stack charts vertically on small screens
                            child: isSmallScreen
                                ? Column(
                                    children: [
                                      Expanded(
                                        child: _buildPieChart(
                                          context,
                                          'Assignment Completion',
                                          [
                                            PieChartSectionData(
                                              value: 75,
                                              color: Colors.blue[600],
                                              title: '75%',
                                              radius: isSmallScreen ? 40 : 50,
                                              titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                            PieChartSectionData(
                                              value: 25,
                                              color: Colors.grey[400],
                                              title: '25%',
                                              radius: isSmallScreen ? 40 : 50,
                                              titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildPieChart(
                                          context,
                                          'Quiz Completion',
                                          [
                                            PieChartSectionData(
                                              value: 60,
                                              color: Colors.teal[300],
                                              title: '60%',
                                              radius: isSmallScreen ? 40 : 50,
                                              titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                            PieChartSectionData(
                                              value: 40,
                                              color: Colors.grey[400],
                                              title: '40%',
                                              radius: isSmallScreen ? 40 : 50,
                                              titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: _buildPieChart(
                                          context,
                                          'Assignment Completion',
                                          [
                                            PieChartSectionData(
                                              value: 75,
                                              color: Colors.blue[600],
                                              title: '75%',
                                              radius: 50,
                                              titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                            PieChartSectionData(
                                              value: 25,
                                              color: Colors.grey[400],
                                              title: '25%',
                                              radius: 50,
                                              titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildPieChart(
                                          context,
                                          'Quiz Completion',
                                          [
                                            PieChartSectionData(
                                              value: 60,
                                              color: Colors.teal[300],
                                              title: '60%',
                                              radius: 50,
                                              titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                            PieChartSectionData(
                                              value: 40,
                                              color: Colors.grey[400],
                                              title: '40%',
                                              radius: 50,
                                              titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 16),
                          // My Courses Section
                          const Text(
                            'My Courses',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: isSmallScreen ? 600 : 300,
                            child: GridView.count(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: isSmallScreen ? 2.0 : 1.8,
                              children: [
                                _buildCourseCard('CS450', 'Advanced Web Development', 45, Colors.blue[600]!, 'Fall 2024', isSmallScreen),
                                _buildCourseCard('CS380', 'Database Systems', 38, Colors.green[600]!, 'Fall 2024', isSmallScreen),
                                _buildCourseCard('CS420', 'Software Engineering', 32, Colors.purple[600]!, 'Fall 2024', isSmallScreen),
                                _buildCourseCard('CS300', 'Data Structures', 31, Colors.orange[600]!, 'Summer 2024', isSmallScreen, inactive: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Calendar and Tasks Panel (Right Side - Only on large screens)
                if (calendarPanelWidth > 0)
                  Container(
                    width: calendarPanelWidth,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        left: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: const SingleChildScrollView(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CalendarWidget(),
                          SizedBox(height: 24),
                          TaskListWidget(),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          leading: const Icon(Icons.dashboard),
          title: const Text('Dashboard'),
          onTap: () => context.go('/dashboard'),
        ),
        ListTile(
          leading: const Icon(Icons.people),
          title: const Text('Students'),
          onTap: () => context.go('/instructor/students'),
        ),
        ListTile(
          leading: const Icon(Icons.book),
          title: const Text('Courses'),
          onTap: () => context.go('/instructor/courses'),
        ),
        ListTile(
          leading: const Icon(Icons.assignment),
          title: const Text('Assignments'),
          onTap: () => context.go('/instructor/assignments'),
        ),
        ListTile(
          leading: const Icon(Icons.grade),
          title: const Text('Grades'),
          onTap: () {
            print('DEBUG: Navigating to /instructor/grades');
            context.go('/instructor/grades');
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, bool isSmallScreen) {
    return Card(
      elevation: 4,
      color: Colors.white,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? double.infinity : MediaQuery.of(context).size.width / 4 - 12,
        ),
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              icon,
              color: Colors.blue[200],
              size: isSmallScreen ? 24 : 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(String code, String title, int students, Color color, String semester, bool isSmallScreen, {bool inactive = false}) {
    return Card(
      elevation: 3,
      color: inactive ? Colors.grey[600]! : color,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 6.0 : 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.more_vert, color: Colors.white, size: isSmallScreen ? 14 : 16),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Students: $students',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  color: Colors.white70,
                ),
              ),
              Text(
                semester,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: inactive ? null : () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8, vertical: isSmallScreen ? 3 : 4),
                      minimumSize: Size(isSmallScreen ? 50 : 60, isSmallScreen ? 20 : 24),
                    ),
                    child: Text('Manage', style: TextStyle(fontSize: isSmallScreen ? 10 : 12)),
                  ),
                  TextButton(
                    onPressed: inactive ? null : () {},
                    child: Text(
                      'Details',
                      style: TextStyle(fontSize: isSmallScreen ? 10 : 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, String title, List<PieChartSectionData> sections) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 20,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context,
      AsyncValue<Map<String, dynamic>?> profileAsync) {
    return profileAsync.when(
      loading: () => const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      ),
      error: (_, __) => _ProfileAvatar(
        initials: 'T',
        onTap: () => _showProfileSheet(context, null),
      ),
      data: (data) {
        final initials = _extractInitials(data?['name'] ?? '');
        final photoUrl = data?['photoUrl'] as String?;
        return _ProfileAvatar(
          initials: initials,
          photoUrl: photoUrl,
          onTap: () => _showProfileSheet(context, data),
        );
      },
    );
  }

  String _extractInitials(String name) {
    if (name.isEmpty) return 'T';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  void _showProfileSheet(
      BuildContext context, Map<String, dynamic>? profileData) {
    final name = profileData?['name'] as String? ?? 'Teacher';
    final email = profileData?['email'] as String? ?? 'No email';
    final role = profileData?['role'] as String? ?? 'teacher';
    final photoUrl = profileData?['photoUrl'] as String?;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: _ProfileAvatar(
                  initials: _extractInitials(name),
                  photoUrl: photoUrl,
                  size: 72,
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.black87),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  email,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 16),
              _ProfileInfoRow(
                icon: Icons.badge_outlined,
                label: 'Role',
                value: role.toUpperCase(),
              ),
              if (profileData?['settings'] is Map<String, dynamic>) ...[
                const SizedBox(height: 12),
                _ProfileInfoRow(
                  icon: Icons.language,
                  label: 'Language',
                  value:
                      profileData!['settings']['language']?.toString() ?? '--',
                ),
                const SizedBox(height: 12),
                _ProfileInfoRow(
                  icon: Icons.brightness_6_outlined,
                  label: 'Theme',
                  value: profileData['settings']['theme']?.toString() ?? '--',
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/profile');
                      },
                      icon: const Icon(Icons.person),
                      label: const Text('View Profile'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.initials,
    required this.onTap,
    this.photoUrl,
    this.size = 40,
  });

  final String initials;
  final VoidCallback onTap;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
          ? NetworkImage(photoUrl!)
          : null,
      backgroundColor: Colors.white24,
      child: (photoUrl == null || photoUrl!.isEmpty)
          ? Text(
              initials,
              style: TextStyle(
                fontSize: size / 2.3,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : null,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(size),
      onTap: onTap,
      child: avatar,
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}