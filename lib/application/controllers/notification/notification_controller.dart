// ========================================
// FILE: notification_controller.dart
// MÔ TẢ: Controller quản lý state notifications (Stream-based)
// ========================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/notification/notification_repository.dart';
import '../../../domain/models/notification_model.dart';

class NotificationController extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  List<NotificationModel> _allNotifications = []; // For full notifications page
  int _unreadCount = 0;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _allNotificationsSubscription;
  StreamSubscription? _unreadCountSubscription;

  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get allNotifications => _allNotifications;
  int get unreadCount => _unreadCount;

  // ========================================
  // HÀM: init - Lắng nghe real-time notifications (for dropdown menu)
  // ========================================
  void init() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ NotificationController: No user logged in');
      return;
    }

    print('✅ NotificationController: Initializing for user ${user.uid}');

    // Listen to recent 4 notifications for dropdown menu
    _notificationSubscription = NotificationRepository.getNotificationsStream(
      user.uid,
      limit: 4,
    ).listen((notifications) {
      print(
          '📬 NotificationController: Received ${notifications.length} notifications');
      _notifications = notifications;
      notifyListeners();
    }, onError: (error) {
      print('❌ NotificationController: Stream error - $error');
    });

    // Listen to unread count stream
    _unreadCountSubscription =
        NotificationRepository.getUnreadCountStream(user.uid).listen((count) {
      print('🔢 NotificationController: Unread count = $count');
      _unreadCount = count;
      notifyListeners();
    }, onError: (error) {
      print('❌ NotificationController: Unread count error - $error');
    });
  }

  // ========================================
  // HÀM: initAllNotifications - Lắng nghe ALL notifications (for full page)
  // ========================================
  void initAllNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ NotificationController: No user logged in');
      return;
    }

    print(
        '✅ NotificationController: Loading all notifications for user ${user.uid}');

    // Listen to ALL notifications (up to 100)
    _allNotificationsSubscription =
        NotificationRepository.getNotificationsStream(
      user.uid,
      limit: 100,
    ).listen((notifications) {
      print(
          '📬 NotificationController: Loaded ${notifications.length} total notifications');
      _allNotifications = notifications;
      notifyListeners();
    }, onError: (error) {
      print('❌ NotificationController: All notifications error - $error');
    });
  }

  // ========================================
  // HÀM: markAsRead
  // ========================================
  Future<void> markAsRead(String notificationId) async {
    await NotificationRepository.markAsRead(notificationId);
    // State sẽ tự động update qua stream
  }

  // ========================================
  // HÀM: markAllAsRead
  // ========================================
  Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await NotificationRepository.markAllAsRead(user.uid);
    // State sẽ tự động update qua stream
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _allNotificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    super.dispose();
  }
}
