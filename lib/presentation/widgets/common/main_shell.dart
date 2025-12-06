import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sidebar_model.dart';
import 'user_menu_dropdown.dart';
import '../../screens/student/dashboard/student_dashboard_page.dart';
import '../../screens/student/course/course_page.dart';
import '../../screens/forum/student_forums_list_screen.dart';
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // LUÔN mặc định là 'dashboard' - đây là trang ưu tiên khi đã đăng nhập
  String activeKey = 'dashboard';
  String _userName = 'User';
  String? _userPhotoUrl;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    activeKey = 'dashboard';
    _loadUserData();
  }

  Future<void> _loadUserData() async {
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
            _userPhotoUrl = data['photoUrl'] ?? user.photoURL;
            _userEmail = data['email'] ?? user.email ?? '';
          });
        } else {
          // Fallback to Firebase Auth data
          setState(() {
            _userName = user.displayName ?? 'User';
            _userPhotoUrl = user.photoURL;
            _userEmail = user.email ?? '';
          });
        }
      }
    } catch (e) {
      // Error loading user data - continue with defaults
    }
  }

  Widget _buildUserAvatar() {
    if (_userPhotoUrl != null && _userPhotoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _userPhotoUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo, Colors.purple]),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void onSelect(String key) {
    // Chỉ cho phép set activeKey là 'dashboard' hoặc 'courses'
    // Profile không được set làm activeKey - profile chỉ mở qua Navigator.push
    if (key == 'dashboard' || key == 'courses' || key == 'forum') {
      setState(() {
        activeKey = key;
      });
    } else {
      // Nếu key không hợp lệ, reset về dashboard
      setState(() {
        activeKey = 'dashboard';
      });
    }
  }

  Widget _buildCurrentPage() {

    switch (activeKey) {
      case 'dashboard':
        return const StudentDashboardPage(showSidebar: false);
      case 'courses':
        return const CoursePage(showSidebar: false);
      case 'forum':
        return const CourseForumsListScreen(showSidebar: false);      
      default:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              activeKey = 'dashboard';
            });
          }
        });
        return const StudentDashboardPage(showSidebar: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final showBottomNav = !kIsWeb && !isWide; // chỉ dùng bottom nav cho mobile/app, tránh cho web
    int _navIndex() {
      switch (activeKey) {
        case 'dashboard':
          return 0;
        case 'courses':
          return 1;
        case 'forum':
          return 2;
        default:
          return 0;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isWide)
              PopupMenuButton<String>(
                offset: const Offset(0, kToolbarHeight), // menu xuất hiện dưới icon
                icon: const Icon(Icons.menu, color: Colors.white),
                color: const Color(0xFF1F2937),
                onSelected: (value) => onSelect(value),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'dashboard',
                    child: ListTile(
                      leading: Icon(Icons.dashboard_outlined, color: Colors.white70),
                      title: Text('Dashboard', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'courses',
                    child: ListTile(
                      leading: Icon(Icons.menu_book_outlined, color: Colors.white70),
                      title: Text('Courses', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'forum',
                    child: ListTile(
                      leading: Icon(Icons.forum_outlined, color: Colors.white70),
                      title: Text('Forum', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            const SizedBox(width: 6),
            const _AppIcon(),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'E-Learning',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          _ResponsiveSearchField(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: UserMenuDropdown(
                userName: _userName,
                userPhotoUrl: _userPhotoUrl,
                userEmail: _userEmail,
                onReturnFromProfile: () {
                  if (activeKey != 'dashboard') {
                    setState(() {
                      activeKey = 'dashboard';
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          const SizedBox(width: 0),
          if (isWide)
            SidebarWidget(onSelect: onSelect, activeKey: activeKey),
          Expanded(
            child: _buildCurrentPage(),
          ),
        ],
      ),
      // Khi màn hình hẹp, hiển thị bottom navigation để đổi tab
      bottomNavigationBar: showBottomNav
          ? BottomNavigationBar(
              backgroundColor: const Color(0xFF1F2937),
              selectedItemColor: Colors.indigo[300],
              unselectedItemColor: Colors.white70,
              currentIndex: _navIndex(),
              onTap: (index) {
                switch (index) {
                  case 0:
                    onSelect('dashboard');
                    break;
                  case 1:
                    onSelect('courses');
                    break;
                  case 2:
                    onSelect('forum');
                    break;
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_outlined),
                  label: 'Courses',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.forum_outlined),
                  label: 'Forum',
                ),
              ],
            )
          : null,
    );
  }
}

// App icon extracted for reuse and clarity
class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.indigo[600],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.menu_book, color: Colors.white),
    );
  }
}

// Responsive search field to prevent overflow in app bar
class _ResponsiveSearchField extends StatelessWidget {
  const _ResponsiveSearchField();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Reduce width on small screens and hide on very small screens
    final searchWidth = screenWidth > 1200
        ? 280.0
        : screenWidth > 900
            ? 220.0
            : screenWidth > 750
                ? 180.0
                : screenWidth > 600
                    ? 150.0
                    : screenWidth > 480
                        ? 120.0
                        : 0.0;

    if (searchWidth == 0) return const SizedBox.shrink();

    return Flexible(
      child: SizedBox(
        width: searchWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  screenWidth > 600 ? 'Search courses, materials...' : 'Search...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: const Color(0xFF111827),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
  }
}
