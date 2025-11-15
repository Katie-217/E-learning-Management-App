import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String code;
  final String name;
  final String instructor;
  final String semester;
  final int sessions;
  final int students;
  final int progress;

  // Additional properties for compatibility
  final String description;
  final int credits;
  final String imageUrl;
  final String status;
  final int maxCapacity; // Maximum number of students allowed

  // Computed properties (no longer stored fields)
  int get totalStudents =>
      students; // Dynamic calculation from actual enrolled students

  CourseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.instructor,
    required this.semester,
    required this.sessions,
    required this.students,
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
      students: json['students'] ?? 0,
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

    return CourseModel(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      instructor: data['teacherName'] ?? data['instructor'] ?? '',
      semester: data['semester'] ?? '',
      sessions: data['session'] ?? 0,
      students: (data['students'] as List<dynamic>?)?.length ?? 0,
      progress: _parseProgress(data['progress']),
      description: data['description'] ?? '',
      credits: data['credits'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      status: data['status'] ?? '',
      maxCapacity: data['maxCapacity'] ?? 50,
    );
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
      'students': students,
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
      'students': students,
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
    int? students,
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
      students: students ?? this.students,
      progress: progress ?? this.progress,
      description: description ?? this.description,
      credits: credits ?? this.credits,
      status: status ?? this.status,
      maxCapacity: maxCapacity ?? this.maxCapacity,
    );
  }
}
