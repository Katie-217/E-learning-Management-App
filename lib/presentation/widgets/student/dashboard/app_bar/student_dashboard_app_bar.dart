import 'package:flutter/material.dart';

class StudentDashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StudentDashboardAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF1F2937),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          const Flexible(
            child: Text('E-Learning',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      actions: [
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            // Giảm width để tránh overflow
            final searchWidth = screenWidth > 1200
                ? 280.0
                : screenWidth > 800
                    ? 200.0
                    : screenWidth > 600
                        ? 150.0
                        : screenWidth > 400
                            ? 120.0
                            : 0.0; // Ẩn search bar trên màn hình rất nhỏ
            
            if (searchWidth == 0) {
              return const SizedBox.shrink();
            }
            
            return Flexible(
              child: SizedBox(
                width: searchWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: screenWidth > 600 ? 'Search courses, materials...' : 'Search...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF111827),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
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
          },
        ),
        IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none)),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.indigo, Colors.purple]),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (screenWidth > 700) ...[
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'Jara Khan',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

