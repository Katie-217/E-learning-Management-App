import 'package:flutter/material.dart';

enum UserRole {
  instructor, // Thay đổi từ teacher thành instructor để nhất quán
  student,
}

//  Mở rộng UserRole với các thuộc tính hiển thị
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.instructor:
        return 'Instructor';
      case UserRole.student:
        return 'Student';
    }
  }

  Color get primaryColor {
    switch (this) {
      case UserRole.instructor:
        return const Color(0xFFEC4899);
      case UserRole.student:
        return const Color(0xFF3B82F6);
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.instructor:
        return Icons.person;
      case UserRole.student:
        return Icons.people;
    }
  }
}

enum UserType { teacher, student }
