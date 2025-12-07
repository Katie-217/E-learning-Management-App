class Quiz {
  final String id;
  final String courseId; // Course ID this quiz belongs to
  final String title;
  final String
      dueDate; // Keep for backward compatibility (use closeDate if available)
  final String
      duration; // Keep for backward compatibility (use durationMinutes)
  final int questions; // Total questions count
  final String status; // 'upcoming', 'available', 'closed'
  final Map<String, int> structure; // {'easy': 5, 'medium': 3, 'hard': 2}

  // Full quiz details
  final String? description;
  final DateTime? openDate;
  final DateTime? closeDate;
  final int? durationMinutes;
  final int? maxAttempts;
  final double? points; // Total points for this quiz
  final List<String>? groupIds; // Group IDs that can access this quiz
  final bool shuffleAnswers;
  final bool showScore;
  final List<String> questionIds; // Computed from structure
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Quiz({
    required this.id,
    required this.courseId,
    required this.title,
    required this.dueDate,
    required this.duration,
    required this.questions,
    required this.status,
    this.structure = const {},
    this.description,
    this.openDate,
    this.closeDate,
    this.durationMinutes,
    this.maxAttempts,
    this.points,
    this.groupIds,
    this.shuffleAnswers = true,
    this.showScore = true,
    this.questionIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Quiz.fromMap(String id, Map<String, dynamic> m) {
    // Calculate total questions from structure
    int totalQuestions = 0;
    if (m['structure'] != null) {
      final structure = Map<String, int>.from(m['structure'] as Map);
      totalQuestions =
          structure.values.fold<int>(0, (sum, count) => sum + count);
    }

    return Quiz(
      id: id,
      courseId: m['courseId'] ?? '',
      title: m['title'] ?? '',
      dueDate: m['dueDate'] ?? m['closeDate'] ?? '',
      duration: m['duration'] ?? '${m['durationMinutes'] ?? 45} mins',
      questions: totalQuestions,
      status: m['status'] ?? 'upcoming',
      structure: m['structure'] != null
          ? Map<String, int>.from(m['structure'] as Map)
          : {},
      description: m['description'],
      openDate: _parseDateTime(m['openDate']),
      closeDate: _parseDateTime(m['closeDate']),
      durationMinutes: m['durationMinutes'],
      maxAttempts: m['maxAttempts'],
      points: m['points'] != null ? (m['points'] as num).toDouble() : null,
      groupIds: m['groupIds'] != null
          ? List<String>.from(m['groupIds'] as List)
          : null,
      shuffleAnswers: m['shuffleAnswers'] ?? true,
      showScore: m['showScore'] ?? true,
      questionIds: m['questionIds'] != null
          ? List<String>.from(m['questionIds'] as List)
          : [],
      createdAt: _parseDateTime(m['createdAt']),
      updatedAt: _parseDateTime(m['updatedAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'openDate': openDate?.toIso8601String(),
      'closeDate': closeDate?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'maxAttempts': maxAttempts,
      'points': points,
      'structure': structure,
      'questionIds': questionIds,
      'shuffleAnswers': shuffleAnswers,
      'showScore': showScore,
      'groupIds': groupIds,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Quiz copyWith({
    String? id,
    String? courseId,
    String? title,
    String? dueDate,
    String? duration,
    int? questions,
    String? status,
    Map<String, int>? structure,
    String? description,
    DateTime? openDate,
    DateTime? closeDate,
    int? durationMinutes,
    int? maxAttempts,
    double? points,
    List<String>? groupIds,
    bool? shuffleAnswers,
    bool? showScore,
    List<String>? questionIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      duration: duration ?? this.duration,
      questions: questions ?? this.questions,
      status: status ?? this.status,
      structure: structure ?? this.structure,
      description: description ?? this.description,
      openDate: openDate ?? this.openDate,
      closeDate: closeDate ?? this.closeDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      points: points ?? this.points,
      groupIds: groupIds ?? this.groupIds,
      shuffleAnswers: shuffleAnswers ?? this.shuffleAnswers,
      showScore: showScore ?? this.showScore,
      questionIds: questionIds ?? this.questionIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper: Total questions computed from structure
  int get totalQuestions {
    return structure.values.fold<int>(0, (sum, count) => sum + count);
  }

  // Helper: Can start quiz now
  bool get canStartNow {
    if (openDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(openDate!) &&
        (closeDate == null || now.isBefore(closeDate!));
  }

  @override
  String toString() {
    return 'Quiz(id: $id, title: $title, status: $status)';
  }
}
