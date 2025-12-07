// ========================================
// FILE: notification_menu.dart
// MÔ TẢ: Dropdown menu hiển thị 4 thông báo mới nhất
// ========================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../domain/models/notification_model.dart';
import 'notification_detail_dialog.dart';

class NotificationMenu extends StatelessWidget {
  final List<NotificationModel> notifications;
  final VoidCallback onMarkAllRead;
  final Function(NotificationModel) onNotificationTap;

  const NotificationMenu({
    super.key,
    required this.notifications,
    required this.onMarkAllRead,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      width: 380,
      constraints: const BoxConstraints(maxHeight: 500),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(),
          const Divider(color: Color(0xFF374151), height: 1),

          // Notification List (SCROLLABLE)
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Color(0xFF374151), height: 1),
              itemBuilder: (context, index) {
                return _buildNotificationItem(notifications[index]);
              },
            ),
          ),

          // Footer with "View All" button
          const Divider(color: Color(0xFF374151), height: 1),
          InkWell(
            onTap: () {
              Navigator.of(context).pop(); // Close dropdown
              Navigator.of(context)
                  .pushNamed('/notifications'); // Navigate to full page
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View All Notifications',
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.blue[400],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onMarkAllRead,
                child: const Text(
                  'Mark all read',
                  style: TextStyle(color: Colors.blue, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Recent notifications (${notifications.length})',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return InkWell(
      onTap: () => onNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: notification.isRead
            ? Colors.transparent
            : const Color(0xFF1E40AF).withOpacity(0.1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getIconColor(notification.type).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIcon(notification.type),
                color: _getIconColor(notification.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assignment Title (prominent)
                  Text(
                    _getAssignmentTitle(notification),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: notification.isRead
                          ? FontWeight.w500
                          : FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Course name and time
                  FutureBuilder<String>(
                    future: _getCourseName(notification.courseId),
                    builder: (context, snapshot) {
                      final courseName = snapshot.data ?? 'Course';
                      return Row(
                        children: [
                          Flexible(
                            child: Text(
                              courseName,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            ' • ${notification.timeAgo}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Unread indicator
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, left: 8),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getAssignmentTitle(NotificationModel notification) {
    // Extract clean title: "Assignment Graded: bai1" -> "bai1"
    if (notification.title.contains(':')) {
      return notification.title.split(':').last.trim();
    }
    // If no colon, check metadata
    if (notification.metadata != null) {
      final assignmentTitle = notification.metadata!['assignmentTitle'];
      if (assignmentTitle != null) return assignmentTitle;
    }
    return notification.title;
  }

  Future<String> _getCourseName(String courseId) async {
    try {
      print('🔍 [Menu] Fetching course: $courseId');
      final doc = await FirebaseFirestore.instance
          .collection('course_of_study')
          .doc(courseId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        print('📦 [Menu] Course data: $data');
        final courseName =
            data?['name'] ?? data?['courseName'] ?? data?['title'] ?? 'Course';
        print('✅ [Menu] Course name: $courseName');
        return courseName;
      } else {
        print('❌ [Menu] Course document not found: $courseId');
      }
    } catch (e) {
      print('❌ [Menu] Error fetching course: $e');
    }
    return 'Course';
  }

  String _formatTitle(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.assignment:
        return 'New Assignment: ${notification.title}';
      case NotificationType.quiz:
        return 'New Quiz: ${notification.title}';
      case NotificationType.announcement:
        return 'New Material: ${notification.title}';
      case NotificationType.grade:
        return 'Grade Released: ${notification.title}';
      case NotificationType.general:
        if (notification.title.contains('Submission')) {
          return 'Submission Successful: ${notification.content}';
        }
        return notification.title;
      default:
        return notification.title;
    }
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.assignment:
        return Icons.assignment;
      case NotificationType.quiz:
        return Icons.quiz;
      case NotificationType.announcement:
        return Icons.folder;
      case NotificationType.grade:
        return Icons.grade;
      default:
        return Icons.check_circle;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.assignment:
        return Colors.blue;
      case NotificationType.quiz:
        return Colors.green;
      case NotificationType.announcement:
        return Colors.orange;
      case NotificationType.grade:
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }
}
