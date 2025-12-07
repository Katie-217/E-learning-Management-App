import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/user_menu_dropdown.dart';

class StudentDashboardAppBar extends StatefulWidget implements PreferredSizeWidget {
  const StudentDashboardAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<StudentDashboardAppBar> createState() => _StudentDashboardAppBarState();
}

class _StudentDashboardAppBarState extends State<StudentDashboardAppBar> {
  String _userName = 'User';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
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
            _userName = data['name'] ?? user.displayName ?? 'User';
            _userEmail = user.email ?? '';
          });
        } else if (mounted) {
          setState(() {
            _userName = user.displayName ?? 'User';
            _userEmail = user.email ?? '';
          });
        }
      }
    } catch (e) {
      // Error loading user name - continue with default
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isVerySmall = screenWidth < 500;
        // Ẩn tên người dùng khi màn hình < 1100px để tránh overflow
        final shouldShowName = screenWidth >= 1100;
        final isMedium = screenWidth < 1200;
        
        // Tính toán maxWidth cho tên người dùng dựa trên screen width
        // Đảm bảo có đủ không gian cho notification icon + avatar + tên + padding
        final availableWidth = constraints.maxWidth;
        final maxNameWidth = shouldShowName 
            ? (availableWidth > 1400 ? 120.0 : availableWidth > 1200 ? 100.0 : 80.0)
            : 0.0;
        
        return AppBar(
          backgroundColor: const Color(0xFF1F2937),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isVerySmall ? 32 : 40,
                height: isVerySmall ? 32 : 40,
                decoration: BoxDecoration(
                  color: Colors.indigo[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.menu_book,
                  size: isVerySmall ? 18 : 24,
                ),
              ),
              SizedBox(width: isVerySmall ? 8 : 12),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isVerySmall ? 100 : isMedium ? 200 : 250,
                  ),
                  child: const Text(
                    'E-Learning',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            // Notification icon với constraints tối thiểu
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
            // User menu dropdown giống bên giáo viên - tăng kích thước khi full màn hình
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
        );
      },
    );
  }
}

