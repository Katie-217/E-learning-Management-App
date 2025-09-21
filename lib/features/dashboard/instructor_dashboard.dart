import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

class InstructorDashboard extends ConsumerWidget {
  const InstructorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          final isLargeScreen = constraints.maxWidth > 800;
          final isMediumScreen = constraints.maxWidth > 600 && constraints.maxWidth <= 800;
          final isSmallScreen = constraints.maxWidth <= 600;

          // Sidebar width
          final sidebarWidth = isLargeScreen ? 200.0 : (isMediumScreen ? 150.0 : 0.0);

          // GridView crossAxisCount
          final crossAxisCount = isLargeScreen ? 3 : (isMediumScreen ? 2 : 1);

          // AppBar with menu button for small screens
          final appBar = AppBar(
            title: const Text('Teacher Dashboard'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            actions: isSmallScreen
                ? [
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ]
                : null,
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
                              _buildStatCard(context, 'Total Students', '156', Icons.people, isSmallScreen),
                              _buildStatCard(context, 'Total Groups', '8', Icons.group, isSmallScreen),
                              _buildStatCard(context, 'Total Courses', '50', Icons.book, isSmallScreen),
                              _buildStatCard(context, 'Assignments', '23', Icons.assignment, isSmallScreen),
                              _buildStatCard(context, 'Quizzes', '15', Icons.quiz, isSmallScreen),
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: Icon(Icons.dashboard),
          title: Text('Dashboard'),
        ),
        ListTile(
          leading: Icon(Icons.people),
          title: Text('Students'),
        ),
        ListTile(
          leading: Icon(Icons.book),
          title: Text('Courses'),
        ),
        ListTile(
          leading: Icon(Icons.assignment),
          title: Text('Assignments'),
        ),
        ListTile(
          leading: Icon(Icons.grade),
          title: Text('Grades'),
        ),
        ListTile(
          leading: Icon(Icons.schedule),
          title: Text('Schedule'),
        ),
        ListTile(
          leading: Icon(Icons.settings),
          title: Text('Settings'),
        ),
        ListTile(
          leading: Icon(Icons.help),
          title: Text('Help'),
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
}

void main() {
  runApp(
    ProviderScope(
      child: MaterialApp(
        home: const InstructorDashboard(),
      ),
    ),
  );
}