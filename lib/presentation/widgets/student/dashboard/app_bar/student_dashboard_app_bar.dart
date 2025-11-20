import 'package:flutter/material.dart';

class StudentDashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StudentDashboardAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
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
    );
  }
}

