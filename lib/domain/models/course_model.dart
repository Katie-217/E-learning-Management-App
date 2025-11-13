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
      totalStudents: json['totalStudents'] ?? 0,
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : DateTime.now(),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : DateTime.now().add(const Duration(days: 90)),
      status: json['status'] ?? 'active',
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
      totalStudents: (data['students'] as List<dynamic>?)?.length ?? 0,
      startDate: data['startDate'] != null 
          ? (data['startDate'] as Timestamp).toDate() 
          : DateTime.now(),
      endDate: data['endDate'] != null 
          ? (data['endDate'] as Timestamp).toDate() 
          : DateTime.now(),
      status: data['status'] ?? '',
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
      'totalStudents': totalStudents,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
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
      'totalStudents': totalStudents,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
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
    int? totalStudents,
    DateTime? startDate,
    DateTime? endDate,
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
      totalStudents: totalStudents ?? this.totalStudents,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }

}
