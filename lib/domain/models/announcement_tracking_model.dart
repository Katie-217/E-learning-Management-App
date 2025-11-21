// ========================================
// FILE: announcement_tracking_model.dart
// MÔ TẢ: Model theo dõi lịch sử xem và tải thông báo của sinh viên
// COLLECTION: announcementTracking (Root Collection)
// PURPOSE: Track "WHO has viewed" và "WHO has downloaded" Announcements
// DESIGN: Composite ID pattern cho performance tối ưu
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementTrackingModel {
  final String id; // Composite ID: [announcementId]_[studentId]
  final String announcementId; // ID của Announcement đã tương tác
  final String studentId; // ID của sinh viên - trả lời "WHO"
  final String courseId; // Denormalized - ID của Course
  final String
      groupId; // ✅ QUAN TRỌNG: Denormalized - ID nhóm sinh viên (cho UI thống kê)
  final bool hasViewed; // Theo dõi "who has viewed"
  final bool hasDownloaded; // Theo dõi "who has downloaded attached files"
  final DateTime lastViewedAt; // Timestamp xem cuối cùng
  final DateTime? lastDownloadedAt; // Optional - chỉ có khi đã download

  const AnnouncementTrackingModel({
    required this.id,
    required this.announcementId,
    required this.studentId,
    required this.courseId,
    required this.groupId,
    this.hasViewed = false,
    this.hasDownloaded = false,
    required this.lastViewedAt,
    this.lastDownloadedAt,
  });

  // ========================================
  // HÀM: generateId() - STATIC UTILITY
  // MÔ TẢ: Tạo composite ID cho tracking document
  // PERFORMANCE: Cho phép upsert siêu nhanh
  // ========================================
  static String generateId({
    required String announcementId,
    required String studentId,
  }) {
    return '${announcementId}_$studentId';
  }

  // ========================================
  // HÀM: fromFirestore()
  // MÔ TẢ: Tạo AnnouncementTrackingModel từ Firestore DocumentSnapshot
  // ========================================
  factory AnnouncementTrackingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AnnouncementTrackingModel(
      id: doc.id,
      announcementId: data['announcementId'] ?? '',
      studentId: data['studentId'] ?? '',
      courseId: data['courseId'] ?? '',
      groupId: data['groupId'] ?? '',
      hasViewed: data['hasViewed'] ?? false,
      hasDownloaded: data['hasDownloaded'] ?? false,
      lastViewedAt:
          AnnouncementTrackingModel._parseDateTime(data['lastViewedAt']) ??
              DateTime.now(),
      lastDownloadedAt:
          AnnouncementTrackingModel._parseDateTime(data['lastDownloadedAt']),
    );
  }

  // ========================================
  // HÀM: fromMap()
  // MÔ TẢ: Tạo AnnouncementTrackingModel từ Map
  // ========================================
  factory AnnouncementTrackingModel.fromMap(Map<String, dynamic> map) {
    return AnnouncementTrackingModel(
      id: map['id'] ?? '',
      announcementId: map['announcementId'] ?? '',
      studentId: map['studentId'] ?? '',
      courseId: map['courseId'] ?? '',
      groupId: map['groupId'] ?? '',
      hasViewed: map['hasViewed'] ?? false,
      hasDownloaded: map['hasDownloaded'] ?? false,
      lastViewedAt:
          AnnouncementTrackingModel._parseDateTime(map['lastViewedAt']) ??
              DateTime.now(),
      lastDownloadedAt:
          AnnouncementTrackingModel._parseDateTime(map['lastDownloadedAt']),
    );
  }

  // ========================================
  // HÀM: toMap()
  // MÔ TẢ: Chuyển AnnouncementTrackingModel thành Map để lưu Firebase
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      'announcementId': announcementId,
      'studentId': studentId,
      'courseId': courseId,
      'groupId': groupId,
      'hasViewed': hasViewed,
      'hasDownloaded': hasDownloaded,
      'lastViewedAt': Timestamp.fromDate(lastViewedAt),
      'lastDownloadedAt': lastDownloadedAt != null
          ? Timestamp.fromDate(lastDownloadedAt!)
          : null,
    };
  }

  // ========================================
  // HÀM: copyWith()
  // MÔ TẢ: Tạo bản sao với một số field thay đổi
  // ========================================
  AnnouncementTrackingModel copyWith({
    String? id,
    String? announcementId,
    String? studentId,
    String? courseId,
    String? groupId,
    bool? hasViewed,
    bool? hasDownloaded,
    DateTime? lastViewedAt,
    DateTime? lastDownloadedAt,
  }) {
    return AnnouncementTrackingModel(
      id: id ?? this.id,
      announcementId: announcementId ?? this.announcementId,
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      groupId: groupId ?? this.groupId,
      hasViewed: hasViewed ?? this.hasViewed,
      hasDownloaded: hasDownloaded ?? this.hasDownloaded,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      lastDownloadedAt: lastDownloadedAt ?? this.lastDownloadedAt,
    );
  }

  // ========================================
  // HÀM: markAsViewed()
  // MÔ TẢ: Đánh dấu đã xem với timestamp hiện tại
  // USE CASE: Khi sinh viên click vào announcement
  // ========================================
  AnnouncementTrackingModel markAsViewed() {
    return copyWith(
      hasViewed: true,
      lastViewedAt: DateTime.now(),
    );
  }

  // ========================================
  // HÀM: markAsDownloaded()
  // MÔ TẢ: Đánh dấu đã tải với timestamp hiện tại
  // USE CASE: Khi sinh viên download file đính kèm
  // ========================================
  AnnouncementTrackingModel markAsDownloaded() {
    return copyWith(
      hasDownloaded: true,
      lastDownloadedAt: DateTime.now(),
    );
  }

  // ========================================
  // GETTER: timeAgo
  // MÔ TẢ: Hiển thị thời gian xem cuối theo format dễ đọc
  // ========================================
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(lastViewedAt);

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
  // GETTER: downloadTimeAgo
  // MÔ TẢ: Hiển thị thời gian download cuối (nếu có)
  // ========================================
  String? get downloadTimeAgo {
    if (lastDownloadedAt == null) return null;

    final now = DateTime.now();
    final difference = now.difference(lastDownloadedAt!);

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
  // HELPER: _parseDateTime()
  // MÔ TẢ: Parse DateTime từ multiple sources (Timestamp, String, DateTime)
  // ========================================
  static DateTime? _parseDateTime(dynamic dateData) {
    if (dateData == null) return null;

    if (dateData is Timestamp) {
      return dateData.toDate();
    }

    if (dateData is DateTime) {
      return dateData;
    }

    try {
      return DateTime.parse(dateData.toString());
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // COMPARISON OPERATORS
  // ========================================
  @override
  String toString() =>
      'AnnouncementTrackingModel(id: $id, studentId: $studentId, hasViewed: $hasViewed, hasDownloaded: $hasDownloaded)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnnouncementTrackingModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}