// ========================================
// FILE: notification_detail_dialog.dart
// MÔ TẢ: Dialog hiển thị chi tiết thông báo
// ========================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../domain/models/notification_model.dart';

// Import Timestamp type
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class NotificationDetailDialog extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onViewDetails;

  const NotificationDetailDialog({
    super.key,
    required this.notification,
    required this.onViewDetails,
  });

  static Future<void> show(
    BuildContext context,
    NotificationModel notification,
    VoidCallback onViewDetails,
  ) {
    return showDialog(
      context: context,
      builder: (context) => NotificationDetailDialog(
        notification: notification,
        onViewDetails: onViewDetails,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildContent(),
            const SizedBox(height: 24),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getIconColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getIcon(), color: _getIconColor(), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getAssignmentTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              FutureBuilder<String>(
                future: _getCourseName(),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? 'Loading...',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  );
                },
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description text
        const SizedBox(height: 8),
        Text(
          notification.content,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),

        // Show grade info if available (for graded assignments)
        if (notification.metadata?['grade'] != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.2),
                  Colors.blue.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.grade, color: Colors.green[400], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Your Grade',
                      style: TextStyle(
                        color: Colors.green[300],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${notification.metadata!['grade']}',
                      style: TextStyle(
                        color: Colors.green[300],
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / 100',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                if (notification.metadata!['feedback'] != null &&
                    notification.metadata!['feedback']
                        .toString()
                        .isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.comment,
                                color: Colors.grey[400], size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Feedback:',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.metadata!['feedback'],
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Show assignment dates for new assignment notifications
        if (notification.metadata?['dueDate'] != null) ...[
          _buildInfoRow(
            Icons.event,
            'Due Date',
            _formatDateTime(notification.metadata!['dueDate']),
            color: Colors.red[300],
          ),
        ],
        if (notification.metadata?['startDate'] != null) ...[
          _buildInfoRow(
            Icons.access_time,
            'Start Date',
            _formatDateTime(notification.metadata!['startDate']),
          ),
        ],
        if (notification.metadata?['lateDeadline'] != null) ...[
          _buildInfoRow(
            Icons.warning_amber,
            'Late Deadline',
            _formatDateTime(notification.metadata!['lateDeadline']),
            color: Colors.amber[300],
          ),
        ],

        // Group info if available
        if (notification.metadata?['groupName'] != null) ...[
          _buildInfoRow(
            Icons.group,
            'Assigned to',
            notification.metadata!['groupName'],
          ),
        ],

        // Notification time
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              notification.timeAgo,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey[400]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: TextStyle(color: Colors.grey[400])),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onViewDetails();
          },
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('View Details'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.assignment:
        return Icons.assignment;
      case NotificationType.quiz:
        return Icons.quiz;
      case NotificationType.announcement:
        return Icons.folder;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.assignment:
        return Colors.blue;
      case NotificationType.quiz:
        return Colors.green;
      case NotificationType.announcement:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getAssignmentTitle() {
    // Extract assignment title from notification title
    // Format: "Assignment Graded: assignment_title" or "New Assignment: assignment_title"
    if (notification.title.contains(':')) {
      return notification.title.split(':').last.trim();
    }
    return notification.title;
  }

  Future<String> _getCourseName() async {
    try {
      print('🔍 Fetching course: ${notification.courseId}');
      final doc = await FirebaseFirestore.instance
          .collection('course_of_study')
          .doc(notification.courseId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        print('📦 Course data: $data');
        final courseName =
            data?['name'] ?? data?['courseName'] ?? data?['title'] ?? 'Course';
        print('✅ Course name: $courseName');
        return courseName;
      } else {
        print('❌ Course document not found: ${notification.courseId}');
      }
    } catch (e) {
      print('❌ Error fetching course name: $e');
    }
    return 'Course';
  }

  String _formatDateTime(dynamic dateData) {
    try {
      if (dateData == null) return 'N/A';
      DateTime date;

      if (dateData is Timestamp) {
        // Firestore Timestamp
        date = dateData.toDate();
      } else if (dateData is String) {
        date = DateTime.parse(dateData);
      } else if (dateData is DateTime) {
        date = dateData;
      } else {
        return 'N/A';
      }

      final weekday =
          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
      final month = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][date.month - 1];
      final hour =
          date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '$weekday, $month ${date.day}, $hour:${date.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return 'N/A';
    }
  }
}
