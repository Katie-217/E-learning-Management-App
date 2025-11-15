// ========================================
// FILE: semester_template_repository.dart
// MÔ TẢ: Repository quản lý "Khuôn Mẫu" (Read-Only)
// Collection: semesterTemplates
// Clean Architecture: Data Layer
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/semester_template_model.dart';

class SemesterTemplateRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'semesterTemplates';

  // ========================================
  // HÀM: getSemesterTemplates()
  // MÔ TẢ: Lấy toàn bộ danh sách các khuôn mẫu từ Firebase
  // Dùng cho UI Dropdown "Chọn Mã HK"
  // ========================================
  Future<List<SemesterTemplateModel>> getSemesterTemplates() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder')
          .get();

      return querySnapshot.docs
          .map((doc) => SemesterTemplateModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      // Fallback to static templates if Firebase fails
      return SemesterTemplates.allTemplates
          .where((template) => template.isActive)
          .toList();
    }
  }

  // ========================================
  // HÀM: getTemplateById()
  // MÔ TẢ: Lấy chi tiết một khuôn mẫu cụ thể bằng ID
  // Ví dụ: getTemplateById("HK1")
  // ========================================
  Future<SemesterTemplateModel?> getTemplateById(String templateId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_collection)
          .doc(templateId)
          .get();

      if (!docSnapshot.exists) {
        // Fallback to static template
        return SemesterTemplates.getTemplateById(templateId);
      }

      return SemesterTemplateModel.fromMap(docSnapshot.id, docSnapshot.data()!);
    } catch (e) {
      // Fallback to static template
      return SemesterTemplates.getTemplateById(templateId);
    }
  }

  // ========================================
  // HÀM: initializeDefaultTemplates()
  // MÔ TẢ: Khởi tạo templates mặc định lần đầu
  // Chỉ gọi 1 lần khi setup hệ thống
  // ========================================
  Future<void> initializeDefaultTemplates() async {
    try {
      final batch = _firestore.batch();
      
      for (final template in SemesterTemplates.allTemplates) {
        final docRef = _firestore.collection(_collection).doc(template.id);
        batch.set(docRef, template.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Lỗi khởi tạo templates: $e');
    }
  }

  // ========================================
  // HÀM: listenToTemplates()
  // MÔ TẢ: Stream để theo dõi thay đổi templates
  // ========================================
  Stream<List<SemesterTemplateModel>> listenToTemplates() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('displayOrder')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SemesterTemplateModel.fromMap(doc.id, doc.data()))
            .toList());
  }
}
