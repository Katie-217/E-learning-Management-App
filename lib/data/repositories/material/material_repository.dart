// ========================================
// FILE: material_repository.dart
// MÔ TẢ: Repository cho Material - Sub-collection trong course_of_study
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/material_model.dart';

class MaterialRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _courseCollectionName = 'course_of_study';
  static const String _materialSubCollectionName = 'materials';

  // ========================================
  // HÀM: getMaterialsByCourse
  // MÔ TẢ: Lấy materials từ sub-collection trong course_of_study
  // ========================================
  static Future<List<MaterialModel>> getMaterialsByCourse(
      String courseId) async {
    try {
      print('DEBUG: ========== FETCHING MATERIALS ==========');
      print('DEBUG: 🔍 Fetching materials for course: $courseId');
      print('DEBUG: 📂 Collection path: $_courseCollectionName/$courseId/$_materialSubCollectionName');

      QuerySnapshot snapshot;
      try {
        // Thử query đơn giản nhất trước (không filter, không orderBy) để lấy tất cả materials
        print('DEBUG: 🔍 Attempting simple query (no filter, no orderBy)...');
        snapshot = await _firestore
            .collection(_courseCollectionName)
            .doc(courseId)
            .collection(_materialSubCollectionName)
            .get();
        print('DEBUG: ✅ Simple query succeeded');
      } catch (e) {
        // Nếu fail, có thể collection không tồn tại
        print('DEBUG: ❌ Query failed: $e');
        print('DEBUG: 💡 Collection might not exist or path is incorrect');
        print('DEBUG: 💡 Full path: $_courseCollectionName/$courseId/$_materialSubCollectionName');
        return [];
      }

      print('DEBUG: 📋 Found ${snapshot.docs.length} material documents');

      if (snapshot.docs.isEmpty) {
        print('DEBUG: ⚠️ No materials found in sub-collection');
        print('DEBUG: 💡 Check if materials exist in Firestore at: $_courseCollectionName/$courseId/$_materialSubCollectionName');
        return [];
      }

      // Parse materials
      final materials = <MaterialModel>[];
      for (var doc in snapshot.docs) {
        try {
          print('DEBUG: 📄 Processing material doc: ${doc.id}');
          print('DEBUG: 📄 Doc data: ${doc.data()}');
          var material = MaterialModel.fromFirestore(doc);
          // Set courseId từ parent nếu chưa có
          if (material.courseId.isEmpty) {
            material = material.copyWith(courseId: courseId);
          }
          // Filter by isPublished in memory if query didn't filter
          if (material.isPublished) {
            materials.add(material);
            print('DEBUG: ✅ Parsed material: ${material.title} (ID: ${material.id})');
          } else {
            print('DEBUG: ⏭️ Skipped unpublished material: ${material.title} (ID: ${material.id})');
          }
        } catch (e, stackTrace) {
          print('DEBUG: ⚠️ Error parsing material doc ${doc.id}: $e');
          print('DEBUG: ⚠️ Stack trace: $stackTrace');
        }
      }

      // Sort by createdAt if not already sorted
      materials.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('DEBUG: ✅ Successfully loaded ${materials.length} materials');
      print('DEBUG: ===========================================');
      return materials;
    } catch (e) {
      print('DEBUG: ❌ Error fetching materials: $e');
      print('DEBUG: ❌ Stack trace: ${StackTrace.current}');
      return [];
    }
  }
}
