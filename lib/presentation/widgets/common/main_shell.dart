import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sidebar_model.dart';
import 'user_menu_dropdown.dart';
import '../../screens/student/dashboard/student_dashboard_page.dart';
import '../../screens/student/course/course_page.dart';
import '../../../application/controllers/notification/notification_controller.dart';
import '../student/dashboard/app_bar/notification/notification_menu.dart';
import '../student/dashboard/app_bar/notification/notification_detail_dialog.dart';

import '../../screens/forum/student_forums_list_screen.dart';
import '../../screens/chat/student_chat_screen.dart';

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
  final NotificationController _notificationController =
      NotificationController();

  @override
  void initState() {
    super.initState();
    activeKey = 'dashboard';
    _loadUserData();
    _notificationController.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (activeKey != 'dashboard' && activeKey != 'courses') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            activeKey = 'dashboard';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _notificationController.dispose();
    super.dispose();
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
    // Ch? cho ph�p set activeKey l� 'dashboard' ho?c 'courses'
    // Profile kh�ng du?c set l�m activeKey - profile ch? m? qua Navigator.push
    if (key == 'dashboard' ||
        key == 'courses' ||
        key == 'forum' ||
        key == 'chat') {
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
      case 'chat':
        return const StudentChatScreen();
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
    final showBottomNav =
        !kIsWeb && !isWide; // ch? d�ng bottom nav cho mobile/app, tr�nh cho web
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
                offset:
                    const Offset(0, kToolbarHeight), // menu xu?t hi?n du?i icon
                icon: const Icon(Icons.menu, color: Colors.white),
                color: const Color(0xFF1F2937),
                onSelected: (value) => onSelect(value),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'dashboard',
                    child: ListTile(
                      leading:
                          Icon(Icons.dashboard_outlined, color: Colors.white70),
                      title: Text('Dashboard',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'courses',
                    child: ListTile(
                      leading:
                          Icon(Icons.menu_book_outlined, color: Colors.white70),
                      title: Text('Courses',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'forum',
                    child: ListTile(
                      leading:
                          Icon(Icons.forum_outlined, color: Colors.white70),
                      title:
                          Text('Forum', style: TextStyle(color: Colors.white)),
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
          ListenableBuilder(
            listenable: _notificationController,
            builder: (context, child) {
              return Stack(
                children: [
                  PopupMenuButton(
                    offset: const Offset(0, 50),
                    color: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    icon: const Icon(Icons.notifications_none),
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem(
                          enabled: false,
                          padding: EdgeInsets.zero,
                          child: NotificationMenu(
                            notifications:
                                _notificationController.notifications,
                            onMarkAllRead: () async {
                              await _notificationController.markAllAsRead();
                              Navigator.pop(context);
                            },
                            onNotificationTap: (notification) async {
                              await _notificationController
                                  .markAsRead(notification.id);
                              Navigator.pop(context);

                              if (context.mounted) {
                                NotificationDetailDialog.show(
                                  context,
                                  notification,
                                  () {
                                    print(
                                        'Navigate to: ${notification.relatedType} - ${notification.relatedId}');
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      ];
                    },
                  ),
                  if (_notificationController.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          _notificationController.unreadCount > 9
                              ? '9+'
                              : '${_notificationController.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          const SizedBox(width: 0),
          if (isWide) SidebarWidget(onSelect: onSelect, activeKey: activeKey),
          Expanded(
            child: _buildCurrentPage(),
          ),
        ],
      ),
      // Khi m�n h�nh h?p, hi?n th? bottom navigation d? d?i tab
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
