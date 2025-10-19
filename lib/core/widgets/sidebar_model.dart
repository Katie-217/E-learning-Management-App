import 'package:flutter/material.dart';

class SidebarWidget extends StatelessWidget {
  final void Function(String key)? onSelect;
  final String activeKey;

  const SidebarWidget({super.key, this.onSelect, this.activeKey = 'dashboard'});

  @override
  Widget build(BuildContext context) {
    const sideWidth = 260.0;

    return Container(
      width: sideWidth,
      color: const Color(0xFF111827),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SizedBox(height: 10),
          ListTile(
            selected: activeKey == 'dashboard',
            leading: const Icon(Icons.trending_up),
            title: const Text('Dashboard'),
            onTap: () => onSelect != null
                ? onSelect!('dashboard')
                : Navigator.pushReplacementNamed(context, '/student-dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Courses'),
            selected: activeKey == 'courses',
            onTap: () => onSelect != null
                ? onSelect!('courses')
                : Navigator.pushReplacementNamed(context, '/course'),
          ),
          const ListTile(
            leading: Icon(Icons.assignment),
            title: Text('Assignments'),
          ),
          const ListTile(
            leading: Icon(Icons.emoji_events),
            title: Text('Grades'),
          ),
          const ListTile(
            leading: Icon(Icons.people),
            title: Text('Forums'),
          ),
          const ListTile(
            leading: Icon(Icons.video_library),
            title: Text('Materials'),
          ),
        ],
      ),
    );
  }
}
