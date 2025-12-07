// ========================================
// FILE: forum_models.dart
// DESCRIPTION: Simplified Forum Models - Only Core Requirements
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';

// ========================================
// ForumTopicModel - Core fields only
// ========================================
class ForumTopicModel {
  final String id;
  final String courseId;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final int replyCount;
  final DateTime? lastReplyAt;
  final List<String> attachments; // File URLs

  const ForumTopicModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.replyCount = 0,
    this.lastReplyAt,
    this.attachments = const [],
  });

  factory ForumTopicModel.fromMap(String id, Map<String, dynamic> map) {
    return ForumTopicModel(
      id: id,
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Unknown',
      createdAt: _parseDateTime(map['createdAt']),
      replyCount: map['replyCount'] ?? 0,
      lastReplyAt: _parseDateTime(map['lastReplyAt']),
      attachments: List<String>.from(map['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'replyCount': replyCount,
      'lastReplyAt': lastReplyAt != null ? Timestamp.fromDate(lastReplyAt!) : null,
      'attachments': attachments,
    };
  }

  // Helper to display "2 days ago"
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} năm trước';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} tháng trước';
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    try {
      return DateTime.parse(val.toString());
    } catch (e) {
      return DateTime.now();
    }
  }
}

// ========================================
// ForumReplyModel - Core fields only
// ========================================
class ForumReplyModel {
  final String id;
  final String topicId;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final List<String> attachments; // File URLs

  const ForumReplyModel({
    required this.id,
    required this.topicId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.attachments = const [],
  });

  factory ForumReplyModel.fromMap(String id, Map<String, dynamic> map) {
    return ForumReplyModel(
      id: id,
      topicId: map['topicId'] ?? '',
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Unknown',
      createdAt: ForumTopicModel._parseDateTime(map['createdAt']),
      attachments: List<String>.from(map['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'attachments': attachments,
    };
  }
  
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }
}