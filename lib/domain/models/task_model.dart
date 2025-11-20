import 'dart:math';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final bool isPriority;
  final String? courseId;
  final String? courseName;
  final TaskType type;
  final bool isCompleted;
  final List<String> groupsApplied;
  final int submittedCount;
  final int totalCount;
  final int lateCount;
  final int notSubmittedCount;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.isPriority = false,
    this.courseId,
    this.courseName,
    this.type = TaskType.other,
    this.isCompleted = false,
    this.groupsApplied = const [],
    this.submittedCount = 0,
    this.totalCount = 0,
    this.lateCount = 0,
    this.notSubmittedCount = 0,
  });

  factory TaskModel.fromMap(String id, Map<String, dynamic> map) {
    // Handle both 'date' and 'dateTime' fields from API
    DateTime dateTime;
    if (map['dateTime'] != null) {
      dateTime = map['dateTime'] is DateTime
          ? map['dateTime']
          : DateTime.parse(map['dateTime'].toString());
    } else if (map['date'] != null) {
      dateTime = map['date'] is DateTime
          ? map['date']
          : DateTime.parse(map['date'].toString());
    } else {
      dateTime = DateTime.now();
    }

    return TaskModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? map['title'] ?? '',
      dateTime: dateTime,
      isPriority: map['isPriority'] ?? false,
      courseId: map['courseId'],
      courseName: map['courseName'],
      type: TaskType.fromString(map['type'] ?? 'other'),
      isCompleted: map['isCompleted'] ?? false,
      groupsApplied: (map['groupApplied'] as List? ??
                  map['groupsApplied'] as List?)
              ?.map((group) => group.toString())
              .toList() ??
          const [],
      submittedCount: (map['submittedCount'] as num?)?.toInt() ?? 0,
      totalCount: (map['totalCount'] as num?)?.toInt() ?? 0,
      lateCount: (map['lateCount'] as num?)?.toInt() ?? 0,
      notSubmittedCount: (map['notSubmittedCount'] as num?)?.toInt() ??
          max(
            0,
            ((map['totalCount'] as num?)?.toInt() ?? 0) -
                ((map['submittedCount'] as num?)?.toInt() ?? 0),
          ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': dateTime.toIso8601String(), // API expects 'date' field
      'dateTime': dateTime.toIso8601String(), // Also include for compatibility
      'isPriority': isPriority,
      'courseId': courseId,
      'courseName': courseName,
      'type': type.toString().split('.').last,
      'isCompleted': isCompleted,
      'groupApplied': groupsApplied,
      'submittedCount': submittedCount,
      'totalCount': totalCount,
      'lateCount': lateCount,
      'notSubmittedCount': notSubmittedCount,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    bool? isPriority,
    String? courseId,
    String? courseName,
    TaskType? type,
    bool? isCompleted,
    List<String>? groupsApplied,
    int? submittedCount,
    int? totalCount,
    int? lateCount,
    int? notSubmittedCount,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      isPriority: isPriority ?? this.isPriority,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      groupsApplied: groupsApplied ?? this.groupsApplied,
      submittedCount: submittedCount ?? this.submittedCount,
      totalCount: totalCount ?? this.totalCount,
      lateCount: lateCount ?? this.lateCount,
      notSubmittedCount: notSubmittedCount ?? this.notSubmittedCount,
    );
  }
}

enum TaskType {
  assignment,
  quiz,
  exam,
  deadline,
  other;

  static TaskType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'assignment':
        return TaskType.assignment;
      case 'quiz':
        return TaskType.quiz;
      case 'exam':
        return TaskType.exam;
      case 'deadline':
        return TaskType.deadline;
      default:
        return TaskType.other;
    }
  }
}
