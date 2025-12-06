import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/domain/models/task_model.dart';
import 'package:elearning_management_app/application/controllers/student/student_dashboard_metrics_provider.dart';
import 'package:elearning_management_app/data/repositories/semester/semester_repository.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/summary_metrics/stats_card.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/progress_overview/pie_chart_widget.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/calendar/student_calendar_panel.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/calendar/components/calendar_task_tile.dart';
import 'package:elearning_management_app/presentation/widgets/common/sidebar_model.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/common/student_dashboard_models.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/common/student_dashboard_card.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/app_bar/student_dashboard_app_bar.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/header/student_dashboard_header.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/recent_submissions/recent_submissions_card.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/completed_quizzes/completed_quizzes_card.dart';

class StudentDashboardPage extends ConsumerStatefulWidget {
  final bool showSidebar;
  const StudentDashboardPage({super.key, this.showSidebar = true});

  @override
  ConsumerState<StudentDashboardPage> createState() =>
      _StudentDashboardPageState();
}

class _StudentDashboardPageState extends ConsumerState<StudentDashboardPage> {
  List<SemesterOption> _semesters = [];
  String? _selectedSemesterId;
  String _userName = 'User';
  StudentDashboardMetrics? _metricsData;
  bool _isMetricsLoading = true;
  bool _isSemestersLoading = true;
  Object? _metricsError;
  
  // Sử dụng providers có sẵn trong controller

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadSemesters(); // Sẽ tự động load metrics sau khi semesters load xong
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
            // Kiểm tra xem semester có đang active không (dựa vào startDate và endDate)
            final now = DateTime.now();
            final isReadonly = semester.endDate != null && 
                              now.isAfter(semester.endDate!);
            
