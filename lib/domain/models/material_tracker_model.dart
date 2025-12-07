// ========================================
// FILE: material_tracker_model.dart
// MÔ TẢ: Model cho Material Tracking System (Simplified)
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialTrackerModel {
  // --- Foreign Keys ---
  final String id; // ${materialId}_${studentId}
  final String materialId;
  final String studentId;
  final String courseId;
  final String groupId; // For group filtering

  // --- Student Info ---
  final String studentName;
  final String studentEmail;

  // --- Tracking Data ---
  final bool isViewed; // Đã xem chưa?
  final DateTime? viewedAt; // Xem lúc nào?

  final bool isDownloaded; // Đã tải chưa?
  final DateTime? downloadedAt; // Tải lúc nào?

  // --- Filter Helper ---
  final String status; // 'new', 'viewed', 'downloaded'

  // --- Timestamps ---
  final DateTime createdAt;
  final DateTime updatedAt;

  MaterialTrackerModel({
    required this.id,
    required this.materialId,
    required this.studentId,
    required this.courseId,
    required this.groupId,
    required this.studentName,
    required this.studentEmail,
    this.isViewed = false,
    this.viewedAt,
    this.isDownloaded = false,
    this.downloadedAt,
    this.status = 'new',
    required this.createdAt,
    required this.updatedAt,
  });

  // Generate tracker ID
  static String generateId(String materialId, String studentId) {
    return '${materialId}_$studentId';
  }

  // Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'studentId': studentId,
      'courseId': courseId,
      'groupId': groupId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'isViewed': isViewed,
      'viewedAt': viewedAt?.toIso8601String(),
      'isDownloaded': isDownloaded,
      'downloadedAt': downloadedAt?.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Convert from Firestore Document
  factory MaterialTrackerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MaterialTrackerModel(
      id: doc.id,
      materialId: data['materialId'] ?? '',
      studentId: data['studentId'] ?? '',
      courseId: data['courseId'] ?? '',
      groupId: data['groupId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      isViewed: data['isViewed'] ?? false,
      viewedAt: _parseDateTime(data['viewedAt']),
      isDownloaded: data['isDownloaded'] ?? false,
      downloadedAt: _parseDateTime(data['downloadedAt']),
      status: data['status'] ?? 'new',
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
    );
  }

  // Helper to parse DateTime from Firestore (handles both Timestamp and String)
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // CopyWith method
  MaterialTrackerModel copyWith({
    String? id,
    String? materialId,
    String? studentId,
    String? courseId,
    String? groupId,
    String? studentName,
    String? studentEmail,
    bool? isViewed,
    DateTime? viewedAt,
    bool? isDownloaded,
    DateTime? downloadedAt,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialTrackerModel(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      groupId: groupId ?? this.groupId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      isViewed: isViewed ?? this.isViewed,
      viewedAt: viewedAt ?? this.viewedAt,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
