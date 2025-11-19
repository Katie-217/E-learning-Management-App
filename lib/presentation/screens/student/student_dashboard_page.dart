import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/application/controllers/instructor/task_provider.dart';
import 'package:elearning_management_app/domain/models/task_model.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/data/repositories/course/course_student_repository.dart';
import 'package:elearning_management_app/data/repositories/assignment/assignment_repository.dart';
import 'package:elearning_management_app/data/repositories/submission/submission_repository.dart';
import 'package:elearning_management_app/domain/models/submission_model.dart';
import 'package:elearning_management_app/presentation/widgets/student/stats_card.dart';
import 'package:elearning_management_app/presentation/widgets/student/circular_progress_widget.dart';
import 'package:elearning_management_app/presentation/widgets/student/pie_chart_widget.dart';
import 'package:elearning_management_app/presentation/widgets/student/student_calendar_panel.dart';
import 'package:elearning_management_app/presentation/widgets/common/sidebar_model.dart';
import 'package:intl/intl.dart';

class StudentDashboardPage extends ConsumerStatefulWidget {
  final bool showSidebar;
  const StudentDashboardPage({super.key, this.showSidebar = true});

  @override
  ConsumerState<StudentDashboardPage> createState() =>
      _StudentDashboardPageState();
}

class _StudentDashboardPageState extends ConsumerState<StudentDashboardPage> {
  // final FirestoreService _service = FirestoreService.instance;

  final List<_SemesterOption> _semesters = const [
    _SemesterOption(id: 'hk1_25', label: 'HK1/2025', isReadonly: false),
    _SemesterOption(id: 'hk2_25', label: 'HK2/2025', isReadonly: true),
    _SemesterOption(id: 'hkhe_25', label: 'HKH/2025', isReadonly: true),
  ];

  String? _selectedSemesterId;
  String _userName = 'User';

  // Summary metrics data
  int _coursesCount = 0;
  int _assignmentsCount = 0;
  int _pendingLateCount = 0;
  int _quizzesCount = 0;
  bool _isLoadingMetrics = true;

  // Pie chart data
  double _assignmentsCompleted = 0.0;
  double _assignmentsPending = 0.0;
  double _quizzesCompleted = 0.0;
  double _quizzesPending = 0.0;

  @override
  void initState() {
    super.initState();
    if (_semesters.isNotEmpty) {
      _selectedSemesterId = _semesters.first.id;
    }
    _loadUserName();
    _loadSummaryMetrics();
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

  Future<void> _loadSummaryMetrics() async {
    try {
      setState(() {
        _isLoadingMetrics = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoadingMetrics = false;
        });
        return;
      }

      // Load courses
      final courses = await CourseStudentRepository.getUserCourses(user.uid);
      final coursesCount = courses.length;

      // Load all assignments from all courses
      List<Assignment> allAssignments = [];
      Map<String, String> assignmentToCourseMap =
          {}; // assignmentId -> courseId

      for (var course in courses) {
        try {
          final assignments =
              await AssignmentRepository.getAssignmentsByCourse(course.id);
          allAssignments.addAll(assignments);
          // Map assignment IDs to course IDs
          for (var assignment in assignments) {
            assignmentToCourseMap[assignment.id] = course.id;
          }
        } catch (e) {
          print('Error loading assignments for course ${course.id}: $e');
        }
      }

      final now = DateTime.now();

      // Count assignments
      final assignmentsCount = allAssignments.length;

      // Load submissions for all assignments
      Map<String, bool> assignmentSubmittedMap =
          {}; // assignmentId -> isSubmitted
      int assignmentsCompleted = 0;
      int assignmentsPending = 0;

      for (var assignment in allAssignments) {
        final courseId = assignmentToCourseMap[assignment.id];
        if (courseId != null) {
          try {
            final submission =
                await SubmissionRepository.getStudentSubmissionForAssignment(
              assignment.id,
              user.uid, // studentId
            );
            final isSubmitted = submission != null &&
                (submission.status == SubmissionStatus.submitted ||
                    submission.status == SubmissionStatus.graded);
            assignmentSubmittedMap[assignment.id] = isSubmitted;

            if (isSubmitted) {
              assignmentsCompleted++;
            } else {
              assignmentsPending++;
            }
          } catch (e) {
            print(
                'Error checking submission for assignment ${assignment.id}: $e');
            assignmentSubmittedMap[assignment.id] = false;
            assignmentsPending++;
          }
        } else {
          assignmentSubmittedMap[assignment.id] = false;
          assignmentsPending++;
        }
      }

      // Count pending/late assignments (not submitted and deadline passed or upcoming)
      final pendingLate = allAssignments.where((a) {
        final isSubmitted = assignmentSubmittedMap[a.id] ?? false;
        if (isSubmitted) return false; // Exclude submitted assignments

        // Pending: deadline in future
        // Late: deadline in past
        return a.deadline.isAfter(now) || a.deadline.isBefore(now);
      }).length;

      // For now, quizzes count = 0 (need quiz repository or check assignment type)
      // TODO: Implement quiz repository or check assignment type field
      final quizzesCount = 0;
      final quizzesPending = 0.0;
      final quizzesCompleted = 0.0;

      setState(() {
        _coursesCount = coursesCount;
        _assignmentsCount = assignmentsCount;
        _pendingLateCount = pendingLate;
        _quizzesCount = quizzesCount;
        _assignmentsPending = assignmentsPending.toDouble();
        _assignmentsCompleted = assignmentsCompleted.toDouble();
        _quizzesPending = quizzesPending;
        _quizzesCompleted = quizzesCompleted;
        _isLoadingMetrics = false;
      });

      print(
          'DEBUG: Summary metrics loaded - Courses: $coursesCount, Assignments: $assignmentsCount, Completed: $assignmentsCompleted, Pending: $assignmentsPending, Pending/Late: $pendingLate');
    } catch (e) {
      print('Error loading summary metrics: $e');
      setState(() {
        _isLoadingMetrics = false;
      });
    }
  }

