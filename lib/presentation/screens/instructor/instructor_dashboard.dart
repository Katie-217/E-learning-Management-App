import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:elearning_management_app/presentation/screens/course/course_page.dart';
import 'package:elearning_management_app/presentation/screens/instructor/instructor_students_page.dart';
import 'package:elearning_management_app/presentation/screens/assignment/assignments_page.dart';
import 'package:elearning_management_app/application/controllers/instructor/instructor_profile_provider.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/calendar_widget.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/task_list_widget.dart';
import 'package:elearning_management_app/presentation/screens/instructor/instructor_courses/instructor_courses_page.dart';
import '../../widgets/instructor/sidebar_widget.dart';
import 'csv_import_screen.dart';
import 'instructor_student_create.dart';
import 'instructor_courses/instructor_course_create.dart';

// Typedef cho callback import
typedef ImportCompleteCallback = void Function(bool success, String message);

class InstructorDashboard extends ConsumerStatefulWidget {
  const InstructorDashboard({super.key});

  @override
  ConsumerState<InstructorDashboard> createState() =>
      _InstructorDashboardState();
}

class _InstructorDashboardState extends ConsumerState<InstructorDashboard> {
  String _activeTab = 'dashboard';
  
  // Trạng thái để quản lý các view trong Students tab
  bool _isCreatingStudent = false;
  bool _isImportingCSV = false;
  
