import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/comment_model.dart';
import '../../../domain/models/announcement_tracking_model.dart';

class AnnouncementRepository {
  final FirebaseFirestore _firestore;

  AnnouncementRepository(this._firestore);

  // ===========================================================================
  // 1. ANNOUNCEMENT CRUD OPERATIONS
  // ===========================================================================
  
  /// Get announcements stream for a course (REMOVED isPinned ordering)
  Stream<List<Map<String, dynamic>>> getAnnouncementsStream(String courseId) {
      return _firestore
          .collection('announcements') // ✅ ĐỔI: Root collection
          .where('courseId', isEqualTo: courseId) // ✅ THÊM: Filter theo course
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList());
    }

  /// Create new announcement (REMOVED isPinned parameter)
  Future<String> createAnnouncement({
    required String courseId,
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    String? authorAvatar,
    List<Map<String, dynamic>> attachments = const [],
    List<String> targetGroupIds = const [],
  }) async {
    try {
      final docRef = await _firestore
          .collection('announcements') // ✅ ĐỔI: Root collection
          .add({
        'courseId': courseId, // Quan trọng để lọc
        'title': title,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'attachments': attachments,
        'targetGroupIds': targetGroupIds,
        'isPublished': true,
        'viewCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create announcement: $e');
    }
  }

  /// Update announcement (REMOVED isPinned parameter)
  Future<void> updateAnnouncement({
    required String courseId,
    required String announcementId,
    required String title,
    required String content,
    List<Map<String, dynamic>>? attachments,
    List<String>? targetGroupIds,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'title': title,
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (attachments != null) updateData['attachments'] = attachments;
      if (targetGroupIds != null) updateData['targetGroupIds'] = targetGroupIds;
      
      await _firestore
          .collection('announcements') // ✅ ĐỔI: Root collection
          .doc(announcementId) // Truy cập thẳng bằng ID
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update announcement: $e');
    }
  }
  /// Delete announcement (and cleanup related data)
  Future<void> deleteAnnouncement({
    required String courseId,
    required String announcementId,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Delete announcement from Root
      batch.delete(
        _firestore
            .collection('announcements') // ✅ ĐỔI: Root collection
            .doc(announcementId),
      );
      
      // Xóa comments (Giữ nguyên logic)
      final commentsSnapshot = await _firestore
          .collection('comments')
          .where('announcementId', isEqualTo: announcementId)
          .get();
      for (var doc in commentsSnapshot.docs) batch.delete(doc.reference);
      
      // Xóa tracking (Giữ nguyên logic)
      final trackingSnapshot = await _firestore
          .collection('announcementTracking')
          .where('announcementId', isEqualTo: announcementId)
          .get();
      for (var doc in trackingSnapshot.docs) batch.delete(doc.reference);
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete announcement: $e');
    }
  }
  // ===========================================================================
  // 2. TRACKING OPERATIONS
  // ===========================================================================

  /// Track view
  Future<void> trackView({
      required String announcementId,
      required String studentId,
      required String courseId,
    }) async {
      final trackingId = AnnouncementTrackingModel.generateId(
        announcementId: announcementId,
        studentId: studentId,
      );

      final batch = _firestore.batch();
      
      // Update tracking doc (Giữ nguyên)
      batch.set(
        _firestore.collection('announcementTracking').doc(trackingId),
        {
          'announcementId': announcementId,
          'studentId': studentId,
          'courseId': courseId,
          'hasViewed': true,
          'lastViewedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      
      // Increment view count (SỬA: Update vào Root Announcement)
      batch.update(
        _firestore
            .collection('announcements') // ✅ ĐỔI: Root collection
            .doc(announcementId),
        {'viewCount': FieldValue.increment(1)},
      );
      
      await batch.commit();
    }

  /// Track download
  Future<void> trackDownload({
    required String announcementId,
    required String studentId,
    required String courseId,
  }) async {
    final trackingId = AnnouncementTrackingModel.generateId(
      announcementId: announcementId,
      studentId: studentId,
    );

    await _firestore
        .collection('announcementTracking')
        .doc(trackingId)
        .set(
          {
            'announcementId': announcementId,
            'studentId': studentId,
            'courseId': courseId,
            'hasDownloaded': true,
            'lastDownloadedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
  }

  /// Get tracking statistics
  Future<Map<String, dynamic>> getTrackingStats({
    required String announcementId,
    required String courseId,
  }) async {
    try {
      // Get tracking data
      final trackingSnapshot = await _firestore
          .collection('announcementTracking')
          .where('announcementId', isEqualTo: announcementId)
          .get();
      
      int viewedCount = 0;
      int downloadedCount = 0;
      Set<String> trackedStudentIds = {};
      
      for (var doc in trackingSnapshot.docs) {
        final data = doc.data();
        trackedStudentIds.add(data['studentId']);
        if (data['hasViewed'] == true) viewedCount++;
        if (data['hasDownloaded'] == true) downloadedCount++;
      }
      
      // ✅ GET TOTAL ENROLLED STUDENTS from enrollments collection
      final enrollmentsSnapshot = await _firestore
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .where('status', isEqualTo: 'active')
          .where('role', isEqualTo: 'student')
          .get();
      
      final totalStudents = enrollmentsSnapshot.docs.length;
      final notViewedCount = totalStudents - viewedCount;
      
      print('📊 Tracking Stats:');
      print('   - Total Students: $totalStudents');
      print('   - Viewed: $viewedCount');
      print('   - Not Viewed: $notViewedCount');
      print('   - Downloaded: $downloadedCount');
      
      return {
        'totalStudents': totalStudents,
        'viewedCount': viewedCount,
        'notViewedCount': notViewedCount,
        'downloadedCount': downloadedCount,
        'viewPercentage': totalStudents > 0 
            ? ((viewedCount / totalStudents) * 100).toStringAsFixed(1) 
            : '0.0',
      };
    } catch (e) {
      throw Exception('Failed to get tracking stats: $e');
    }
  }
  /// Get tracking data stream
  Stream<List<AnnouncementTrackingModel>> getTrackingStream(String announcementId) {
    return _firestore
        .collection('announcementTracking')
        .where('announcementId', isEqualTo: announcementId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementTrackingModel.fromFirestore(doc))
            .toList());
  }

  // ===========================================================================
  // 3. COMMENT OPERATIONS
  // ===========================================================================

  /// Get comments stream
  Stream<List<CommentModel>> getCommentsStream(String announcementId) {
    return _firestore
        .collection('comments')
        .where('announcementId', isEqualTo: announcementId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromMap(doc.data()))
            .toList());
  }

  /// Add comment
  Future<void> addComment({
    required String announcementId,
    required String courseId,
    required String content,
    required String authorId,
    required String authorName,
    required String authorRole,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Create comment (Giữ nguyên)
      final commentRef = _firestore.collection('comments').doc();
      batch.set(commentRef, {
        'id': commentRef.id,
        'announcementId': announcementId,
        'courseId': courseId,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'authorRole': authorRole,
        'createdAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
      });
      
      // Increment comment count (SỬA: Update vào Root Announcement)
      batch.update(
        _firestore
            .collection('announcements') // ✅ ĐỔI: Root collection
            .doc(announcementId),
        {'commentCount': FieldValue.increment(1)},
      );
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Delete comment (SỬA: Decrement commentCount trong Root)
  Future<void> deleteComment({
    required String commentId,
    required String courseId,
    required String announcementId,
  }) async {
    try {
      final batch = _firestore.batch();
      
      batch.update(
        _firestore.collection('comments').doc(commentId),
        {'isDeleted': true, 'content': '[Comment deleted]'},
      );
      
      batch.update(
        _firestore
            .collection('announcements') // ✅ ĐỔI: Root collection
            .doc(announcementId),
        {'commentCount': FieldValue.increment(-1)},
      );
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // ===========================================================================
  // 4. STUDENT-SPECIFIC QUERIES
  // ===========================================================================

  /// Get announcements for student (SỬA: Query từ Root)
  Stream<List<Map<String, dynamic>>> getStudentAnnouncementsStream({
    required String courseId,
    required String studentGroupId,
  }) {
    return _firestore
        .collection('announcements') // ✅ ĐỔI: Root collection
        .where('courseId', isEqualTo: courseId) // ✅ THÊM: Filter course
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        // ... (Phần logic filter group bên dưới giữ nguyên)
        .map((snapshot) => snapshot.docs
            .where((doc) {
              final data = doc.data();
              final targetGroups = List<String>.from(data['targetGroupIds'] ?? []);
              return targetGroups.isEmpty || targetGroups.contains(studentGroupId);
            })
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            })
            .toList());
  }
  // Thêm vào AnnouncementRepository class
  /// Get tracking data as list (for provider)
  Future<List<AnnouncementTrackingModel>> getTrackingList(String announcementId) async {
  try {
    final snapshot = await _firestore
        .collection('announcementTracking')
        .where('announcementId', isEqualTo: announcementId)
        .get();
    
    return snapshot.docs
        .map((doc) => AnnouncementTrackingModel.fromFirestore(doc))
        .toList();
  } catch (e) {
    print('Error getting tracking list: $e');
    return [];
  }
  }

  /// Check if student has viewed announcement
  Future<bool> hasStudentViewed({
    required String announcementId,
    required String studentId,
  }) async {
    try {
      final trackingId = AnnouncementTrackingModel.generateId(
        announcementId: announcementId,
        studentId: studentId,
      );
      
      final doc = await _firestore
          .collection('announcementTracking')
          .doc(trackingId)
          .get();
      
      if (!doc.exists) return false;
      
      return doc.data()?['hasViewed'] ?? false;
    } catch (e) {
      return false;
    }
  }
  
}

// ===========================================================================
// PROVIDER
// ===========================================================================

final AnnouncementRepositoryProvider = 
    Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository(FirebaseFirestore.instance);
});
