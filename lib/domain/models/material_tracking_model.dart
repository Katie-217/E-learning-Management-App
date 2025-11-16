// ========================================
// FILE: material_tracking_model.dart
// MÔ TẢ: Model theo dõi lịch sử xem và tải tài liệu của sinh viên
// COLLECTION: materialTracking (Root Collection)
// PURPOSE: Thay thế downloadCount trong MaterialModel - Theo dõi "AI" đã "xem" và "tải"
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialTrackingModel {
  final String id; // Composite ID: [materialId]_[studentId]
  final String materialId;
  final String courseId;
  final String studentId;
  final String
      groupId; // ✅ QUAN TRỌNG: Lấy từ Enrollment để Giảng viên xem thống kê theo nhóm
  final bool hasViewed; // Theo dõi "who has viewed"
  final bool hasDownloaded; // Theo dõi "who has downloaded" (không đếm số lần)
  final DateTime lastViewedAt;
  final DateTime? lastDownloadedAt; // Optional - chỉ có khi đã download

  const MaterialTrackingModel({
    required this.id,
    required this.materialId,
    required this.courseId,
    required this.studentId,
    required this.groupId,
    this.hasViewed = false,
    this.hasDownloaded = false,
    required this.lastViewedAt,
    this.lastDownloadedAt,
  });

  // ========================================
  // HÀM: generateId()
  // MÔ TẢ: Tạo composite ID cho tracking document
  // ========================================
  static String generateId({
    required String materialId,
    required String studentId,
  }) {
    return '${materialId}_$studentId';
  }

  // ========================================
  // HÀM: fromFirestore()
  // MÔ TẢ: Tạo MaterialTrackingModel từ Firestore DocumentSnapshot
  // ========================================
  factory MaterialTrackingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MaterialTrackingModel(
      id: doc.id,
      materialId: data['materialId'] ?? '',
      courseId: data['courseId'] ?? '',
      studentId: data['studentId'] ?? '',
      groupId: data['groupId'] ?? '',
      hasViewed: data['hasViewed'] ?? false,
      hasDownloaded: data['hasDownloaded'] ?? false,
      lastViewedAt: _parseDateTime(data['lastViewedAt']) ?? DateTime.now(),
      lastDownloadedAt: _parseDateTime(data['lastDownloadedAt']),
    );
  }

  // ========================================
  // HÀM: fromMap()
  // MÔ TẢ: Tạo MaterialTrackingModel từ Map
  // ========================================
  factory MaterialTrackingModel.fromMap(Map<String, dynamic> map) {
    return MaterialTrackingModel(
      id: map['id'] ?? '',
      materialId: map['materialId'] ?? '',
      courseId: map['courseId'] ?? '',
      studentId: map['studentId'] ?? '',
      groupId: map['groupId'] ?? '',
      hasViewed: map['hasViewed'] ?? false,
      hasDownloaded: map['hasDownloaded'] ?? false,
      lastViewedAt: _parseDateTime(map['lastViewedAt']) ?? DateTime.now(),
      lastDownloadedAt: _parseDateTime(map['lastDownloadedAt']),
    );
  }

  // ========================================
  // HÀM: toMap()
  // MÔ TẢ: Chuyển MaterialTrackingModel thành Map để lưu Firebase
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'courseId': courseId,
      'studentId': studentId,
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
  MaterialTrackingModel copyWith({
    String? id,
    String? materialId,
    String? courseId,
    String? studentId,
    String? groupId,
    bool? hasViewed,
    bool? hasDownloaded,
    DateTime? lastViewedAt,
    DateTime? lastDownloadedAt,
  }) {
    return MaterialTrackingModel(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      courseId: courseId ?? this.courseId,
      studentId: studentId ?? this.studentId,
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
  // ========================================
  MaterialTrackingModel markAsViewed() {
    return copyWith(
      hasViewed: true,
      lastViewedAt: DateTime.now(),
    );
  }

  // ========================================
  // HÀM: markAsDownloaded()
  // MÔ TẢ: Đánh dấu đã tải với timestamp hiện tại
  // ========================================
  MaterialTrackingModel markAsDownloaded() {
    return copyWith(
      hasDownloaded: true,
      lastDownloadedAt: DateTime.now(),
    );
  }

  // ========================================
  // HÀM: _parseDateTime()
  // MÔ TẢ: Parse datetime từ Firestore Timestamp hoặc string
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

  @override
  String toString() {
    return 'MaterialTrackingModel(id: $id, materialId: $materialId, studentId: $studentId, hasViewed: $hasViewed, hasDownloaded: $hasDownloaded)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaterialTrackingModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ========================================
// CLASS: MaterialStats
// MÔ TẢ: Thống kê tài liệu cho UI (View counts, Download counts by group)
// ========================================
class MaterialStats {
  final String materialId;
  final int totalViews;
  final int totalDownloads;
  final Map<String, int> viewsByGroup; // groupId -> count
  final Map<String, int> downloadsByGroup; // groupId -> count
  final List<MaterialTrackingModel> recentActivity;

  const MaterialStats({
    required this.materialId,
    required this.totalViews,
    required this.totalDownloads,
    required this.viewsByGroup,
    required this.downloadsByGroup,
    required this.recentActivity,
  });

  // ========================================
  // HÀM: fromTrackingList()
  // MÔ TẢ: Tạo thống kê từ danh sách tracking records
  // ========================================
  factory MaterialStats.fromTrackingList(
    String materialId,
    List<MaterialTrackingModel> trackingList,
  ) {
    int totalViews = 0;
    int totalDownloads = 0;
    Map<String, int> viewsByGroup = {};
    Map<String, int> downloadsByGroup = {};

    for (final tracking in trackingList) {
      // Count views
      if (tracking.hasViewed) {
        totalViews++;
        viewsByGroup[tracking.groupId] =
            (viewsByGroup[tracking.groupId] ?? 0) + 1;
      }

      // Count downloads
      if (tracking.hasDownloaded) {
        totalDownloads++;
        downloadsByGroup[tracking.groupId] =
            (downloadsByGroup[tracking.groupId] ?? 0) + 1;
      }
    }

    // Sort recent activity by lastViewedAt descending
    final recentActivity = List<MaterialTrackingModel>.from(trackingList);
    recentActivity.sort((a, b) => b.lastViewedAt.compareTo(a.lastViewedAt));

    return MaterialStats(
      materialId: materialId,
      totalViews: totalViews,
      totalDownloads: totalDownloads,
      viewsByGroup: viewsByGroup,
      downloadsByGroup: downloadsByGroup,
      recentActivity: recentActivity.take(10).toList(), // Latest 10 activities
    );
  }

  @override
  String toString() {
    return 'MaterialStats(materialId: $materialId, totalViews: $totalViews, totalDownloads: $totalDownloads)';
  }
}
