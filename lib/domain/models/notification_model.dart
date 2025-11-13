// ========================================
// FILE: notification_model.dart
// MÔ TẢ: Model thông báo in-app cho sinh viên
// ========================================

class NotificationModel {
  final String id;
  final String userId; // Người nhận thông báo
  final String courseId;
  final String title;
  final String content;
  final NotificationType type;
  final NotificationPriority priority;
  final String? relatedId; // ID của assignment, quiz, announcement, etc.
  final String? relatedType; // 'assignment', 'quiz', 'announcement', etc.
  final String? actionUrl; // Deep link để navigate
  final String? imageUrl; // Icon hoặc hình ảnh
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? scheduledAt; // Thông báo định thời
  final bool isRead;
  final bool isArchived;
  final Map<String, dynamic>? metadata; // Thông tin thêm
  final String? createdBy; // Người tạo thông báo (instructor)

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.title,
    required this.content,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.relatedId,
    this.relatedType,
    this.actionUrl,
    this.imageUrl,
    required this.createdAt,
    this.readAt,
    this.scheduledAt,
    this.isRead = false,
    this.isArchived = false,
    this.metadata,
    this.createdBy,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      type: _parseType(map['type'] ?? 'general'),
      priority: _parsePriority(map['priority'] ?? 'normal'),
      relatedId: map['relatedId'],
      relatedType: map['relatedType'],
      actionUrl: map['actionUrl'],
      imageUrl: map['imageUrl'],
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      readAt: _parseDateTime(map['readAt']),
      scheduledAt: _parseDateTime(map['scheduledAt']),
      isRead: map['isRead'] ?? false,
      isArchived: map['isArchived'] ?? false,
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdBy: map['createdBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'courseId': courseId,
      'title': title,
      'content': content,
      'type': type.name,
      'priority': priority.name,
      'relatedId': relatedId,
      'relatedType': relatedType,
      'actionUrl': actionUrl,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'isRead': isRead,
      'isArchived': isArchived,
      'metadata': metadata,
      'createdBy': createdBy,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? courseId,
    String? title,
    String? content,
    NotificationType? type,
    NotificationPriority? priority,
    String? relatedId,
    String? relatedType,
    String? actionUrl,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? scheduledAt,
    bool? isRead,
    bool? isArchived,
    Map<String, dynamic>? metadata,
    String? createdBy,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      relatedId: relatedId ?? this.relatedId,
      relatedType: relatedType ?? this.relatedType,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // ========================================
  // GETTER: timeAgo
  // ========================================
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  // ========================================
  // GETTER: isScheduled
  // ========================================
  bool get isScheduled =>
      scheduledAt != null && scheduledAt!.isAfter(DateTime.now());

  // ========================================
  // GETTER: shouldShow
  // ========================================
  bool get shouldShow {
    if (isArchived) return false;
    if (scheduledAt != null && scheduledAt!.isAfter(DateTime.now()))
      return false;
    return true;
  }

  // ========================================
  // HÀM: markAsRead()
  // ========================================
  NotificationModel markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  // ========================================
  // HÀM: archive()
  // ========================================
  NotificationModel archive() {
    return copyWith(isArchived: true);
  }

  // ========================================
  // Factory methods for common notification types
  // ========================================

  /// Thông báo bài tập mới
  factory NotificationModel.newAssignment({
    required String userId,
    required String courseId,
    required String assignmentId,
    required String assignmentTitle,
    required DateTime dueDate,
    required String createdBy,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      courseId: courseId,
      title: 'Bài tập mới',
      content:
          'Bài tập "$assignmentTitle" đã được giao. Hạn nộp: ${_formatDate(dueDate)}',
      type: NotificationType.assignment,
      priority: NotificationPriority.high,
      relatedId: assignmentId,
      relatedType: 'assignment',
      actionUrl: '/course/$courseId/assignment/$assignmentId',
      createdAt: DateTime.now(),
      createdBy: createdBy,
      metadata: {
        'assignmentTitle': assignmentTitle,
        'dueDate': dueDate.toIso8601String(),
      },
    );
  }

  /// Thông báo quiz mới
  factory NotificationModel.newQuiz({
    required String userId,
    required String courseId,
    required String quizId,
    required String quizTitle,
    required DateTime availableAt,
    required String createdBy,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      courseId: courseId,
      title: 'Quiz mới',
      content:
          'Quiz "$quizTitle" đã sẵn sàng. Có thể làm từ: ${_formatDate(availableAt)}',
      type: NotificationType.quiz,
      priority: NotificationPriority.high,
      relatedId: quizId,
      relatedType: 'quiz',
      actionUrl: '/course/$courseId/quiz/$quizId',
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );
  }

  /// Thông báo thông báo mới
  factory NotificationModel.newAnnouncement({
    required String userId,
    required String courseId,
    required String announcementId,
    required String title,
    required String createdBy,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      courseId: courseId,
      title: 'Thông báo mới',
      content: title,
      type: NotificationType.announcement,
      priority: NotificationPriority.normal,
      relatedId: announcementId,
      relatedType: 'announcement',
      actionUrl: '/course/$courseId/stream',
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );
  }

  /// Thông báo điểm số
  factory NotificationModel.gradeReleased({
    required String userId,
    required String courseId,
    required String submissionId,
    required String assignmentTitle,
    required double score,
    required double maxScore,
    required String createdBy,
  }) {
    final percentage = (score / maxScore * 100).toStringAsFixed(1);
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      courseId: courseId,
      title: 'Điểm số mới',
      content:
          'Bài "$assignmentTitle" đã được chấm điểm: $score/$maxScore ($percentage%)',
      type: NotificationType.grade,
      priority: NotificationPriority.high,
      relatedId: submissionId,
      relatedType: 'submission',
      actionUrl: '/course/$courseId/grades',
      createdAt: DateTime.now(),
      createdBy: createdBy,
      metadata: {
        'score': score,
        'maxScore': maxScore,
        'percentage': percentage,
      },
    );
  }