            return SemesterOption(
              id: semester.id,
              label: semester.name,
              isReadonly: isReadonly,
            );
          }).toList();
          
          // Sắp xếp: active trước, readonly sau
          _semesters.sort((a, b) {
            if (a.isReadonly == b.isReadonly) return 0;
            return a.isReadonly ? 1 : -1;
          });
          
          _isSemestersLoading = false;
          
          // Chọn semester đầu tiên nếu chưa có và load metrics
          if (_selectedSemesterId == null && _semesters.isNotEmpty) {
            _selectedSemesterId = _semesters.first.id;
            // Load metrics sau khi đã có semester
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadMetricsForCurrentSemester();
            });
          } else if (_selectedSemesterId != null) {
            // Nếu đã có semester, load metrics ngay
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadMetricsForCurrentSemester();
            });
          }
        });
      }
    } catch (e) {
      print('DEBUG: ❌ Error loading semesters: $e');
      if (mounted) {
        setState(() {
          _isSemestersLoading = false;
          // Fallback to empty list nếu lỗi
          _semesters = [];
          // Vẫn load metrics với semester mặc định
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadMetricsForCurrentSemester();
          });
        });
      }
    }
  }

  Future<void> _loadUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _userName = data['name'] ?? user.displayName ?? 'User';
          });
        } else {
          // Fallback to Firebase Auth data
          setState(() {
            _userName = user.displayName ?? 'User';
          });
        }
      }
    } catch (e) {
      // Error loading user name - continue with default
    }
  }

  SemesterOption get _activeSemester {
    SemesterOption? matched;
    final currentId = _selectedSemesterId;
    if (currentId != null) {
      for (final option in _semesters) {
        if (option.id == currentId) {
          matched = option;
          break;
        }
      }
    }
    matched ??= _semesters.isNotEmpty
        ? _semesters.first
        : const SemesterOption(
            id: 'default',
            label: 'Current Semester',
            isReadonly: false,
          );
    // Auto-update selectedSemesterId if it doesn't match (original logic)
    // Note: This doesn't call setState, just updates the value
    if (matched.id != currentId) {
      _selectedSemesterId = matched.id;
    }
    return matched;
  }

  List<SummaryMetric> _buildSummaryMetrics(
    StudentDashboardMetrics? metrics,
    bool isLoading,
  ) {
    String valueText(int value) => isLoading ? '...' : '$value';

    return [
      SummaryMetric(
        icon: Icons.menu_book_outlined,
        title: 'Courses',
        value: valueText(metrics?.coursesCount ?? 0),
        bgStart: const Color(0xFF6366F1),
        bgEnd: const Color(0xFF8B5CF6),
        iconColor: const Color(0xFFACAFFF),
      ),
      SummaryMetric(
        icon: Icons.assignment_outlined,
        title: 'Assignments',
        value: valueText(metrics?.assignmentsCount ?? 0),
        bgStart: const Color(0xFFF97316),
        bgEnd: const Color(0xFFFFB347),
        iconColor: const Color(0xFFFFE0B5),
      ),
      SummaryMetric(
        icon: Icons.pending_actions_outlined,
        title: 'Pending / Late',
        value: valueText(metrics?.pendingLateCount ?? 0),
        bgStart: const Color(0xFFFF6B6B),
        bgEnd: const Color(0xFFFF8E72),
        iconColor: const Color(0xFFFFD6D6),
      ),
      SummaryMetric(
        icon: Icons.quiz_outlined,
        title: 'Quizzes',
        value: valueText(metrics?.quizzesCount ?? 0),
        bgStart: const Color(0xFF0EA5E9),
        bgEnd: const Color(0xFF38BDF8),
        iconColor: const Color(0xFFBEE8FF),
      ),
    ];
  }

  // Removed hardcoded data - now using real data from repositories

  // Data for pie charts - loaded from real data in _loadSummaryMetrics()

  // ignore: unused_element
  Widget _buildQuizExamList(List<TaskModel> tasks) {
    final relevantTasks = tasks
        .where(
            (task) => task.type == TaskType.quiz || task.type == TaskType.exam)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    if (relevantTasks.isEmpty) {
      return const Text(
        'Không có quiz hoặc exam trong tháng này.',
        style: TextStyle(color: Colors.white70, fontSize: 12),
      );
    }

    return Column(
      children: relevantTasks
          .map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CalendarTaskTile(task: task),
              ))
          .toList(),
    );
  }

  // ignore: unused_element
  Widget _buildDailyTasks(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return const Text(
        'Không có nhiệm vụ nào cho ngày đã chọn.',
        style: TextStyle(color: Colors.white70, fontSize: 12),
      );
    }

    final sortedTasks = tasks.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Column(
      children: sortedTasks
          .map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CalendarTaskTile(task: task),
              ))
          .toList(),
    );
  }

  Future<void> _loadMetricsForCurrentSemester() async {
    if (!mounted) return;
    
    final semester = _activeSemester;
    final key = buildStudentSemesterKey(semester.id, semester.label);
    
    print('DEBUG: 🔍 Loading metrics for semester: ${semester.label} (key: $key)');
    
    setState(() {
      _isMetricsLoading = true;
      _metricsError = null;
    });
    
    try {
      final metrics = await ref.read(studentDashboardMetricsProvider(key).future);
      
      print('DEBUG: ✅ Metrics loaded:');
      print('  - Courses: ${metrics.coursesCount}');
      print('  - Assignments: ${metrics.assignmentsCount}');
      print('  - Completed: ${metrics.assignmentsCompleted}');
      print('  - Pending: ${metrics.assignmentsPending}');
      print('  - Pending/Late: ${metrics.pendingLateCount}');
      
      if (!mounted) return;
      setState(() {
        _metricsData = metrics;
        _isMetricsLoading = false;
      });
    } catch (e, stackTrace) {
      print('DEBUG: ❌ Error loading metrics: $e');
      print('DEBUG: Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _metricsError = e;
        _isMetricsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);

    final activeSemester = _activeSemester;
    final summaryMetrics =
        _buildSummaryMetrics(_metricsData, _isMetricsLoading);
    final isReadonlySemester = activeSemester.isReadonly;
    final assignmentsCompleted = _metricsData?.assignmentsCompleted ?? 0;
    final assignmentsPending = _metricsData?.assignmentsPending ?? 0;
    final quizzesCompleted = _metricsData?.quizzesCompleted ?? 0;
    final quizzesPending = _metricsData?.quizzesPending ?? 0;

    return Theme(
      data: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        iconTheme: baseTheme.iconTheme.copyWith(color: Colors.white70),
        listTileTheme: baseTheme.listTileTheme.copyWith(
          textColor: Colors.white,
          iconColor: Colors.white70,
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1720),
        appBar: widget.showSidebar ? const StudentDashboardAppBar() : null,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showSidebar && MediaQuery.of(context).size.width > 800)
              const SidebarWidget(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final padding = screenWidth > 800
                      ? 18.0
                      : screenWidth > 600
                          ? 16.0
                          : 12.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StudentDashboardHeader(
                          userName: _userName,
                          semesters: _semesters,
                          selectedSemesterId: _selectedSemesterId,
                          isReadonlySemester: isReadonlySemester,
                          onSemesterChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedSemesterId = value;
                            });
                            _loadMetricsForCurrentSemester();
                          },
                        ),
                        LayoutBuilder(builder: (context, headerCons) {
                          final headerScreenWidth = MediaQuery.of(context).size.width;
                          return SizedBox(height: headerScreenWidth > 600 ? 24 : 16);
                        }),
                    LayoutBuilder(builder: (context, cons) {
                      final isNarrow = cons.maxWidth < 600;
                      final currentScreenWidth = MediaQuery.of(context).size.width;
                      final spacing = currentScreenWidth > 600 ? 12.0 : 8.0;
                      // Đảm bảo bố cục chính không bị phá vỡ - chỉ thay đổi direction của cards
                      return isNarrow
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch, // Đảm bảo cards chiếm full width
                              children: summaryMetrics
                                  .map((metric) => Padding(
                                        padding: EdgeInsets.only(bottom: spacing),
                                        child: StatsCard(
                                          icon: metric.icon,
                                          title: metric.title,
                                          value: metric.value,
                                          bgStart: metric.bgStart,
                                          bgEnd: metric.bgEnd,
                                          iconColor: metric.iconColor,
                                        ),
                                      ))
                                  .toList(),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start, // Giữ alignment
                              children:
                                  summaryMetrics.asMap().entries.map((entry) {
                                final index = entry.key;
                                final metric = entry.value;
                                return Expanded(
                                  // Dùng Expanded để chia đều không gian, đảm bảo không overflow
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: index < summaryMetrics.length - 1
                                          ? spacing
                                          : 0,
                                    ),
                                    child: StatsCard(
                                      icon: metric.icon,
                                      title: metric.title,
                                      value: metric.value,
                                      bgStart: metric.bgStart,
                                      bgEnd: metric.bgEnd,
                                      iconColor: metric.iconColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                    }),
                    if (_metricsError != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(239, 68, 68, 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromRGBO(239, 68, 68, 0.3),
                          ),
                        ),
                        child: Text(
                          'Không thể tải dữ liệu thống kê: $_metricsError',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    LayoutBuilder(builder: (context, spacingCons) {
                      final spacingScreenWidth = MediaQuery.of(context).size.width;
                      return SizedBox(height: spacingScreenWidth > 600 ? 18 : 12);
                    }),
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 960;
                      final mainScreenWidth = MediaQuery.of(context).size.width;
                      return Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main content column - luôn chiếm đủ không gian
                          if (isWide)
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final submissionsAsync = ref.watch(studentRecentSubmissionsItemProvider);
                                      return submissionsAsync.when(
                                        data: (submissions) => RecentSubmissionsCard(
                                          submissions: submissions,
                                        ),
                                        loading: () => RecentSubmissionsCard(
                                          submissions: [],
                                        ),
                                        error: (_, __) => RecentSubmissionsCard(
                                          submissions: [],
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: mainScreenWidth > 600 ? 12 : 8),
                                  StudentDashboardCard(
                                    title: 'Progress Overview & Completion Rate',
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final isNarrow =
                                            constraints.maxWidth < 600;
                                        return isNarrow
                                            ? Column(
                                                children: [
                                                  PieChartWidget(
                                                    completed:
                                                        assignmentsCompleted,
                                                    pending: assignmentsPending,
                                                    title: 'Assignments',
                                                    completedColor:
                                                        const Color(0xFF22C55E),
                                                    pendingColor:
                                                        const Color(0xFFFF6B6B),
                                                    trendPercent: 5.0,
                                                    trendLabel: 'vs last month',
                                                  ),
                                                  Container(
                                                    width: double.infinity,
                                                    height: 1,
                                                    margin: const EdgeInsets
                                                        .symmetric(vertical: 16),
                                                    color: Colors.grey[800],
                                                  ),
                                                  PieChartWidget(
                                                    completed: quizzesCompleted,
                                                    pending: quizzesPending,
                                                    title: 'Quizzes',
                                                    completedColor:
                                                        const Color(0xFF0EA5E9),
                                                    pendingColor:
                                                        const Color(0xFFFFB347),
                                                    trendPercent: -12.0,
                                                    trendLabel:
                                                        'vs previous semester',
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                children: [
                                                  Expanded(
                                                    child: PieChartWidget(
                                                      completed:
                                                          assignmentsCompleted,
                                                      pending: assignmentsPending,
                                                      title: 'Assignments',
                                                      completedColor:
                                                          const Color(0xFF22C55E),
                                                      pendingColor:
                                                          const Color(0xFFFF6B6B),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 2,
                                                    height: 200,
                                                    margin: const EdgeInsets
                                                        .symmetric(horizontal: 8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[700],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              1),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: PieChartWidget(
                                                      completed: quizzesCompleted,
                                                      pending: quizzesPending,
                                                      title: 'Quizzes',
                                                      completedColor:
                                                          const Color(0xFF0EA5E9),
                                                      pendingColor:
                                                          const Color(0xFFFFB347),
                                                    ),
                                                  ),
                                                ],
                                              );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: mainScreenWidth > 600 ? 12 : 8),
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final quizzesAsync = ref.watch(studentCompletedQuizzesItemProvider);
                                      return quizzesAsync.when(
                                        data: (quizzes) => CompletedQuizzesCard(
                                          quizzes: quizzes,
                                        ),
                                        loading: () => CompletedQuizzesCard(
                                          quizzes: [],
                                        ),
                                        error: (_, __) => CompletedQuizzesCard(
                                          quizzes: [],
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: mainScreenWidth > 600 ? 12 : 8),
                                ],
                              ),
                            )
                          else
                            // Khi màn hình nhỏ, không dùng Expanded để tránh overflow
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Consumer(
                                  builder: (context, ref, child) {
                                    final submissionsAsync = ref.watch(studentRecentSubmissionsItemProvider);
                                    return submissionsAsync.when(
                                      data: (submissions) => RecentSubmissionsCard(
                                        submissions: submissions,
                                      ),
                                      loading: () => RecentSubmissionsCard(
                                        submissions: [],
                                      ),
                                      error: (_, __) => RecentSubmissionsCard(
                                        submissions: [],
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: mainScreenWidth > 600 ? 12 : 8),
                                StudentDashboardCard(
                                  title: 'Progress Overview & Completion Rate',
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isNarrow =
                                          constraints.maxWidth < 600;
                                      return isNarrow
                                          ? Column(
                                              children: [
                                                PieChartWidget(
                                                  completed:
                                                      assignmentsCompleted,
                                                  pending: assignmentsPending,
                                                  title: 'Assignments',
                                                  completedColor:
                                                      const Color(0xFF22C55E),
                                                  pendingColor:
                                                      const Color(0xFFFF6B6B),
                                                  trendPercent: 5.0,
                                                  trendLabel: 'vs last month',
                                                ),
                                                Container(
                                                  width: double.infinity,
                                                  height: 1,
                                                  margin: const EdgeInsets
                                                      .symmetric(vertical: 16),
                                                  color: Colors.grey[800],
                                                ),
                                                PieChartWidget(
                                                  completed: quizzesCompleted,
                                                  pending: quizzesPending,
                                                  title: 'Quizzes',
                                                  completedColor:
                                                      const Color(0xFF0EA5E9),
                                                  pendingColor:
                                                      const Color(0xFFFFB347),
                                                  trendPercent: -12.0,
                                                  trendLabel:
                                                      'vs previous semester',
                                                ),
                                              ],
                                            )
                                          : Row(
                                              children: [
                                                Expanded(
                                                  child: PieChartWidget(
                                                    completed:
                                                        assignmentsCompleted,
                                                    pending: assignmentsPending,
                                                    title: 'Assignments',
                                                    completedColor:
                                                        const Color(0xFF22C55E),
                                                    pendingColor:
                                                        const Color(0xFFFF6B6B),
                                                  ),
                                                ),
                                                Container(
                                                  width: 2,
                                                  height: 200,
                                                  margin: const EdgeInsets
                                                      .symmetric(horizontal: 8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[700],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            1),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: PieChartWidget(
                                                    completed: quizzesCompleted,
                                                    pending: quizzesPending,
                                                    title: 'Quizzes',
                                                    completedColor:
                                                        const Color(0xFF0EA5E9),
                                                    pendingColor:
                                                        const Color(0xFFFFB347),
                                                  ),
                                                ),
                                              ],
                                            );
                                    },
                                  ),
                                ),
                                SizedBox(height: mainScreenWidth > 600 ? 12 : 8),
                                Consumer(
                                  builder: (context, ref, child) {
                                    final quizzesAsync = ref.watch(studentCompletedQuizzesItemProvider);
                                    return quizzesAsync.when(
                                      data: (quizzes) => CompletedQuizzesCard(
                                        quizzes: quizzes,
                                      ),
                                      loading: () => CompletedQuizzesCard(
                                        quizzes: [],
                                      ),
                                      error: (_, __) => CompletedQuizzesCard(
                                        quizzes: [],
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: mainScreenWidth > 600 ? 12 : 8),
                              ],
                            ),
                          SizedBox(
                              width: isWide ? (mainScreenWidth > 800 ? 12 : 8) : 0,
                              height: isWide ? 0 : (mainScreenWidth > 600 ? 12 : 8)),
                          // Calendar sidebar - luôn chiếm đủ không gian khi wide
                          if (isWide)
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  StudentDashboardCard(
                                    title: 'Calendar',
                                    child: const StudentCalendarPanel(),
                                  ),
                                ],
                              ),
                            )
                          else
                            // Khi màn hình nhỏ, calendar ở dưới
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                StudentDashboardCard(
                                  title: 'Calendar',
                                  child: const StudentCalendarPanel(),
                                ),
                              ],
                            ),
                        ],
                      );
                    }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
