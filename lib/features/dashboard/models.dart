// ========================================
// FILE: models.dart
// MÔ TẢ: Các model dữ liệu dùng cho Dashboard giảng viên
// ========================================

class Semester {
  final String id;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;

  Semester({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      startDate: _parseDateTime(json['startDate']),
      endDate: _parseDateTime(json['endDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

class DashboardStats {
  final int totalStudents;
  final int totalGroups;
  final int totalCourses;
  final int totalAssignments;
  final int totalQuizzes;

  DashboardStats({
    required this.totalStudents,
    required this.totalGroups,
    required this.totalCourses,
    required this.totalAssignments,
    required this.totalQuizzes,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return DashboardStats(
      totalStudents: _toInt(json['totalStudents']),
      totalGroups: _toInt(json['totalGroups']),
      totalCourses: _toInt(json['totalCourses']),
      totalAssignments: _toInt(json['totalAssignments']),
      totalQuizzes: _toInt(json['totalQuizzes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalStudents': totalStudents,
      'totalGroups': totalGroups,
      'totalCourses': totalCourses,
      'totalAssignments': totalAssignments,
      'totalQuizzes': totalQuizzes,
    };
  }
}


