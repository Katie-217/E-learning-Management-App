import 'package:flutter/material.dart';
import 'sidebar_model.dart';
import '../../features/student/presentation/pages/student_dashboard_page.dart';
import '../../features/courses/presentation/pages/course_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String activeKey = 'dashboard';

  void onSelect(String key) {
    setState(() {
      activeKey = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
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
      ),
      body: Row(
        children: [
          const SizedBox(width: 0),
          if (MediaQuery.of(context).size.width > 800)
            SidebarWidget(onSelect: onSelect, activeKey: activeKey),
          Expanded(
            child: IndexedStack(
              index: activeKey == 'dashboard' ? 0 : 1,
              children: const [
                StudentDashboardPage(showSidebar: false),
                CoursePage(showSidebar: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