  _SemesterOption get _activeSemester {
    _SemesterOption? matched;
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
        : const _SemesterOption(
            id: 'default',
            label: 'Current Semester',
            isReadonly: false,
          );
    if (matched.id != currentId) {
      _selectedSemesterId = matched.id;
    }
    return matched;
  }

  bool get _isReadonlySemester => _activeSemester.isReadonly;

  List<_SummaryMetric> get _summaryMetrics => [
        _SummaryMetric(
          icon: Icons.menu_book_outlined,
          title: 'Courses',
          value: _isLoadingMetrics ? '...' : '$_coursesCount',
          bgStart: const Color(0xFF6366F1),
          bgEnd: const Color(0xFF8B5CF6),
          iconColor: const Color(0xFFACAFFF),
        ),
        _SummaryMetric(
          icon: Icons.assignment_outlined,
          title: 'Assignments',
          value: _isLoadingMetrics ? '...' : '$_assignmentsCount',
          bgStart: const Color(0xFFF97316),
          bgEnd: const Color(0xFFFFB347),
          iconColor: const Color(0xFFFFE0B5),
        ),
        _SummaryMetric(
          icon: Icons.pending_actions_outlined,
          title: 'Pending / Late',
          value: _isLoadingMetrics ? '...' : '$_pendingLateCount',
          bgStart: const Color(0xFFFF6B6B),
          bgEnd: const Color(0xFFFF8E72),
          iconColor: const Color(0xFFFFD6D6),
        ),
        _SummaryMetric(
          icon: Icons.quiz_outlined,
          title: 'Quizzes',
          value: _isLoadingMetrics ? '...' : '$_quizzesCount',
          bgStart: const Color(0xFF0EA5E9),
          bgEnd: const Color(0xFF38BDF8),
          iconColor: const Color(0xFFBEE8FF),
        ),
      ];

  final List<_SubmissionItem> _recentSubmissions = const [
    _SubmissionItem(
      title: 'Machine Learning Lab 4',
      timeLabel: 'Submitted 2h ago',
      type: _SubmissionType.assignment,
      status: _SubmissionStatus.onTime,
    ),
    _SubmissionItem(
      title: 'Database Systems Essay',
      timeLabel: 'Submitted yesterday',
      type: _SubmissionType.assignment,
      status: _SubmissionStatus.early,
    ),
    _SubmissionItem(
      title: 'Networks Quiz',
      timeLabel: 'Submitted 4 days ago',
      type: _SubmissionType.quiz,
      status: _SubmissionStatus.late,
    ),
  ];

  List<_CompletedQuizItem> get _completedQuizzes => const [
        _CompletedQuizItem(
          title: 'Database Systems Quiz 1',
          courseName: 'Database Systems',
          score: 85,
          maxScore: 100,
          completedDate: '2024-01-15',
        ),
        _CompletedQuizItem(
          title: 'Machine Learning Midterm',
          courseName: 'Machine Learning',
          score: 92,
          maxScore: 100,
          completedDate: '2024-01-10',
        ),
        _CompletedQuizItem(
          title: 'Networks Quiz 2',
          courseName: 'Computer Networks',
          score: 78,
          maxScore: 100,
          completedDate: '2024-01-08',
        ),
      ];

