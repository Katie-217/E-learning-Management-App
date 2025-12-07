import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sidebar_model.dart';
import 'user_menu_dropdown.dart';
import '../../screens/student/dashboard/student_dashboard_page.dart';
import '../../screens/student/course/course_page.dart';
import '../../../application/controllers/notification/notification_controller.dart';
import '../student/dashboard/app_bar/notification/notification_menu.dart';
import '../student/dashboard/app_bar/notification/notification_detail_dialog.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // LUÃ”N máº·c Ä‘á»‹nh lÃ  'dashboard' - Ä‘Ã¢y lÃ  trang Æ°u tiÃªn khi Ä‘Ã£ Ä‘Äƒng nháº­p
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
    if (key == 'dashboard' || key == 'courses') {
      setState(() {
        activeKey = key;
      });
    } else {
      // Náº¿u key khÃ´ng há»£p lá»‡, reset vá» dashboard
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
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
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
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: UserMenuDropdown(
              userName: _userName,
              userPhotoUrl: _userPhotoUrl,
              userEmail: _userEmail,
              onReturnFromProfile: () {
                // Khi quay láº¡i tá»« profile, set activeKey vá» dashboard
                // Chá»‰ thá»±c hiá»‡n náº¿u activeKey khÃ´ng pháº£i lÃ  dashboard
                if (activeKey != 'dashboard') {
                  setState(() {
                    activeKey = 'dashboard';
                  });
                }
              },
            ),
          )
        ],
      ),
      body: Row(
        children: [
          const SizedBox(width: 0),
          if (MediaQuery.of(context).size.width > 800)
            SidebarWidget(onSelect: onSelect, activeKey: activeKey),
          Expanded(
            child: _buildCurrentPage(),
          ),
        ],
      ),
    );
  }
}
