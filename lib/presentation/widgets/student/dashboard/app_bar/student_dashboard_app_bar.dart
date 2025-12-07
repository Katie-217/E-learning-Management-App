import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../../application/controllers/notification/notification_controller.dart';
import 'notification/notification_menu.dart';
import 'notification/notification_detail_dialog.dart';

class StudentDashboardAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  const StudentDashboardAppBar({super.key});

  @override
  State<StudentDashboardAppBar> createState() => _StudentDashboardAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _StudentDashboardAppBarState extends State<StudentDashboardAppBar> {
  final NotificationController _notificationController =
      NotificationController();

  @override
  void initState() {
    super.initState();
    _notificationController.init();
  }

  @override
  void dispose() {
    _notificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
            child: const Icon(Icons.menu_book),
          ),
          const SizedBox(width: 12),
          const Text(
            'E-Learning',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        // Notification Bell
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
                    print('ðŸ”” Building menu items');
                    print(
                        'ðŸ”” Notifications count: ${_notificationController.notifications.length}');

                    return [
                      PopupMenuItem(
                        enabled: false,
                        padding: EdgeInsets.zero,
                        child: NotificationMenu(
                          notifications: _notificationController.notifications,
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
                                  // TODO: Navigate to related content
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
        // User Profile
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient:
                      LinearGradient(colors: [Colors.indigo, Colors.purple]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getUserInitial(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getUserName(),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0] ?? 'Student';
  }

  String _getUserInitial() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email ?? 'S';
    return name.isNotEmpty ? name[0].toUpperCase() : 'S';
  }
}