  // Data for pie charts - loaded from real data in _loadSummaryMetrics()

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
                child: _TaskTile(task: task),
              ))
          .toList(),
    );
  }

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
                child: _TaskTile(task: task),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);

    final selectedDate = ref.watch(selectedDateProvider);
    final monthKey = DateTime(selectedDate.year, selectedDate.month);
    final monthlyTasksAsync = ref.watch(tasksForMonthProvider(monthKey));

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
        appBar: widget.showSidebar
            ? AppBar(
                backgroundColor: const Color(0xFF1F2937),
                title: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.indigo[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu_book),
                  ),
                  const SizedBox(width: 12),
                  const Text('E-Learning',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )),
                ]),
                actions: [
                  SizedBox(
                    width: 300,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search courses, materials...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: const Color(0xFF111827),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none)),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Colors.indigo, Colors.purple]),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Jara Khan',
                        style: TextStyle(color: Colors.white),
                      ),
                    ]),
                  )
                ],
              )
            : null,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello $_userName',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isReadonlySemester
                                    ? 'Viewing past semester (read-only)'
                                    : "Let's learn something new today!",
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.school_outlined, size: 20),
                              const SizedBox(width: 8),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: const Color(0xFF1F2937),
                                  value:
                                      _selectedSemesterId ?? _activeSemester.id,
                                  borderRadius: BorderRadius.circular(12),
                                  icon: const Icon(
                                    Icons.expand_more,
                                    color: Colors.white70,
                                  ),
                                  items: _semesters
                                      .map(
                                        (semester) => DropdownMenuItem(
                                          value: semester.id,
                                          child: Text(
                                            semester.label,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _selectedSemesterId = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(builder: (context, cons) {
                      final isNarrow = cons.maxWidth < 600;
                      return isNarrow
                          ? Column(
                              children: _summaryMetrics
                                  .map((metric) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
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
                              children:
                                  _summaryMetrics.asMap().entries.map((entry) {
                                final index = entry.key;
                                final metric = entry.value;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: index < _summaryMetrics.length - 1
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
                              }).toList(),
                            );
                    }),
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
                                _DashboardCard(
                                  title: 'Recent Submissions',
                                  child: Column(
                                    children: _recentSubmissions
                                        .map(
                                          (submission) => _SubmissionTile(
                                            item: submission,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _DashboardCard(
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
                                                      _assignmentsCompleted,
                                                  pending: _assignmentsPending,
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
                                                  completed: _quizzesCompleted,
                                                  pending: _quizzesPending,
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
                                                        _assignmentsCompleted,
                                                    pending:
                                                        _assignmentsPending,
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
                                                    completed:
                                                        _quizzesCompleted,
                                                    pending: _quizzesPending,
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
                                const SizedBox(height: 12),
                                _DashboardCard(
                                  title: 'Completed Quizzes with Scores',
                                  child: _completedQuizzes.isNotEmpty
                                      ? Column(
                                          children: _completedQuizzes
                                              .map(
                                                (quiz) => _CompletedQuizTile(
                                                  item: quiz,
                                                ),
                                              )
                                              .toList(),
                                        )
                                      : const Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Text(
                                            'No completed quizzes available.',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                          SizedBox(
                              width: isWide ? 12 : 0, height: isWide ? 0 : 12),
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                _DashboardCard(
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

class _DashboardCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _DashboardCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  final _SubmissionItem item;
  const _SubmissionTile({required this.item});

  Color get _statusColor {
    switch (item.status) {
      case _SubmissionStatus.onTime:
        return const Color(0xFF34D399); // Green
      case _SubmissionStatus.early:
        return const Color(0xFFFFB347); // Orange
      case _SubmissionStatus.late:
        return const Color(0xFFFF6B6B); // Red
    }
  }

  String get _statusLabel {
    switch (item.status) {
      case _SubmissionStatus.onTime:
        return 'On time';
      case _SubmissionStatus.early:
        return 'Early';
      case _SubmissionStatus.late:
        return 'Late';
    }
  }

  IconData get _icon {
    switch (item.type) {
      case _SubmissionType.assignment:
        return Icons.assignment_outlined;
      case _SubmissionType.quiz:
        return Icons.quiz_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _icon,
              color: _statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item.timeLabel,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chevron_right),
            color: Colors.white54,
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  const _TaskTile({required this.task});

  Color get _primaryColor {
    switch (task.type) {
      case TaskType.assignment:
        return const Color(0xFF60A5FA);
      case TaskType.quiz:
        return const Color(0xFFFBBF24);
      case TaskType.exam:
        return const Color(0xFFF472B6);
      case TaskType.deadline:
        return const Color(0xFF34D399);
      case TaskType.other:
        return const Color(0xFF818CF8);
    }
  }

  IconData get _icon {
    switch (task.type) {
      case TaskType.assignment:
        return Icons.assignment_outlined;
      case TaskType.quiz:
        return Icons.quiz_outlined;
      case TaskType.exam:
        return Icons.fact_check_outlined;
      case TaskType.deadline:
        return Icons.event_note_outlined;
      case TaskType.other:
        return Icons.task_alt_outlined;
    }
  }

  String _getStatusLabel() {
    try {
      final now = DateTime.now();
      final dueDate = task.dateTime;
      final difference = dueDate.difference(now).inDays;

      if (task.isCompleted) {
        if (difference < 0) {
          return 'Submitted • Late';
        } else {
          return 'Submitted';
        }
      } else {
        if (difference < 0) {
          return 'Late';
        } else if (difference == 0) {
          return 'Due today • Pending';
        } else if (difference == 1) {
          return 'Due tomorrow • Pending';
        } else {
          return 'Due in $difference days • Pending';
        }
      }
    } catch (e) {
      return 'Pending';
    }
  }

  Color _getStatusColor() {
    try {
      final now = DateTime.now();
      final dueDate = task.dateTime;
      final difference = dueDate.difference(now).inDays;

      if (task.isCompleted) {
        if (difference < 0) {
          return const Color(0xFFFF6B6B); // Red for late submission
        } else {
          return const Color(0xFF34D399); // Green for on-time submission
        }
      } else {
        if (difference < 0) {
          return const Color(0xFFFF6B6B); // Red for late
        } else if (difference <= 1) {
          return const Color(0xFFFFB347); // Orange for urgent
        } else {
          return const Color(0xFF60A5FA); // Blue for pending
        }
      }
    } catch (e) {
      return const Color(0xFF60A5FA); // Default to blue
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('MMM d • h:mm a').format(task.dateTime);
    final courseLabel = task.courseName ?? 'General';
    final statusLabel = _getStatusLabel();
    final statusColor = _getStatusColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isPriority
              ? const Color(0xFFFF6B6B).withOpacity(0.8)
              : Colors.white.withOpacity(0.12),
          width: task.isPriority ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _primaryColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Icon(_icon, color: _primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  courseLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      timeLabel,
                      style: TextStyle(color: _primaryColor, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (task.isPriority)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFFF6B6B), // Red background for high priority
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B6B).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.priority_high,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Priority',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SemesterOption {
  final String id;
  final String label;
  final bool isReadonly;

  const _SemesterOption({
    required this.id,
    required this.label,
    required this.isReadonly,
  });
}

class _SummaryMetric {
  final IconData icon;
  final String title;
  final String value;
  final Color bgStart;
  final Color bgEnd;
  final Color iconColor;

  const _SummaryMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.bgStart,
    required this.bgEnd,
    required this.iconColor,
  });
}

enum _SubmissionType {
  assignment,
  quiz,
}

enum _SubmissionStatus {
  onTime,
  early,
  late,
}

class _SubmissionItem {
  final String title;
  final String timeLabel;
  final _SubmissionType type;
  final _SubmissionStatus status;

  const _SubmissionItem({
    required this.title,
    required this.timeLabel,
    required this.type,
    required this.status,
  });
}

class _CompletedQuizItem {
  final String title;
  final String courseName;
  final int score;
  final int maxScore;
  final String completedDate;

  const _CompletedQuizItem({
    required this.title,
    required this.courseName,
    required this.score,
    required this.maxScore,
    required this.completedDate,
  });

  double get percentage => (score / maxScore) * 100;
}

class _CompletedQuizTile extends StatelessWidget {
  final _CompletedQuizItem item;
  const _CompletedQuizTile({required this.item});

  Color get _scoreColor {
    final percentage = item.percentage;
    if (percentage >= 90) return const Color(0xFF34D399); // Green
    if (percentage >= 70) return const Color(0xFF60A5FA); // Blue
    if (percentage >= 50) return const Color(0xFFFFB347); // Orange
    return const Color(0xFFFF6B6B); // Red
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _scoreColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.quiz_outlined,
              color: _scoreColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.courseName,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Completed on ${item.completedDate}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _scoreColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _scoreColor.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.score}/${item.maxScore}',
                  style: TextStyle(
                    color: _scoreColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${item.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _scoreColor.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
