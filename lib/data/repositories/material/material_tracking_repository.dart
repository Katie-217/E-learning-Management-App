// ========================================
// FILE: material_tracking_repository.dart
// MÔ TẢ: Repository quản lý việc theo dõi xem và tải tài liệu
// COLLECTION: materialTracking (Root Collection)
// Clean Architecture: Data Layer
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../domain/models/material_tracking_model.dart';

class MaterialTrackingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'materialTracking';

  // ========================================
  // HÀM: logViewEvent()
  // MÔ TẢ: Ghi nhật ký sự kiện "xem" tài liệu
  // LOGIC: Dùng composite ID để set() hoặc update() document
  // ========================================
  Future<void> logViewEvent(MaterialTrackingModel data) async {
    try {
      final docRef = _firestore.collection(_collection).doc(data.id);
      
      // Check if document exists
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        // Update existing document - mark as viewed with current timestamp
        await docRef.update({
          'hasViewed': true,
          'lastViewedAt': Timestamp.fromDate(DateTime.now()),
          'groupId': data.groupId, // Update groupId in case it changed
        });
        
        print('✅ Updated view event for material ${data.materialId}, student ${data.studentId}');
      } else {
        // Create new document with view event
        final trackingData = data.copyWith(
          hasViewed: true,
          lastViewedAt: DateTime.now(),
        );
        
        await docRef.set(trackingData.toMap());
        print('✅ Created new tracking document with view event for material ${data.materialId}, student ${data.studentId}');
      }
    } catch (e) {
      print('❌ Error logging view event: $e');
      throw Exception('Failed to log view event: $e');
    }
  }

  // ========================================
  // HÀM: logDownloadEvent()
  // MÔ TẢ: Ghi nhật ký sự kiện "tải" tài liệu
  // LOGIC: Dùng composite ID để set() hoặc update() document
  // ========================================
  Future<void> logDownloadEvent(MaterialTrackingModel data) async {
    try {
      final docRef = _firestore.collection(_collection).doc(data.id);
      
      // Check if document exists
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        // Update existing document - mark as downloaded with current timestamp
        await docRef.update({
          'hasDownloaded': true,
          'lastDownloadedAt': Timestamp.fromDate(DateTime.now()),
          'groupId': data.groupId, // Update groupId in case it changed
        });
        
        print('✅ Updated download event for material ${data.materialId}, student ${data.studentId}');
      } else {
        // Create new document with download event (and auto-mark as viewed)
        final trackingData = data.copyWith(
          hasViewed: true, // Auto-mark as viewed when downloading
          hasDownloaded: true,
          lastViewedAt: DateTime.now(),
          lastDownloadedAt: DateTime.now(),
        );
        
        await docRef.set(trackingData.toMap());
        print('✅ Created new tracking document with download event for material ${data.materialId}, student ${data.studentId}');
      }
    } catch (e) {
      print('❌ Error logging download event: $e');
      throw Exception('Failed to log download event: $e');
    }
  }

  // ========================================
  // HÀM: getStatsForMaterial()
  // MÔ TẢ: Lấy thống kê cho một tài liệu cụ thể
  // LOGIC: Query tất cả tracking records của materialId
  // ========================================
  Future<List<MaterialTrackingModel>> getStatsForMaterial(String materialId) async {
    try {
      print('DEBUG: 🔍 Getting tracking stats for materialId: $materialId');
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('materialId', isEqualTo: materialId)
          .get();

      final trackingList = querySnapshot.docs
          .map((doc) => MaterialTrackingModel.fromFirestore(doc))
          .toList();

      print('DEBUG: ✅ Found ${trackingList.length} tracking records for material $materialId');
      
      return trackingList;
    } catch (e) {
      print('DEBUG: ❌ Error getting material stats: $e');
      throw Exception('Failed to get material stats: $e');
    }
  }

  // ========================================
  // HÀM: getStatsForCourse()
  // MÔ TẢ: Lấy thống kê cho tất cả tài liệu trong khóa học
  // ========================================
  Future<List<MaterialTrackingModel>> getStatsForCourse(String courseId) async {
    try {
      print('DEBUG: 🔍 Getting tracking stats for courseId: $courseId');
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('courseId', isEqualTo: courseId)
          .get();

      final trackingList = querySnapshot.docs
          .map((doc) => MaterialTrackingModel.fromFirestore(doc))
          .toList();

      print('DEBUG: ✅ Found ${trackingList.length} tracking records for course $courseId');
      
      return trackingList;
    } catch (e) {
      print('DEBUG: ❌ Error getting course stats: $e');
      throw Exception('Failed to get course stats: $e');
    }
  }

  // ========================================
  // HÀM: getStudentActivity()
  // MÔ TẢ: Lấy lịch sử hoạt động của sinh viên
  // ========================================
  Future<List<MaterialTrackingModel>> getStudentActivity(
    String studentId, {
    String? courseId,
  }) async {
    try {
      print('DEBUG: 🔍 Getting activity for studentId: $studentId');
      
      Query query = _firestore
          .collection(_collection)
          .where('studentId', isEqualTo: studentId);

      if (courseId != null) {
        query = query.where('courseId', isEqualTo: courseId);
      }

      final querySnapshot = await query
          .orderBy('lastViewedAt', descending: true)
          .get();

      final trackingList = querySnapshot.docs
          .map((doc) => MaterialTrackingModel.fromFirestore(doc))
          .toList();

      print('DEBUG: ✅ Found ${trackingList.length} activity records for student $studentId');
      
      return trackingList;
    } catch (e) {
      print('DEBUG: ❌ Error getting student activity: $e');
      throw Exception('Failed to get student activity: $e');
    }
  }

  // ========================================
  // HÀM: getGroupStats()
  // MÔ TẢ: Lấy thống kê theo nhóm cho một tài liệu
  // ========================================
  Future<Map<String, List<MaterialTrackingModel>>> getGroupStats(
    String materialId,
  ) async {
    try {
      final trackingList = await getStatsForMaterial(materialId);
      
      // Group by groupId
      final Map<String, List<MaterialTrackingModel>> groupedStats = {};
      
      for (final tracking in trackingList) {
        if (!groupedStats.containsKey(tracking.groupId)) {
          groupedStats[tracking.groupId] = [];
        }
        groupedStats[tracking.groupId]!.add(tracking);
      }

      return groupedStats;
    } catch (e) {
      throw Exception('Failed to get group stats: $e');
    }
  }

  // ========================================
  // HÀM: getTrackingRecord()
  // MÔ TẢ: Lấy tracking record cụ thể của một sinh viên với một tài liệu
  // ========================================
  Future<MaterialTrackingModel?> getTrackingRecord(
    String materialId,
    String studentId,
  ) async {
    try {
      final trackingId = MaterialTrackingModel.generateId(
        materialId: materialId,
        studentId: studentId,
      );

      final docSnapshot = await _firestore
          .collection(_collection)
          .doc(trackingId)
          .get();

      if (docSnapshot.exists) {
        return MaterialTrackingModel.fromFirestore(docSnapshot);
      }

      return null;
    } catch (e) {
      print('DEBUG: ❌ Error getting tracking record: $e');
      return null;
    }
  }

  // ========================================
  // HÀM: deleteTrackingRecord()
  // MÔ TẢ: Xóa tracking record (cho cleanup hoặc GDPR)
  // ========================================
  Future<void> deleteTrackingRecord(String materialId, String studentId) async {
    try {
      final trackingId = MaterialTrackingModel.generateId(
        materialId: materialId,
        studentId: studentId,
      );

      await _firestore.collection(_collection).doc(trackingId).delete();
      
      print('✅ Deleted tracking record for material $materialId, student $studentId');
    } catch (e) {
      throw Exception('Failed to delete tracking record: $e');
    }
  }

  // ========================================
  // HÀM: bulkDeleteTrackingForMaterial()
  // MÔ TẢ: Xóa tất cả tracking records của một tài liệu (khi xóa material)
  // ========================================
  Future<void> bulkDeleteTrackingForMaterial(String materialId) async {
    try {
      final batch = _firestore.batch();
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('materialId', isEqualTo: materialId)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      print('✅ Bulk deleted ${querySnapshot.docs.length} tracking records for material $materialId');
    } catch (e) {
      throw Exception('Failed to bulk delete tracking records: $e');
    }
  }

  // ========================================
  // HÀM: listenToMaterialStats()
  // MÔ TẢ: Stream để theo dõi thay đổi thống kê real-time
  // ========================================
  Stream<List<MaterialTrackingModel>> listenToMaterialStats(String materialId) {
    return _firestore
        .collection(_collection)
        .where('materialId', isEqualTo: materialId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialTrackingModel.fromFirestore(doc))
            .toList());
  }
}