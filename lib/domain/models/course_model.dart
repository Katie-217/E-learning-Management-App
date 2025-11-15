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
  final int progress;

  // Additional properties for compatibility
  final String description;
  final int credits;
  final String imageUrl;
  final String status;
  final int maxCapacity; // Maximum number of students allowed

  CourseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.instructor,
    required this.semester,
    required this.sessions,
    required this.progress,
    this.description = '',
    this.credits = 3,
    this.imageUrl = '',
    this.status = 'active',
    this.maxCapacity = 50, // Default capacity
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
      progress: json['progress'] ?? 0,
      description: json['description'] ?? '',
      credits: json['credits'] ?? 3,
      imageUrl: json['imageUrl'] ?? '',
      status: json['status'] ?? 'active',
      maxCapacity: json['maxCapacity'] ?? 50,
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
      progress: _parseProgress(data['progress']),
      description: data['description'] ?? '',
      credits: data['credits'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      status: data['status'] ?? '',
      maxCapacity: data['maxCapacity'] ?? 50,
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
      'progress': progress,
      'description': description,
      'credits': credits,
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
      'progress': progress,
      'description': description,
      'credits': credits,
      'imageUrl': imageUrl,
      'status': status,
    };
  }

  // Helper method để parse progress từ string hoặc number
  static int _parseProgress(dynamic progressData) {
    if (progressData == null) {
      return 0;
    }
    if (progressData is int) {
      return progressData;
    }
    if (progressData is String) {
      return int.tryParse(progressData) ?? 0;
    }
    return 0;
  }

  CourseModel copyWith({
    String? id,
    String? code,
    String? name,
    String? instructor,
    String? semester,
    int? sessions,
    int? progress,
    String? description,
    int? credits,
    String? imageUrl,
    int? maxCapacity,
    String? status,
  }) {
    return CourseModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      instructor: instructor ?? this.instructor,
      semester: semester ?? this.semester,
      sessions: sessions ?? this.sessions,
      progress: progress ?? this.progress,
      description: description ?? this.description,
      credits: credits ?? this.credits,
      status: status ?? this.status,
      maxCapacity: maxCapacity ?? this.maxCapacity,
    );
  }
}
