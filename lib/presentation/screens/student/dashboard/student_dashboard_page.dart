import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/domain/models/task_model.dart';
import 'package:elearning_management_app/application/controllers/student/student_dashboard_metrics_provider.dart';
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
  // final FirestoreService _service = FirestoreService.instance;

  final List<SemesterOption> _semesters = const [
    SemesterOption(id: 'hk1_25', label: 'HK1/2025', isReadonly: false),
    SemesterOption(id: 'hk2_25', label: 'HK2/2025', isReadonly: true),
    SemesterOption(id: 'hkhe_25', label: 'HKH/2025', isReadonly: true),
  ];

  String? _selectedSemesterId;
  String _userName = 'User';
  StudentDashboardMetrics? _metricsData;
  bool _isMetricsLoading = true;
  Object? _metricsError;
  
  @override
  void initState() {
    super.initState();
    if (_semesters.isNotEmpty) {
      _selectedSemesterId = _semesters.first.id;
    }
    _loadUserName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMetricsForCurrentSemester();
    });
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
      print('Error loading user name: $e');
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

  final List<SubmissionItem> _recentSubmissions = const [
    SubmissionItem(
      title: 'Machine Learning Lab 4',
      timeLabel: 'Submitted 2h ago',
      type: DashboardSubmissionType.assignment,
      status: DashboardSubmissionStatus.onTime,
    ),
    SubmissionItem(
      title: 'Database Systems Essay',
      timeLabel: 'Submitted yesterday',
      type: DashboardSubmissionType.assignment,
      status: DashboardSubmissionStatus.early,
    ),
    SubmissionItem(
      title: 'Networks Quiz',
      timeLabel: 'Submitted 4 days ago',
      type: DashboardSubmissionType.quiz,
      status: DashboardSubmissionStatus.late,
    ),
  ];

  List<CompletedQuizItem> get _completedQuizzes => const [
        CompletedQuizItem(
          title: 'Database Systems Quiz 1',
          courseName: 'Database Systems',
          score: 85,
          maxScore: 100,
          completedDate: '2024-01-15',
        ),
        CompletedQuizItem(
          title: 'Machine Learning Midterm',
          courseName: 'Machine Learning',
          score: 92,
          maxScore: 100,
          completedDate: '2024-01-10',
        ),
        CompletedQuizItem(
          title: 'Networks Quiz 2',
          courseName: 'Computer Networks',
          score: 78,
          maxScore: 100,
          completedDate: '2024-01-08',
        ),
      ];

  // Data for pie charts - loaded from real data in _loadSummaryMetrics()

  // ignore: unused_element
  Widget _buildQuizExamList(List<TaskModel> tasks) {
    final relevantTasks = tasks
        .where((task) => task.type == TaskType.quiz || task.type == TaskType.exam)
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
    final semester = _activeSemester;
    final key = buildStudentSemesterKey(semester.id, semester.label);
    setState(() {
      _isMetricsLoading = true;
      _metricsError = null;
    });
    try {
      final metrics =
          await ref.read(studentDashboardMetricsProvider(key).future);
      if (!mounted) return;
      setState(() {
        _metricsData = metrics;
        _isMetricsLoading = false;
      });
    } catch (e) {
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
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
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
                      const SizedBox(height: 24),
                      LayoutBuilder(builder: (context, cons) {
                        final isNarrow = cons.maxWidth < 600;
                        return isNarrow
                            ? Column(
                                children: summaryMetrics
                                    .map((metric) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
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
                                children: summaryMetrics
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final index = entry.key;
                                      final metric = entry.value;
                                      return Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            right: index < summaryMetrics.length - 1
                                                ? 12
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
                                    })
                                    .toList(),
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
                      const SizedBox(height: 18),
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 960;
                      return Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: isWide ? 2 : 0,
                            child: Column(
                              children: [
                                RecentSubmissionsCard(
                                  submissions: _recentSubmissions,
                                ),
                                const SizedBox(height: 12),
                                StudentDashboardCard(
                                  title: 'Progress Overview & Completion Rate',
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isNarrow = constraints.maxWidth < 600;
                                      return isNarrow
                                          ? Column(
                                              children: [
                                                PieChartWidget(
                                                  completed: assignmentsCompleted,
                                                  pending: assignmentsPending,
                                                  title: 'Assignments',
                                                  completedColor: const Color(0xFF22C55E),
                                                  pendingColor: const Color(0xFFFF6B6B),
                                                  trendPercent: 5.0,
                                                  trendLabel: 'vs last month',
                                                ),
                                                Container(
                                                  width: double.infinity,
                                                  height: 1,
                                                  margin: const EdgeInsets.symmetric(vertical: 16),
                                                  color: Colors.grey[800],
                                                ),
                                                PieChartWidget(
                                                  completed: quizzesCompleted,
                                                  pending: quizzesPending,
                                                  title: 'Quizzes',
                                                  completedColor: const Color(0xFF0EA5E9),
                                                  pendingColor: const Color(0xFFFFB347),
                                                  trendPercent: -12.0,
                                                  trendLabel: 'vs previous semester',
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
                                                    completedColor: const Color(0xFF22C55E),
                                                    pendingColor: const Color(0xFFFF6B6B),
                                                  ),
                                                ),
                                                Container(
                                                  width: 2,
                                                  height: 200,
                                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[700],
                                                    borderRadius: BorderRadius.circular(1),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: PieChartWidget(
                                                    completed: quizzesCompleted,
                                                    pending: quizzesPending,
                                                    title: 'Quizzes',
                                                    completedColor: const Color(0xFF0EA5E9),
                                                    pendingColor: const Color(0xFFFFB347),
                                                  ),
                                                ),
                                              ],
                                            );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                CompletedQuizzesCard(
                                  quizzes: _completedQuizzes,
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                          SizedBox(width: isWide ? 12 : 0, height: isWide ? 0 : 12),
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                StudentDashboardCard(
                                  title: 'Calendar',
                                  child: const StudentCalendarPanel(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}









