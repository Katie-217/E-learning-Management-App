// =======================================
// FILE: material_tracking_model.dart
// MÔ TẢ: Model theo dõi sinh viên tải tài liệu (BẮT BUỘC CHO ĐỒ ÁN)
// =======================================

import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialTrackingModel {
  // ID này sẽ là dạng kết hợp: "materialID_studentID"
  // Giúp tìm kiếm O(1) mà không cần query phức tạp
  final String id; 
  
  final String materialId;
  final String studentId;
  
  // Denormalization (Lưu dư thừa để query thống kê nhanh)
  final String courseId; 
  
  // Thời điểm tải xuống lần cuối
  final DateTime downloadedAt;
  
  // Số lần tải (Optional - để giảng viên biết SV có tải lại nhiều lần không)
  final int downloadCount;

  const MaterialTrackingModel({
    required this.id,
    required this.materialId,
    required this.studentId,
    required this.courseId,
    required this.downloadedAt,
    this.downloadCount = 1,
  });

  // =======================================
  // HÀM HELPER: Tạo ID duy nhất
  // =======================================
  static String generateId(String materialId, String studentId) {
    return '${materialId}_$studentId';
  }

  // =======================================
  // FACTORY: Từ Firestore
  // =======================================
  factory MaterialTrackingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return MaterialTrackingModel(
      id: doc.id,
      materialId: data['materialId'] ?? '',
      studentId: data['studentId'] ?? '',
      courseId: data['courseId'] ?? '',
      downloadedAt: _parseDateTime(data['downloadedAt']),
      downloadCount: data['downloadCount'] ?? 1,
    );
  }

  // =======================================
  // METHOD: To Map (Lưu lên Firestore)
  // =======================================
  Map<String, dynamic> toFirestore() {
    return {
      'materialId': materialId,
      'studentId': studentId,
      'courseId': courseId,
      'downloadedAt': FieldValue.serverTimestamp(), // Lấy giờ server
      'downloadCount': downloadCount,
    };
  }
  
  // Helper parse ngày tháng an toàn
  static DateTime _parseDateTime(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  // CopyWith để update số lần tải
  MaterialTrackingModel copyWith({
    int? downloadCount,
    DateTime? downloadedAt,
  }) {
    return MaterialTrackingModel(
      id: id,
      materialId: materialId,
      studentId: studentId,
      courseId: courseId,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      downloadCount: downloadCount ?? this.downloadCount,
    );
  }
}