import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentModel {
  final String id;
  final String courseId;
  final String userId;

  // Dữ liệu dư thừa (Snapshot) để hiển thị nhanh danh sách mà không cần query User
  final String? studentName;
  final String? studentEmail;

  final DateTime enrolledAt;
  final String role; // 'student', 'teacher'
  final String status; // 'active', 'dropped'
  final String groupId; // ID của nhóm - SINGLE SOURCE OF TRUTH - REQUIRED!

  EnrollmentModel({
    required this.id,
    required this.courseId,
    required this.userId,
    this.studentName,
    this.studentEmail,
    required this.enrolledAt,
    this.role = 'student',
    this.status = 'active',
    required this.groupId, // REQUIRED - sinh viên CHỈ có thể enroll khi đã chọn nhóm
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'userId': userId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'enrolledAt': enrolledAt.toIso8601String(), // Hoặc dùng Timestamp
      'role': role,
      'groupId': groupId, // Nơi lưu groupId assignment
      'status': status,
    };
  }

  factory EnrollmentModel.fromMap(String id, Map<String, dynamic> map) {
    return EnrollmentModel(
      id: id,
      courseId: map['courseId'] ?? '',
      userId: map['userId'] ?? '',
      studentName: map['studentName'],
      studentEmail: map['studentEmail'],
      enrolledAt: _parseDateTime(map['enrolledAt']),
      role: map['role'] ?? 'student',
      status: map['status'] ?? 'active',
      groupId: map['groupId'] ?? '', // REQUIRED - must have groupId
    );
  }

  // Helper method để handle cả Timestamp và String
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();

    // Nếu là Firestore Timestamp
    if (dateTime is Timestamp) {
      return dateTime.toDate();
    }

    // Nếu là String
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return DateTime.now();
      }
    }

    // Nếu đã là DateTime
    if (dateTime is DateTime) {
      return dateTime;
    }

    // Default fallback
    return DateTime.now();
  }

  // ========================================
  // METHOD: copyWith - For group assignment changes
  // ========================================
  EnrollmentModel copyWith({
    String? id,
    String? courseId,
    String? userId,
    String? studentName,
    String? studentEmail,
    DateTime? enrolledAt,
    String? role,
    String? status,
    String? groupId, // Can change group but cannot be null/empty
  }) {
    return EnrollmentModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      userId: userId ?? this.userId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      role: role ?? this.role,
      status: status ?? this.status,
      groupId: groupId ?? this.groupId,
    );
  }

  // ========================================
  // HELPER: generateId - Composite ID for uniqueness
  // ========================================
  static String generateId({
    required String courseId,
    required String userId,
  }) {
    return '${courseId}_${userId}';
  }
}
