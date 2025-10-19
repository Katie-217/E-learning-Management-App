
// // Model dữ liệu cho khóa học và trạng thái khóa học


// import 'package:hive/hive.dart';

// part 'course.g.dart'; // Generated file


// //  Model chính cho thông tin khóa học

// @HiveType(typeId: 0)
// class CourseModel extends HiveObject {
//   @HiveField(0)
//   final String id;

//   @HiveField(1)
//   final String name;

//   @HiveField(2)
//   final String code;

//   @HiveField(3)
//   final String instructor;

//   @HiveField(4)
//   final String description;

//   @HiveField(5)
//   final int credits;

//   @HiveField(6)
//   final String semester;

//   @HiveField(7)
//   final CourseStatus status;

//   @HiveField(8)
//   final String imageUrl;

//   @HiveField(9)
//   final double progress;

//   @HiveField(10)
//   final int totalStudents;

//   @HiveField(11)
//   final DateTime startDate;

//   @HiveField(12)
//   final DateTime endDate;

//   CourseModel({
//     required this.id,
//     required this.name,
//     required this.code,
//     required this.instructor,
//     required this.description,
//     required this.credits,
//     required this.semester,
//     required this.status,
//     required this.imageUrl,
//     required this.progress,
//     required this.totalStudents,
//     required this.startDate,
//     required this.endDate,
//   });

//   factory CourseModel.fromJson(Map<String, dynamic> json) {
//     return CourseModel(
//       id: json['id'] ?? '',
//       name: json['name'] ?? '',
//       code: json['code'] ?? '',
//       instructor: json['instructor'] ?? '',
//       description: json['description'] ?? '',
//       credits: json['credits'] ?? 0,
//       semester: json['semester'] ?? '',
//       status: CourseStatus.values.firstWhere(
//         (e) => e.toString().split('.').last == json['status'],
//         orElse: () => CourseStatus.active,
//       ),
//       imageUrl: json['imageUrl'] ?? '',
//       progress: (json['progress'] ?? 0).toDouble(),
//       totalStudents: json['totalStudents'] ?? 0,
//       startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
//       endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'code': code,
//       'instructor': instructor,
//       'description': description,
//       'credits': credits,
//       'semester': semester,
//       'status': status.toString().split('.').last,
//       'imageUrl': imageUrl,
//       'progress': progress,
//       'totalStudents': totalStudents,
//       'startDate': startDate.toIso8601String(),
//       'endDate': endDate.toIso8601String(),
//     };
//   }
// }

// @HiveType(typeId: 1)
// enum CourseStatus {
//   @HiveField(0)
//   active,
//   @HiveField(1)
//   completed,
//   @HiveField(2)
//   paused,
//   @HiveField(3)
//   archived,
// }

// // Alias for backward compatibility
// typedef Course = CourseModel;

import 'package:flutter/material.dart';

class CourseModel {
  final int id;
  final String code;
  final String name;
  final String instructor;
  final String semester;
  final int sessions;
  final int students;
  final String group;
  final List<Color> gradient;
  final int progress;
  
  // Additional properties for compatibility
  final String description;
  final int credits;
  final String imageUrl;
  final int totalStudents;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  CourseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.instructor,
    required this.semester,
    required this.sessions,
    required this.students,
    required this.group,
    required this.gradient,
    required this.progress,
    this.description = '',
    this.credits = 3,
    this.imageUrl = '',
    this.totalStudents = 0,
    DateTime? startDate,
    DateTime? endDate,
    this.status = 'active',
  }) : startDate = startDate ?? DateTime.now(),
       endDate = endDate ?? DateTime.now().add(const Duration(days: 90));

  static List<CourseModel> mockCourses = [
    CourseModel(
      id: 1,
      code: 'IT4409',
      name: 'Web Programming & Applications',
      instructor: 'Dr. Nguyen Van A',
      semester: 'Spring 2025',
      sessions: 15,
      students: 50,
      group: 'Group 1',
      gradient: [Colors.blue, Colors.cyan],
      progress: 65,
      description: 'Learn modern web development with React, Node.js, and databases',
      credits: 3,
      imageUrl: 'https://picsum.photos/400/200?random=1',
      totalStudents: 50,
      startDate: DateTime(2025, 1, 15),
      endDate: DateTime(2025, 5, 15),
      status: 'active',
    ),
    CourseModel(
      id: 2,
      code: 'IT3100',
      name: 'Database Management Systems',
      instructor: 'Dr. Tran Thi B',
      semester: 'Spring 2025',
      sessions: 15,
      students: 45,
      group: 'Group 2',
      gradient: [Colors.purple, Colors.pink],
      progress: 45,
      description: 'Database design, SQL, and database administration',
      credits: 3,
      imageUrl: 'https://picsum.photos/400/200?random=2',
      totalStudents: 45,
      startDate: DateTime(2025, 1, 15),
      endDate: DateTime(2025, 5, 15),
      status: 'active',
    ),
    CourseModel(
      id: 3,
      code: 'IT4788',
      name: 'Mobile Application Development',
      instructor: 'Dr. Le Van C',
      semester: 'Spring 2025',
      sessions: 15,
      students: 40,
      group: 'Group 1',
      gradient: [Colors.green, Colors.teal],
      progress: 80,
      description: 'Cross-platform mobile development with Flutter',
      credits: 3,
      imageUrl: 'https://picsum.photos/400/200?random=3',
      totalStudents: 40,
      startDate: DateTime(2025, 1, 15),
      endDate: DateTime(2025, 5, 15),
      status: 'active',
    ),
  ];
}
