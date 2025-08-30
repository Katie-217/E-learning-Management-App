// ========================================
// FILE: instructor_dashboard.dart
// MÔ TẢ: Màn hình dashboard cho giáo viên
// ========================================

import 'package:flutter/material.dart';

// ========================================
// CLASS: InstructorDashboardPage
// MÔ TẢ: Widget chính cho màn hình dashboard của giáo viên
// ========================================
class InstructorDashboardPage extends StatelessWidget {
  // ========================================
  // CONSTRUCTOR: InstructorDashboardPage
  // MÔ TẢ: Khởi tạo trang dashboard giáo viên
  // ========================================
  const InstructorDashboardPage({super.key});

  // ========================================
  // HÀM: build()
  // MÔ TẢ: Xây dựng giao diện dashboard giáo viên
  // ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ========================================
      // PHẦN: AppBar
      // MÔ TẢ: Thanh tiêu đề của màn hình
      // ========================================
      appBar: AppBar(title: const Text('Instructor Dashboard')),
      // ========================================
      // PHẦN: Body
      // MÔ TẢ: Nội dung chính của màn hình
      // ========================================
      body: const Center(
        child: Text('Courses, Groups, Stats Chart'),
      ),
    );
  }
}












