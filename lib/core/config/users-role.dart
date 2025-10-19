// ========================================
// FILE: user_role.dart
// MÔ TẢ: Định nghĩa enum và extension cho vai trò người dùng
// ========================================

import 'package:flutter/material.dart';

// ========================================
// ENUM: UserRole
// MÔ TẢ: Định nghĩa các vai trò người dùng trong hệ thống
// ========================================
enum UserRole {
  teacher,
  student,
}

// ========================================
// EXTENSION: UserRoleExtension
// MÔ TẢ: Mở rộng UserRole với các thuộc tính hiển thị
// ========================================
extension UserRoleExtension on UserRole {
  // ========================================
  // GETTER: displayName
  // MÔ TẢ: Trả về tên hiển thị của vai trò
  // ========================================
  String get displayName {
    switch (this) {
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
    }
  }

  // ========================================
  // GETTER: primaryColor
  // MÔ TẢ: Trả về màu chính cho vai trò
  // ========================================
  Color get primaryColor {
    switch (this) {
      case UserRole.teacher:
        return const Color(0xFFEC4899);
      case UserRole.student:
        return const Color(0xFF3B82F6);
    }
  }

  // ========================================
  // GETTER: icon
  // MÔ TẢ: Trả về icon đại diện cho vai trò
  // ========================================
  IconData get icon {
    switch (this) {
      case UserRole.teacher:
        return Icons.person;
      case UserRole.student:
        return Icons.people;
    }
  }

}

// ========================================
// ENUM: UserType
// MÔ TẢ: Định nghĩa các loại người dùng trong hệ thống
// ========================================
enum UserType { teacher, student }






