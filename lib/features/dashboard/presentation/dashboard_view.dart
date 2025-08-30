// ========================================
// FILE: dashboard_view.dart
// MÔ TẢ: Màn hình dashboard chung cho ứng dụng
// ========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ========================================
// CLASS: DashboardView
// MÔ TẢ: Widget chính cho màn hình dashboard
// ========================================
class DashboardView extends StatelessWidget {
  // ========================================
  // CONSTRUCTOR: DashboardView
  // MÔ TẢ: Khởi tạo trang dashboard
  // ========================================
  const DashboardView({super.key});

  // ========================================
  // HÀM: build()
  // MÔ TẢ: Xây dựng giao diện dashboard
  // ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ========================================
      // PHẦN: AppBar
      // MÔ TẢ: Thanh tiêu đề với nút profile
      // ========================================
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
          )
        ],
      ),
      // ========================================
      // PHẦN: Body
      // MÔ TẢ: Nội dung chính của dashboard
      // ========================================
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Welcome! This is the skeleton Dashboard.'),
          SizedBox(height: 12),
          Text('Add role-based Instructor/Student sections here.'),
        ],
      ),
    );
  }
}












