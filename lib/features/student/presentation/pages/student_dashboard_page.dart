import 'package:flutter/material.dart';
import '../../../../data/models/assignment_model.dart';
import '../../../../data/models/quiz_model.dart';
// import '../../../../core/services/firestore_service.dart';
import '../widgets/stats_card.dart';
import '../../../assignments/presentation/widgets/assignment_card.dart';
import '../../../quizzes/presentation/widgets/quiz_card.dart';
import '../widgets/bar_chart.dart';
import '../widgets/circular_progress_widget.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/upcoming_events_widget.dart';
import '../../../../core/widgets/sidebar_model.dart';

class StudentDashboardPage extends StatefulWidget {
  final bool showSidebar;
  const StudentDashboardPage({super.key, this.showSidebar = true});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  // final FirestoreService _service = FirestoreService.instance;

  @override
  Widget build(BuildContext context) {
    final sideWidth = 260.0;

    return Scaffold(
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
                const Text('E-Learning', style: TextStyle(fontWeight: FontWeight.w600)),
              ]),
              actions: [
                SizedBox(
                  width: 300,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search courses, materials...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFF111827),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.indigo, Colors.purple]),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Jara Khan'),
                  ]),
                )
              ],
            )
          : null,
      body: Row(
        children: [
          // Sidebar
          if (widget.showSidebar && MediaQuery.of(context).size.width > 800)
            const SidebarWidget(),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hello Jara',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("Let's learn something new today!",
                      style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 18),

                  // === Stats Grid ===
                  LayoutBuilder(builder: (context, cons) {
                    final cross = cons.maxWidth > 900 ? 4 : (cons.maxWidth > 600 ? 2 : 1);
                    return GridView.count(
                      crossAxisCount: cross,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        StatsCard(icon: Icons.schedule, title: 'In Progress', value: '5', bgStart: Colors.orange, bgEnd: Colors.orangeAccent, iconColor: Colors.orange),
                        StatsCard(icon: Icons.check_circle, title: 'Completed', value: '12', bgStart: Colors.green, bgEnd: Colors.greenAccent, iconColor: Colors.green),
                        StatsCard(icon: Icons.emoji_events, title: 'Certificates', value: '8', bgStart: Colors.blue, bgEnd: Colors.blueAccent, iconColor: Colors.blue),
                        StatsCard(icon: Icons.trending_up, title: 'Avg Score', value: '85%', bgStart: Colors.purple, bgEnd: Colors.purpleAccent, iconColor: Colors.purple),
                      ],
                    );
                  }),
                  const SizedBox(height: 15),

                  // === Two-column main area ===
                  LayoutBuilder(builder: (context, constraints) {
                    final leftFlex = constraints.maxWidth > 900 ? 2 : 1;
                    const rightFlex = 1;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // === LEFT column ===
                        Expanded(
                          flex: leftFlex,
                          child: Column(
                            children: [
                              // Active Hours + Performance
                              Row(
                                children: [
                                  // Active Hours Card
                                  Expanded(
                                    child: Container(
                                      height: 400, // Increased height to prevent overflow
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF111827),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[800]!),
                                      ),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Active Hours', style: TextStyle(fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 12),
                                            SimpleBarChart(data: [
                                              {'day': 'M', 'height': 90.0},
                                              {'day': 'T', 'height': 120.0},
                                              {'day': 'W', 'height': 70.0},
                                              {'day': 'T', 'height': 120.0},
                                              {'day': 'F', 'height': 100.0},
                                              {'day': 'S', 'height': 85.0},
                                              {'day': 'S', 'height': 110.0},
                                            ]),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Performance Card
                                  Expanded(
                                    child: Container(
                                      height: 400, // Increased height to match Active Hours
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF111827),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[800]!),
                                      ),
                                      child: SingleChildScrollView(
                                        child: const Column(
                                          children: [
                                            Text('Performance', style: TextStyle(fontWeight: FontWeight.w600)),
                                            SizedBox(height: 10),
                                            CircularPercentWidget(percent: 0.40, label: 'Productivity'),
                                            SizedBox(height: 8),
                                            Text('Your productivity is 40% higher compared to last month', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center)
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Assignments Section
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111827),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[800]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('My Assignments', style: TextStyle(fontWeight: FontWeight.w600)),
                                    SizedBox(height: 8),
                                    // Gắn Firestore hoặc mock data trong AssignmentCard
                                    AssignmentCard(
                                      assignment: Assignment(id: '1', title: 'Mobile App Development', dueDate: 'Today, 11:59 PM', grade: '85/100', status: 'completed'),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Quizzes Section
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111827),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[800]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Quizzes & Exams', style: TextStyle(fontWeight: FontWeight.w600)),
                                    SizedBox(height: 8),
                                    QuizCard(
                                      quiz: Quiz(id: '1', title: 'Database Management Quiz', dueDate: 'Tomorrow, 2:00 PM', duration: '45 min', questions: 20, status: 'upcoming'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // === RIGHT column ===
                        Expanded(
                          flex: rightFlex,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111827),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[800]!)
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: const [
                                    Text('February 2025', style: TextStyle(fontWeight: FontWeight.w600)),
                                    SizedBox(height: 12),
                                    SimpleCalendar(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const UpcomingEventsWidget(),
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
    );
  }
}









