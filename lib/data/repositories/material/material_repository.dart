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
      print(
          'DEBUG: 📂 Primary path: $_courseCollectionName/$courseId/$_materialSubCollectionName');

      QuerySnapshot snapshot =
          await _firestore
              .collection(_courseCollectionName)
              .doc(courseId)
              .collection(_materialSubCollectionName)
              .get();

      bool usedFallback = false;

      if (snapshot.docs.isEmpty) {
        print(
            'DEBUG: ⚠️ No documents returned from primary path. Trying collectionGroup fallback...');
        try {
          snapshot = await _firestore
              .collectionGroup(_materialSubCollectionName)
              .where('courseId', isEqualTo: courseId)
              .get();
          usedFallback = true;
          print(
              'DEBUG: ✅ CollectionGroup query succeeded with ${snapshot.docs.length} docs');
        } catch (e) {
          print(
              'DEBUG: ❌ CollectionGroup query failed: $e. Trying root collection fallback...');
        }
      }

      if (snapshot.docs.isEmpty) {
        try {
          snapshot = await _firestore
              .collection(_materialSubCollectionName)
              .where('courseId', isEqualTo: courseId)
              .get();
          usedFallback = true;
          print(
              'DEBUG: ✅ Root collection fallback succeeded with ${snapshot.docs.length} docs');
        } catch (e) {
          print('DEBUG: ❌ Root collection fallback failed: $e');
        }
      }

      print('DEBUG: 📋 Found ${snapshot.docs.length} material documents');

      if (snapshot.docs.isEmpty) {
        print('DEBUG: ⚠️ No materials found in sub-collection');
        print(
            'DEBUG: 💡 Checked paths: primary=${!usedFallback}, fallback=$usedFallback');
        return [];
      }

      // Parse materials (deduplicate by document ID)
      final Map<String, MaterialModel> materials = {};
      for (var doc in snapshot.docs) {
        try {
          print('DEBUG: 📄 Processing material doc: ${doc.id}');
          print('DEBUG: 📄 Doc data: ${doc.data()}');
          var material = MaterialModel.fromFirestore(doc);

          // Nếu courseId trống (do lấy qua collectionGroup), map lại từ tham số truyền vào
          if (material.courseId.isEmpty) {
            material = material.copyWith(courseId: courseId);
          }

          // Filter by isPublished in memory if query didn't filter
          if (material.isPublished) {
            materials[material.id] = material;
            print(
                'DEBUG: ✅ Parsed material: ${material.title} (ID: ${material.id})');
          } else {
            print(
                'DEBUG: ⏭️ Skipped unpublished material: ${material.title} (ID: ${material.id})');
          }
        } catch (e, stackTrace) {
          print('DEBUG: ⚠️ Error parsing material doc ${doc.id}: $e');
          print('DEBUG: ⚠️ Stack trace: $stackTrace');
        }
      }

      // Sort by createdAt if not already sorted
      final materialList = materials.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('DEBUG: ✅ Successfully loaded ${materialList.length} materials');
      print('DEBUG: ===========================================');
      return materialList;
    } catch (e) {
      print('DEBUG: ❌ Error fetching materials: $e');
      print('DEBUG: ❌ Stack trace: ${StackTrace.current}');
      return [];
    }
  }
}
