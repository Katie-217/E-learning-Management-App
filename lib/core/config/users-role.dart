import 'package:flutter/material.dart';

enum UserRole {
  teacher,
  student,
}

//  Mở rộng UserRole với các thuộc tính hiển thị
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
    }
  }

  Color get primaryColor {
    switch (this) {
      case UserRole.teacher:
        return const Color(0xFFEC4899);
      case UserRole.student:
        return const Color(0xFF3B82F6);
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.teacher:
        return Icons.person;
      case UserRole.student:
        return Icons.people;
    }
  }

}

enum UserType { teacher, student }






