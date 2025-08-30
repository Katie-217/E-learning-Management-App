// ========================================
// FILE: course.dart
// MÔ TẢ: Model dữ liệu cho khóa học và trạng thái khóa học
// ========================================

import 'package:hive/hive.dart';

part 'course.g.dart'; // Generated file

// ========================================
// CLASS: Course
// MÔ TẢ: Model chính cho thông tin khóa học
// ========================================
@HiveType(typeId: 0)
class Course extends HiveObject {
  // ========================================
  // CÁC TRƯỜNG DỮ LIỆU CƠ BẢN
  // MÔ TẢ: Thông tin cơ bản của khóa học
  // ========================================
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String code;

  @HiveField(3)
  final String instructor;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final int credits;

  @HiveField(6)
  final String semester;

  // ========================================
  // CÁC TRƯỜNG DỮ LIỆU TRẠNG THÁI
  // MÔ TẢ: Thông tin trạng thái và tiến độ khóa học
  // ========================================
  @HiveField(7)
  final CourseStatus status;

  @HiveField(8)
  final String imageUrl;

  @HiveField(9)
  final double progress;

  @HiveField(10)
  final int totalStudents;

  // ========================================
  // CÁC TRƯỜNG DỮ LIỆU THỜI GIAN
  // MÔ TẢ: Thông tin thời gian bắt đầu và kết thúc
  // ========================================
  @HiveField(11)
  final DateTime startDate;

  @HiveField(12)
  final DateTime endDate;

  // ========================================
  // CONSTRUCTOR: Course
  // MÔ TẢ: Khởi tạo đối tượng Course
  // ========================================
  Course({
    required this.id,
    required this.name,
    required this.code,
    required this.instructor,
    required this.description,
    required this.credits,
    required this.semester,
    required this.status,
    required this.imageUrl,
    required this.progress,
    required this.totalStudents,
    required this.startDate,
    required this.endDate,
  });

  // ========================================
  // HÀM: fromJson()
  // MÔ TẢ: Tạo Course từ dữ liệu JSON
  // ========================================
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      instructor: json['instructor'] ?? '',
      description: json['description'] ?? '',
      credits: json['credits'] ?? 0,
      semester: json['semester'] ?? '',
      status: CourseStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => CourseStatus.active,
      ),
      imageUrl: json['imageUrl'] ?? '',
      progress: (json['progress'] ?? 0).toDouble(),
      totalStudents: json['totalStudents'] ?? 0,
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
    );
  }

  // ========================================
  // HÀM: toJson()
  // MÔ TẢ: Chuyển đổi Course thành dữ liệu JSON
  // ========================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'instructor': instructor,
      'description': description,
      'credits': credits,
      'semester': semester,
      'status': status.toString().split('.').last,
      'imageUrl': imageUrl,
      'progress': progress,
      'totalStudents': totalStudents,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}

// ========================================
// ENUM: CourseStatus
// MÔ TẢ: Định nghĩa các trạng thái của khóa học
// ========================================
@HiveType(typeId: 1)
enum CourseStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  completed,
  @HiveField(2)
  paused,
  @HiveField(3)
  archived,
}
