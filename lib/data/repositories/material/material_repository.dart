import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/material_model.dart';
import '../../../domain/models/material_tracking_model.dart';

class MaterialRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Hàm thực thi logic "All or Nothing"
  /// Trả về true nếu thành công, false nếu thất bại
  Future<bool> trackDownloadTransaction({
    required MaterialModel material,
    required String studentId,
  }) async {
    // 1. Khởi tạo Batch
    WriteBatch batch = _firestore.batch();

    try {
      // --- BƯỚC A: CHUẨN BỊ DỮ LIỆU TRACKING ---
      // Tạo Composite ID: materialID_studentID
      final String trackingId = MaterialTrackingModel.generateId(material.id, studentId);
      
      final DocumentReference trackingRef = _firestore
          .collection('material_tracking')
          .doc(trackingId);

      // Dữ liệu tracking
      final Map<String, dynamic> trackingData = {
        'id': trackingId, // Field ID trong model
        'materialId': material.id,
        'studentId': studentId,
        'courseId': material.courseId, // Denormalization từ MaterialModel
        'downloadedAt': FieldValue.serverTimestamp(), // Lấy giờ chuẩn server
        'downloadCount': FieldValue.increment(1), // Tăng số lần SV này tải
      };

      // set với merge: true để hỗ trợ Idempotency (Tải lại không bị lỗi)
      batch.set(trackingRef, trackingData, SetOptions(merge: true));

      // --- BƯỚC B: CHUẨN BỊ DỮ LIỆU MATERIAL (COUNTER) ---
      final DocumentReference materialRef = _firestore
          .collection('materials') // Giả sử collection tên là 'materials'
          .doc(material.id);

      // Chỉ update đúng trường downloadCount
      batch.update(materialRef, {
        'downloadCount': FieldValue.increment(1),
      });

      // --- BƯỚC C: COMMIT (KÍCH HOẠT) ---
      // Lúc này dữ liệu mới thực sự được gửi đi
      await batch.commit();
      
      return true; // Thành công
    } catch (e) {
      print('Lỗi Transaction: $e');
      return false; // Thất bại, dữ liệu Rollback hoàn toàn
    }
  }
}
