import 'package:cloud_firestore/cloud_firestore.dart';

// ========================================
// COURSE MODEL - CLEANED VERSION
// ========================================
// NOTE: Student management logic has been moved to EnrollmentRepository/EnrollmentController
// This model no longer handles student lists or counts
// Use EnrollmentRepository.countStudentsInCourse() for student count
// Use EnrollmentRepository.getStudentsInCourse() for student list
// ========================================

class CourseModel {
  final String id;
  final String code;
  final String name;
  final String instructor;
  final String semester;
  final int sessions;

  // Additional properties for compatibility
  final String description;
  final String imageUrl;
  final String status;

  CourseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.instructor,
    required this.semester,
    required this.sessions,
    this.description = '',
    this.imageUrl = '',
    this.status = 'active',
  });

  // Factory constructor để tạo từ JSON (cho API calls)
  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      instructor: json['instructor'] ?? '',
      semester: json['semester'] ?? '',
      sessions: json['session'] ?? 0,
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      status: json['status'] ?? 'active',
    );
  }

  // Factory constructor để tạo từ Firestore DocumentSnapshot
  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse sessions - support multiple field names
    int sessionsCount = _parseSessions(data);

    return CourseModel(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      instructor: data['teacherName'] ?? data['instructor'] ?? '',
      semester: data['semester'] ?? '',
      sessions: sessionsCount,
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      status: data['status'] ?? 'active',
    );
  }

  // Helper method để parse sessions từ nhiều field names
  static int _parseSessions(Map<String, dynamic> data) {
    // Try multiple field names
    if (data['sessions'] != null) {
      final value = data['sessions'];
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
    }
    if (data['session'] != null) {
      final value = data['session'];
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
    }
    if (data['totalSessions'] != null) {
      final value = data['totalSessions'];
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
    }
    if (data['numberOfSessions'] != null) {
      final value = data['numberOfSessions'];
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Method để convert thành JSON (cho API calls)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'instructor': instructor,
      'semester': semester,
      'sessions': sessions,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
    };
  }

  // Method để convert thành Map cho Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'name': name,
      'instructor': instructor,
      'semester': semester,
      'sessions': sessions,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
    };
  }

  CourseModel copyWith({
    String? id,
    String? code,
    String? name,
    String? instructor,
    String? semester,
    int? sessions,
    String? description,
    String? imageUrl,
    String? status,
  }) {
    return CourseModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      instructor: instructor ?? this.instructor,
      semester: semester ?? this.semester,
      sessions: sessions ?? this.sessions,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
    );
  }
}