  static NotificationType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return NotificationType.assignment;
      case 'quiz':
        return NotificationType.quiz;
      case 'announcement':
        return NotificationType.announcement;
      case 'grade':
        return NotificationType.grade;
      case 'reminder':
        return NotificationType.reminder;
      case 'message':
        return NotificationType.message;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.general;
    }
  }

  static NotificationPriority _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }

  static DateTime? _parseDateTime(dynamic dateData) {
    if (dateData == null) return null;
    if (dateData is DateTime) return dateData;
    try {
      return DateTime.parse(dateData.toString());
    } catch (e) {
      return null;
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() =>
      'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ========================================
// ENUM: NotificationType
// ========================================
enum NotificationType {
  general, // Thông báo chung
  assignment, // Bài tập
  quiz, // Quiz
  announcement, // Thông báo
  grade, // Điểm số
  reminder, // Nhắc nhở
  message, // Tin nhắn
  system, // Hệ thống
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.general:
        return 'Chung';
      case NotificationType.assignment:
        return 'Bài tập';
      case NotificationType.quiz:
        return 'Quiz';
      case NotificationType.announcement:
        return 'Thông báo';
      case NotificationType.grade:
        return 'Điểm số';
      case NotificationType.reminder:
        return 'Nhắc nhở';
      case NotificationType.message:
        return 'Tin nhắn';
      case NotificationType.system:
        return 'Hệ thống';
    }
  }

  String get name {
    switch (this) {
      case NotificationType.general:
        return 'general';
      case NotificationType.assignment:
        return 'assignment';
      case NotificationType.quiz:
        return 'quiz';
      case NotificationType.announcement:
        return 'announcement';
      case NotificationType.grade:
        return 'grade';
      case NotificationType.reminder:
        return 'reminder';
      case NotificationType.message:
        return 'message';
      case NotificationType.system:
        return 'system';
    }
  }
}

// ========================================
// ENUM: NotificationPriority
// ========================================
enum NotificationPriority {
  low, // Thấp
  normal, // Bình thường
  high, // Cao
  urgent, // Khẩn cấp
}

extension NotificationPriorityExtension on NotificationPriority {
  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Thấp';
      case NotificationPriority.normal:
        return 'Bình thường';
      case NotificationPriority.high:
        return 'Cao';
      case NotificationPriority.urgent:
        return 'Khẩn cấp';
    }
  }

  String get name {
    switch (this) {
      case NotificationPriority.low:
        return 'low';
      case NotificationPriority.normal:
        return 'normal';
      case NotificationPriority.high:
        return 'high';
      case NotificationPriority.urgent:
        return 'urgent';
    }
  }
}
