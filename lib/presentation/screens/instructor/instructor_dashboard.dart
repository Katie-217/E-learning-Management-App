import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/presentation/screens/instructor/manage_student/instructor_students_page.dart';
import 'package:elearning_management_app/application/controllers/instructor/instructor_profile_provider.dart';
import 'package:elearning_management_app/presentation/screens/instructor/instructor_courses/instructor_courses_page.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/semester_switcher.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/instructor_calendar_panel.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/instructor_progress_charts.dart';
import 'package:elearning_management_app/application/controllers/instructor/instructor_kpi_provider.dart';
import 'package:elearning_management_app/presentation/widgets/instructor/kpi_cards.dart';
import 'package:elearning_management_app/presentation/widgets/common/user_menu_dropdown.dart';
import 'package:elearning_management_app/presentation/screens/admin/admin_cleanup_screen.dart';
import 'package:elearning_management_app/data/repositories/semester/semester_repository.dart';
import 'package:elearning_management_app/application/controllers/course/course_instructor_provider.dart';
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
  List<InstructorSemester> _semesters = [];
  bool _isSemestersLoading = true;
  String _userName = 'User';
  String _userEmail = '';
  
  int _getBottomNavIndex() {
    switch (_activeTab) {
      case 'dashboard':
        return 0;
      case 'courses':
        return 1;
      case 'students':
        return 2;
      case 'forum':
        return 3;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    // Load user info
    _loadUserInfo();
    // Không cần preload ở đây vì đã được preload trong RoleBasedDashboard
    // Chỉ cần load semesters để hiển thị dropdown
    _loadSemesters();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          final data = doc.data()!;
          setState(() {
            // Ưu tiên: name -> displayName -> Firebase Auth displayName -> email (username part) -> 'User'
            _userName = data['name'] ?? 
                       data['displayName'] ?? 
                       user.displayName ?? 
                       (user.email?.split('@')[0] ?? 'User');
            _userEmail = data['email'] ?? user.email ?? '';
          });
          print('DEBUG: Loaded user name: $_userName, email: $_userEmail');
        } else if (mounted) {
          // Fallback to Firebase Auth data
          setState(() {
            _userName = user.displayName ?? 
                       (user.email?.split('@')[0] ?? 'User');
            _userEmail = user.email ?? '';
          });
          print('DEBUG: Using Firebase Auth - name: $_userName, email: $_userEmail');
        }
      }
    } catch (e) {
      print('Error loading user info: $e');
      // Continue with default values
    }
  }

  Future<void> _loadSemesters() async {
    try {
      setState(() => _isSemestersLoading = true);
      // Gọi trực tiếp repository để lấy semesters thật
      final semesterRepo = SemesterRepository();
      final semesters = await semesterRepo.getAllSemesters();
      
      if (mounted) {
        setState(() {
          _semesters = semesters.map((semester) {
            return InstructorSemester(
              id: semester.id,
              code: semester.code ?? semester.name,
              name: semester.name,
              startDate: semester.startDate,
            );
          }).toList();
          
          // Sắp xếp: mới nhất trước
          _semesters.sort((a, b) => b.startDate.compareTo(a.startDate));
          
          _isSemestersLoading = false;
          
          // Chọn học kì hiện tại nếu chưa có semester được chọn
          if (_selectedSemester == null && _semesters.isNotEmpty) {
            // Tìm học kì hiện tại (dựa vào startDate và endDate)
            InstructorSemester? currentSemester;
            
            // Tìm semester có isCurrentSemester = true
            for (final semester in semesters) {
              if (semester.isCurrentSemester) {
                // Tìm InstructorSemester tương ứng
                currentSemester = _semesters.firstWhere(
                  (s) => s.id == semester.id,
                  orElse: () => _semesters.first,
                );
                print('DEBUG: ✅ Found current semester: ${currentSemester.name}');
                break;
              }
            }
            
            // Nếu không tìm thấy học kì hiện tại, dùng semester đầu tiên (mới nhất)
            _selectedSemester = currentSemester ?? _semesters.first;
            
            if (currentSemester == null) {
              print('DEBUG: ⚠️ No current semester found, using first semester: ${_selectedSemester?.name}');
            }
            
            // Không cần preload vì data đã được preload cho tất cả semesters trong RoleBasedDashboard
            // Chỉ cần trigger rebuild để UI cập nhật
          }
        });
      }
    } catch (e) {
      print('DEBUG: ❌ Error loading semesters: $e');
      if (mounted) {
        setState(() {
          _isSemestersLoading = false;
          _semesters = [];
        });
        // Không cần preload vì data đã được preload trong RoleBasedDashboard
      }
    }
  }


  // Preload tất cả dữ liệu cần thiết cho dashboard
  // Preload với semester cụ thể (có thể gọi trước khi _selectedSemester được set)
  Future<void> _preloadDashboardDataWithSemester(String semesterName) async {
    if (!mounted) return;
    
    final now = DateTime.now();
    final monthKey = DateTime(now.year, now.month);
    
    print('DEBUG: 🔄 Preloading dashboard data for semester: $semesterName');
    
    // Preload tất cả dữ liệu song song, không await để không block UI
    // Riverpod sẽ cache data, nên khi UI watch providers, data đã có sẵn
    Future.wait([
      // Preload KPI stats (quan trọng nhất, load trước)
      ref.read(instructorKPIStatsProvider(semesterName).future),
      
      // Preload assignment submission stats
      ref.read(instructorAssignmentSubmissionStatsProvider(semesterName).future),
      
      // Preload quiz completion stats
      ref.read(instructorQuizCompletionStatsProvider(semesterName).future),
      
      // Preload tasks for current month (với semester)
      ref.read(instructorTasksForMonthProvider(
        InstructorTaskMonthKey(monthKey, semesterName)
      ).future),
      
      // Preload tasks for today (với semester)
      ref.read(instructorTasksForDateProvider(
        InstructorTaskKey(now, semesterName)
      ).future),
    ]).then((_) {
      if (mounted) {
        print('DEBUG: ✅ Preloading dashboard data completed for semester: $semesterName');
        // Trigger rebuild để UI cập nhật
        setState(() {});
      }
    }).catchError((e) {
      print('DEBUG: ⚠️ Error preloading dashboard data: $e');
      // Không throw error, để UI vẫn có thể hiển thị với loading state
    });
  }
  
  Future<void> _preloadDashboardData() async {
    final semesterName = _selectedSemester?.name ?? 'All';
    await _preloadDashboardDataWithSemester(semesterName);
  }
  
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final showBottomNav = !kIsWeb && !isWide; // chỉ dùng bottom nav cho mobile/app, tránh cho web
    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isVerySmall = screenWidth < 400;
            final iconSize = isVerySmall ? 28.0 : 32.0; // Giảm từ 32/40 xuống 28/32
            final titleSize = isVerySmall ? 13.0 : 15.0; // Giảm từ 14/16 xuống 13/15
            final spacing = isVerySmall ? 4.0 : 6.0;
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isWide)
                  PopupMenuButton<String>(
                    offset: const Offset(0, kToolbarHeight),
                    icon: Icon(Icons.menu, color: Colors.white, size: isVerySmall ? 20.0 : 24.0),
                    padding: EdgeInsets.all(isVerySmall ? 4.0 : 8.0),
                    constraints: BoxConstraints(
                      minWidth: isVerySmall ? 32.0 : 48.0,
                      minHeight: isVerySmall ? 32.0 : 48.0,
                    ),
                    color: const Color(0xFF1F2937),
                    onSelected: (value) {
                      setState(() {
                        _activeTab = value;
                      });
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'dashboard',
                        child: ListTile(
                          leading: Icon(Icons.dashboard_outlined, color: Colors.white70),
                          title: Text('Dashboard', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'courses',
                        child: ListTile(
                          leading: Icon(Icons.book_outlined, color: Colors.white70),
                          title: Text('Teaching', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'students',
                        child: ListTile(
                          leading: Icon(Icons.people_outlined, color: Colors.white70),
                          title: Text('Students', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'forum',
                        child: ListTile(
                          leading: Icon(Icons.forum_outlined, color: Colors.white70),
                          title: Text('Forum', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                SizedBox(width: spacing),
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: Colors.indigo[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.school, color: Colors.white, size: iconSize * 0.6),
                ),
                SizedBox(width: spacing + 2),
                Flexible(
                  child: Text(
                    isVerySmall ? 'Teacher' : 'Teacher Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: titleSize,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          // Đã bỏ _InstructorResponsiveSearchField()
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isVerySmall = screenWidth < 400;
              
              return IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.notifications_none,
                  size: isVerySmall ? 20.0 : 24.0,
                ),
                padding: EdgeInsets.all(isVerySmall ? 4.0 : 8.0),
                constraints: BoxConstraints(
                  minWidth: isVerySmall ? 32.0 : 48.0,
                  minHeight: isVerySmall ? 32.0 : 48.0,
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isVerySmall = screenWidth < 400;
                
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isVerySmall ? 120.0 : 180.0,
                  ),
                  child: UserMenuDropdown(
                    userName: _userName,
                    userEmail: _userEmail,
                    userPhotoUrl: null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          if (isWide)
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
      // Khi màn hình hẹp, hiển thị bottom navigation để đổi tab
      bottomNavigationBar: showBottomNav
          ? BottomNavigationBar(
              backgroundColor: const Color(0xFF1F2937),
              selectedItemColor: Colors.indigo[400],
              unselectedItemColor: Colors.grey[400],
              currentIndex: _getBottomNavIndex(),
              onTap: (index) {
                setState(() {
                  switch (index) {
                    case 0:
                      _activeTab = 'dashboard';
                      break;
                    case 1:
                      _activeTab = 'courses';
                      break;
                    case 2:
                      _activeTab = 'students';
                      break;
                    case 3:
                      _activeTab = 'forum';
                      break;
                  }
                });
              },
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book),
                  label: 'Teaching',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Students',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.forum),
                  label: 'Forum',
                ),
              ],
            )
          : null,
      floatingActionButton: isWide
          ? FloatingActionButton.extended(
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
            )
          : FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminCleanupScreen(),
                  ),
                );
              },
              backgroundColor: Colors.red[700],
              child: const Icon(Icons.cleaning_services, color: Colors.white),
              tooltip: 'Admin: Clean up test users',
            ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final padding = screenWidth > 800
            ? 18.0
            : screenWidth > 600
                ? 16.0
                : 12.0;
        
        switch (_activeTab) {
          case 'courses':
            return Padding(
              padding: EdgeInsets.all(padding),
              child: const InstructorCoursesPage(),
            );
          case 'students':
            return Padding(
              padding: EdgeInsets.all(padding),
              child: const InstructorStudentsPage(),
            );
          case 'forum':
            return Padding(
              padding: EdgeInsets.all(padding),
              child: const InstructorForumScreen(),
            );
          default: // dashboard
            final semesterName = _selectedSemester?.name ?? 'All';
            final kpiStatsAsync =
                ref.watch(instructorKPIStatsProvider(semesterName));
            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome and Semester Switcher in same row
                  LayoutBuilder(
                    builder: (context, headerConstraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isNarrow = headerConstraints.maxWidth < 600;
                      return isNarrow
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Welcome message
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back, $_userName',
                                      style: TextStyle(
                                        fontSize: screenWidth > 600 ? 28 : 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: screenWidth > 600 ? 4 : 3),
                                    Text(
                                      "Ready to inspire your students today?",
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: screenWidth > 600 ? 16 : 14,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenWidth > 600 ? 16 : 12),
                                // Semester Switcher
                                _isSemestersLoading
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : Align(
                                        alignment: Alignment.centerLeft,
                                        child: InstructorSemesterSwitcher(
                                          semesters: _semesters,
                                          initialSemester: _selectedSemester,
                                          onSemesterChanged: (semester) {
                                            setState(() {
                                              _selectedSemester = semester;
                                            });
                                            // Không cần preload lại vì data đã được preload cho tất cả semesters
                                            // Chỉ cần trigger rebuild để UI cập nhật với data từ cache
                                          },
                                        ),
                                      ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Left: Welcome message
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back, $_userName',
                                        style: TextStyle(
                                          fontSize: screenWidth > 800 ? 28 : 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      SizedBox(height: screenWidth > 600 ? 4 : 3),
                                      Text(
                                        "Ready to inspire your students today?",
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: screenWidth > 600 ? 16 : 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: screenWidth > 800 ? 16 : 12),
                                // Right: Semester Switcher
                                _isSemestersLoading
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : Flexible(
                                        child: InstructorSemesterSwitcher(
                                          semesters: _semesters,
                                          initialSemester: _selectedSemester,
                                          onSemesterChanged: (semester) {
                                            setState(() {
                                              _selectedSemester = semester;
                                            });
                                            // Không cần preload lại vì data đã được preload cho tất cả semesters
                                            // Chỉ cần trigger rebuild để UI cập nhật với data từ cache
                                          },
                                        ),
                                      ),
                              ],
                            );
                    },
                  ),
                  SizedBox(height: screenWidth > 600 ? 20 : 16),
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
              SizedBox(height: screenWidth > 600 ? 20 : 16),
              // Charts and Calendar Layout
              LayoutBuilder(builder: (context, constraints) {
                final spacing = screenWidth > 600 ? 12.0 : 8.0;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 2 Charts in a row
                    LayoutBuilder(
                      builder: (context, chartConstraints) {
                        final canFitTwoCharts =
                            chartConstraints.maxWidth > 600;
                        return canFitTwoCharts
                            ? Row(
                                children: [
                                  Expanded(
                                    child: AssignmentSubmissionChart(
                                      selectedSemester: _selectedSemester,
                                    ),
                                  ),
                                  SizedBox(width: spacing),
                                  Expanded(
                                    child: QuizCompletionChart(
                                      selectedSemester: _selectedSemester,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AssignmentSubmissionChart(
                                    selectedSemester: _selectedSemester,
                                  ),
                                  SizedBox(height: spacing),
                                  QuizCompletionChart(
                                    selectedSemester: _selectedSemester,
                                  ),
                                ],
                              );
                      },
                    ),
                    SizedBox(height: spacing),
                    // Calendar Panel below charts
                    _buildCalendarTasksPanel(),
                  ],
                );
              }),
            ],
          ),
        );
        }
      },
    );
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

