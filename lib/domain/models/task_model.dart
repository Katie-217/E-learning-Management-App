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