  // 🆕 Trạng thái để quản lý các view trong Courses tab
  bool _isCreatingCourse = false;

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
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient:
                        LinearGradient(colors: [Colors.indigo, Colors.purple]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  const Text('Dr. Johnson'),
                ]
              ],
            ),
          )
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          if (!isMobile)
            SidebarWidget(
              activeTab: _activeTab,
              onTabSelected: (tab) {
                setState(() {
                  _activeTab = tab;
                  // Reset các trạng thái khi đổi tab
                  _isCreatingStudent = false;
                  _isImportingCSV = false;
                  _isCreatingCourse = false;
                });
              },
            ),
          // Main Content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_activeTab) {
      case 'courses':
        // 🆕 LOGIC MỚI: Kiểm tra trạng thái để hiển thị đúng màn hình
        return Padding(
          padding: const EdgeInsets.all(18),
          child: _isCreatingCourse
              ? _buildCreateCourseView() // Hiển thị form tạo course
              : _buildCoursesListView(), // Hiển thị danh sách courses
        );
      case 'students':
        return Padding(
          padding: const EdgeInsets.all(18),
          child: _isImportingCSV
              ? _buildImportCSVView()
              : _isCreatingStudent
                  ? _buildCreateStudentView()
                  : _buildStudentsListView(),
        );
      default: // dashboard
        return SingleChildScrollView(
          padding: const EdgeInsets.all(18),
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
                  style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              const SizedBox(height: 20),
              // Stats Grid
              LayoutBuilder(builder: (context, cons) {
                final cross =
                    cons.maxWidth > 900 ? 4 : (cons.maxWidth > 600 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: cross,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard('Students', '156', Icons.people, Colors.blue,
                        Colors.blueAccent),
                    _buildStatCard('Active Courses', '5', Icons.book,
                        Colors.green, Colors.greenAccent),
                    _buildStatCard('Pending Assignments', '23',
                        Icons.assignment, Colors.orange, Colors.orangeAccent),
                    _buildStatCard('Avg. Class Score', '85%', Icons.trending_up,
                        Colors.purple, Colors.purpleAccent),
                  ],
                );
              }),
              const SizedBox(height: 20),
              // Two Column Layout
              LayoutBuilder(builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 900;
                return isWideScreen
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildProgressOverview(),
                                const SizedBox(height: 12),
                                _buildMyCoursesSection(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                _buildCalendarSection(),
                                const SizedBox(height: 12),
                                _buildUpcomingTasksSection(),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildProgressOverview(),
                          const SizedBox(height: 12),
                          _buildMyCoursesSection(),
                          const SizedBox(height: 12),
                          _buildCalendarSection(),
                          const SizedBox(height: 12),
                          _buildUpcomingTasksSection(),
                        ],
                      );
              }),
            ],
          ),
        );
    }
  }

  // 🆕 HÀM MỚI: Xây dựng view danh sách courses
  Widget _buildCoursesListView() {
    return InstructorCoursesPage(
      onCreateCoursePressed: () {
        // 🔥 KHI NHẤN NÚT CREATE COURSE
        setState(() {
          _isCreatingCourse = true;
        });
      },
    );
  }

  // 🆕 HÀM MỚI: Xây dựng view tạo course
  Widget _buildCreateCourseView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header với nút Back
        Row(
          children: [
            // Nút quay lại
            IconButton(
              onPressed: () {
                // 🔥 QUAY LẠI DANH SÁCH COURSES
                setState(() {
                  _isCreatingCourse = false;
                });
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: 'Back to Courses List',
            ),
            const SizedBox(width: 12),
            const Text(
              'Create New Course',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Add a new course to your teaching schedule',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
        const SizedBox(height: 24),
        // Form tạo course
        Expanded(
          child: CreateCoursePage(
            onSuccess: () {
              // Callback khi tạo thành công
              setState(() {
                _isCreatingCourse = false;
              });
            },
            onCancel: () {
              // Callback khi hủy
              setState(() {
                _isCreatingCourse = false;
              });
            },
          ),
        ),
      ],
    );
  }

  // HÀM: Xây dựng view danh sách students
  Widget _buildStudentsListView() {
    return InstructorStudentsPage(
      onCreateStudentPressed: () {
        setState(() {
          _isCreatingStudent = true;
        });
      },
      onImportCSVPressed: () {
        setState(() {
          _isImportingCSV = true;
        });
      },
    );
  }

  // HÀM: Xây dựng view tạo student
  Widget _buildCreateStudentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isCreatingStudent = false;
                });
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: 'Back to Students List',
            ),
            const SizedBox(width: 12),
            const Text(
              'Create New Student',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Add a new student to the system',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: CreateStudentPage(
            onSuccess: () {
              setState(() {
                _isCreatingStudent = false;
              });
            },
            onCancel: () {
              setState(() {
                _isCreatingStudent = false;
              });
            },
          ),
        ),
      ],
    );
  }

  // HÀM: Xây dựng view import CSV
  Widget _buildImportCSVView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isImportingCSV = false;
                });
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: 'Back to Students List',
            ),
            const SizedBox(width: 12),
            const Text(
              'Import Students from CSV',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Bulk import students using CSV file',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: CsvImportScreen(
            dataType: 'students',
            onImportComplete: (bool success, String message) {
              setState(() {
                _isImportingCSV = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: success ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            onCancel: () {
              setState(() {
                _isImportingCSV = false;
              });
            },
          ),
        ),
      ],
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

  Widget _buildProgressOverview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgressItem(
                  'Assignments Graded',
                  '156',
                  '180',
                  0.87,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressItem(
                  'Quiz Completion',
                  '142',
                  '156',
                  0.91,
                  Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String current, String total,
      double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$current / $total',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMyCoursesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Courses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildCourseCard(
              'CS450', 'Advanced Web Development', 45, Colors.blue),
          const SizedBox(height: 8),
          _buildCourseCard('CS380', 'Database Systems', 38, Colors.green),
          const SizedBox(height: 8),
          _buildCourseCard('CS420', 'Software Engineering', 32, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildCourseCard(
      String code, String title, int students, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$students students',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Manage', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'February 2025',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              28,
              (index) => Container(
                decoration: BoxDecoration(
                  color: index == 14 ? Colors.indigo[600] : Colors.grey[800],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTasksSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Tasks',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildTaskItem('Grade Assignment #5', 'CS450', Colors.blue, true),
          const SizedBox(height: 8),
          _buildTaskItem('Prepare Lecture Notes', 'CS380', Colors.green, false),
          const SizedBox(height: 8),
          _buildTaskItem(
              'Review Student Submissions', 'CS420', Colors.purple, false),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
      String title, String course, Color color, bool isUrgent) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUrgent ? color : color.withOpacity(0.2),
          width: isUrgent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  course,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          if (isUrgent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Urgent',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}