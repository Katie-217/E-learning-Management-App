// ========================================
// FILE: notification_repository.dart
// MÔ TẢ: Repository quản lý thông báo trong Firestore
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/notification_model.dart';

class NotificationRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'notifications';

  // ========================================
  // HÀM: getNotificationsStream - Lấy danh sách notifications real-time
  // ========================================
  static Stream<List<NotificationModel>> getNotificationsStream(
    String userId, {
    int limit = 50,
  }) {
    print(
        '🔍 NotificationRepository: Querying notifications for userId=$userId, limit=$limit');

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      print(
          '📦 NotificationRepository: Received ${snapshot.docs.length} documents');

      final notifications = snapshot.docs.map((doc) {
        try {
          return NotificationModel.fromMap({
            'id': doc.id,
            ...doc.data(),
          });
        } catch (e) {
          print('❌ Error parsing notification ${doc.id}: $e');
          rethrow;
        }
      }).toList();

      print(
          '✅ NotificationRepository: Parsed ${notifications.length} notifications');
      return notifications;
    });
  }

  // ========================================
  // HÀM: getUnreadCountStream - Đếm số thông báo chưa đọc real-time
  // ========================================
  static Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ========================================
  // HÀM: markAsRead - Đánh dấu 1 thông báo đã đọc
  // ========================================
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collectionName).doc(notificationId).update({
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: markAllAsRead - Đánh dấu tất cả thông báo đã đọc
  // ========================================
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: createNotification - Tạo notification mới
  // ========================================
  static Future<String> createNotification(
      NotificationModel notification) async {
    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .add(notification.toMap());
      return docRef.id;
    } catch (e) {
      print('❌ Error creating notification: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: deleteNotification - Xóa notification
  // ========================================
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collectionName).doc(notificationId).delete();
    } catch (e) {
      print('❌ Error deleting notification: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: archiveNotification - Lưu trữ notification
  // ========================================
  static Future<void> archiveNotification(String notificationId) async {
    try {
      await _firestore.collection(_collectionName).doc(notificationId).update({
        'isArchived': true,
      });
    } catch (e) {
      print('❌ Error archiving notification: $e');
      rethrow;
    }
  }
}
