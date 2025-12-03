import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/presentation/screens/instructor/manage_student/instructor_students_page.dart';
import 'package:elearning_management_app/application/controllers/instructor/instructor_profile_provider.dart';
import 'package:elearning_management_app/presentation/screens/instructor/instructor_courses/instructor_courses_page.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/semester_switcher.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/instructor_calendar_panel.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/instructor_progress_charts.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/assignment_tracking_table.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/quiz_results_table.dart';
import 'package:elearning_management_app/application/controllers/instructor/instructor_kpi_provider.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/kpi_cards.dart';
import 'package:elearning_management_app/presentation/widgets/common/user_menu_dropdown.dart';
import 'package:elearning_management_app/presentation/screens/admin/admin_cleanup_screen.dart';
import '../forum/instructor_forum_screen.dart';
class InstructorDashboard extends ConsumerStatefulWidget {
  const InstructorDashboard({super.key});

  @override
  ConsumerState<InstructorDashboard> createState() =>
      _InstructorDashboardState();
}

class _InstructorDashboardState extends ConsumerState<InstructorDashboard> {
  String _activeTab = 'dashboard';
  InstructorSemester? _selectedSemester;
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.indigo[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Teacher Dashboard',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          if (!isMobile)
            SizedBox(
              width: 250,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search courses...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFF111827),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  ),
                ),
              ),
            ),
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Consumer(
              builder: (context, ref, child) {
                final profileAsync = ref.watch(instructorProfileProvider);
                return profileAsync.when(
                  data: (profile) => UserMenuDropdown(
                    userName: profile?['name'] ??
                        profile?['displayName'] ??
                        'Dr. Johnson',
                    userEmail: profile?['email'] ?? 'dr.johnson@university.edu',
                    userPhotoUrl: profile?['photoUrl'],
                  ),
                  loading: () => const UserMenuDropdown(
                    userName: 'Dr. Johnson',
                    userEmail: 'dr.johnson@university.edu',
                    userPhotoUrl: null,
                  ),
                  error: (_, __) => const UserMenuDropdown(
                    userName: 'Dr. Johnson',
                    userEmail: 'dr.johnson@university.edu',
                    userPhotoUrl: null,
                  ),
                );
              },
            ),
          )
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          if (!isMobile)
            Container(
              width: 220,
              color: const Color(0xFF111827),
              child: _buildSidebar(),
            ),
          // Main Content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AdminCleanupScreen(),
            ),
          );
        },
        backgroundColor: Colors.red[700],
        icon: const Icon(Icons.cleaning_services, color: Colors.white),
        label: const Text('🧹 Cleanup', style: TextStyle(color: Colors.white)),
        tooltip: 'Admin: Clean up test users',
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_activeTab) {
      case 'courses':
        return const Padding(
          padding: EdgeInsets.all(18),
          child: InstructorCoursesPage(),
        );
      case 'students':
        return const Padding(
          padding: EdgeInsets.all(18),
          child: InstructorStudentsPage(),
        );
      case 'forum':
        return const Padding(
          padding: EdgeInsets.all(18),
          child: InstructorForumScreen(),
        );
      default: // dashboard
        final semesterName = _selectedSemester?.name ?? 'Fall 2024';
        final kpiStatsAsync =
            ref.watch(instructorKPIStatsProvider(semesterName));
        return SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome and Semester Switcher in same row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Welcome message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome back, Dr. Johnson',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text("Ready to inspire your students today?",
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right: Semester Switcher
                  InstructorSemesterSwitcher(
                    initialSemester: _selectedSemester,
                    onSemesterChanged: (semester) {
                      setState(() {
                        _selectedSemester = semester;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // KPI Cards - 5 cards bắt buộc
              kpiStatsAsync.when(
                data: (stats) => InstructorKPICards(stats: stats),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Unable to load KPI stats: $error',
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Two Column Layout
              LayoutBuilder(builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 900;
                return isWideScreen
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Charts + Assignment Tracking Table
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                // 2 Charts in a row
                                Row(
                                  children: [
                                    const Expanded(
                                      child: AssignmentSubmissionChart(),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: QuizCompletionChart(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Assignment Tracking Table
                                const SizedBox(
                                  height: 400,
                                  child: AssignmentTrackingTable(),
                                ),
                                const SizedBox(height: 12),
                                // Quiz Results Table
                                const SizedBox(
                                  height: 400,
                                  child: QuizResultsTable(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Right Column: Calendar Panel
                          Expanded(
                            flex: 1,
                            child: _buildCalendarTasksPanel(),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          // Charts in a row on mobile if space allows
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final canFitTwoCharts =
                                  constraints.maxWidth > 600;
                              return canFitTwoCharts
                                  ? Row(
                                      children: [
                                        const Expanded(
                                          child: AssignmentSubmissionChart(),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: QuizCompletionChart(),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        const AssignmentSubmissionChart(),
                                        const SizedBox(height: 12),
                                        const QuizCompletionChart(),
                                      ],
                                    );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildCalendarTasksPanel(),
                          const SizedBox(height: 12),
                          // Assignment Tracking Table
                          const SizedBox(
                            height: 400,
                            child: AssignmentTrackingTable(),
                          ),
                          const SizedBox(height: 12),
                          // Quiz Results Table
                          const SizedBox(
                            height: 400,
                            child: QuizResultsTable(),
                          ),
                        ],
                      );
              }),
            ],
          ),
        );
    }
  }

  Widget _buildSidebar() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        _buildSidebarItem(
          'Dashboard',
          Icons.dashboard,
          'dashboard',
        ),
        _buildSidebarItem(
          'Teaching',
          Icons.book,
          'courses',
        ),
        _buildSidebarItem(
          'Students',
          Icons.people,
          'students',
        ),
        _buildSidebarItem(
          'Forum',
          Icons.book,
          'forum',        
        ),
      ],
    );
  }

  Widget _buildSidebarItem(String label, IconData icon, String tabKey) {
    final isActive = _activeTab == tabKey;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.indigo[600]?.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border:
            isActive ? Border.all(color: Colors.indigo[600]!, width: 1) : null,
      ),
      child: ListTile(
        leading: Icon(icon,
            color: isActive ? Colors.indigo[400] : Colors.grey[400], size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[300],
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() => _activeTab = tabKey);
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      Color gradientStart, Color gradientEnd) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: Colors.white, size: 20),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarTasksPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: InstructorCalendarPanel(selectedSemester: _selectedSemester),
    );
  }
}
