import 'package:flutter/material.dart';
import '../../widgets/instructor/course_widget.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  String _activeTab = 'courses';

  final List<CourseModel> courses = [
    CourseModel(
      id: '1',
      title: 'Phân tích và trực quan dữ liệu',
      teacher: 'Trần Lương Quốc Đại',
      time: 'Thứ 5, ca 3, F704',
      faculty: 'Khoa CNTT',
      color: Colors.blue,
    ),
    CourseModel(
      id: '2',
      title: 'Lập trình Web Advanced',
      teacher: 'Nguyễn Văn Hòa',
      time: 'Thứ 3, ca 2, F512',
      faculty: 'Khoa CNTT',
      color: Colors.green,
    ),
    CourseModel(
      id: '3',
      title: 'Database Management Systems',
      teacher: 'Phạm Thị Hương',
      time: 'Thứ 2, ca 4, F801',
      faculty: 'Khoa CNTT',
      color: Colors.purple,
    ),
    CourseModel(
      id: '4',
      title: 'Cấu trúc dữ liệu & Giải thuật',
      teacher: 'Lê Thị Minh Châu',
      time: 'Thứ 4, ca 1, F601',
      faculty: 'Khoa CNTT',
      color: Colors.orange,
    ),
    CourseModel(
      id: '5',
      title: 'Mạng máy tính',
      teacher: 'Phạm Văn Đức',
      time: 'Thứ 3, ca 4, F603',
      faculty: 'Khoa CNTT',
      color: Colors.teal,
    ),
    CourseModel(
      id: '6',
      title: 'Lập trình di động',
      teacher: 'Trần Hoàng Nam',
      time: 'Thứ 6, ca 2, F505',
      faculty: 'Khoa CNTT',
      color: Colors.red,
    ),
  ];

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
              child: const Icon(Icons.book_outlined, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text(
              'My Courses',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Add Course',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.indigo, Colors.purple]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  const Text('Student Name', style: TextStyle(color: Colors.white)),
                ],
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          if (!isMobile)
            Container(
              width: 220,
              color: const Color(0xFF111827),
              child: _buildSidebar(),
            ),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: courses.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) => CourseCard(course: courses[index]),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        _buildSidebarItem('Dashboard', Icons.dashboard, 'dashboard'),
        _buildSidebarItem('My Courses', Icons.book, 'courses'),
        _buildSidebarItem('Calendar', Icons.calendar_today, 'calendar'),
        _buildSidebarItem('Grades', Icons.grade, 'grades'),
        _buildSidebarItem('Settings', Icons.settings, 'settings'),
      ],
    );
  }

  Widget _buildSidebarItem(String label, IconData icon, String tabKey) {
    final isActive = _activeTab == tabKey;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.indigo[600]?.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: Colors.indigo[600]!, width: 1) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.indigo[400] : Colors.grey[400], size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[300],
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => setState(() => _activeTab = tabKey),
      ),
    );
  }
}