// Responsive search field to prevent overflow in app bar
class _InstructorResponsiveSearchField extends StatelessWidget {
  const _InstructorResponsiveSearchField();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Reduce width on small screens and hide on very small screens
    final searchWidth = screenWidth > 1200
        ? 280.0
        : screenWidth > 900
            ? 220.0
            : screenWidth > 750
                ? 180.0
                : screenWidth > 600
                    ? 150.0
                    : screenWidth > 480
                        ? 120.0
                        : screenWidth > 400
                            ? 100.0
                            : 0.0; // Ẩn hoàn toàn khi màn hình < 400px

    if (searchWidth == 0) return const SizedBox.shrink();

    final isSmall = screenWidth < 600;
    final fontSize = isSmall ? 12.0 : 14.0;
    final hintSize = isSmall ? 11.0 : 14.0;
    final horizontalPadding = isSmall ? 6.0 : 8.0;
    final verticalPadding = isSmall ? 6.0 : 8.0;

    return Flexible(
      child: SizedBox(
        width: searchWidth,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
          child: TextField(
            style: TextStyle(color: Colors.white, fontSize: fontSize),
            decoration: InputDecoration(
              hintText: screenWidth > 600 ? 'Search courses...' : 'Search...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: hintSize),
              filled: true,
              fillColor: const Color(0xFF111827),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmall ? 8.0 : 10.0,
                vertical: isSmall ? 6.0 : 8.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }
}
