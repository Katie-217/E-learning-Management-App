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
        .collection('courses')
        .doc(courseId)
        .collection('announcements')
        .orderBy('createdAt', descending: true) // Only sort by date
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
          .collection('courses')
          .doc(courseId)
          .collection('announcements')
          .add({
        'courseId': courseId,
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
          .collection('courses')
          .doc(courseId)
          .collection('announcements')
          .doc(announcementId)
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
      
      // Delete announcement
      batch.delete(
        _firestore
            .collection('courses')
            .doc(courseId)
            .collection('announcements')
            .doc(announcementId),
      );
      
      // Delete all comments
      final commentsSnapshot = await _firestore
          .collection('comments')
          .where('announcementId', isEqualTo: announcementId)
          .get();
      
      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete all tracking data
      final trackingSnapshot = await _firestore
          .collection('announcementTracking')
          .where('announcementId', isEqualTo: announcementId)
          .get();
      
      for (var doc in trackingSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
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
    
    // Update tracking document
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
    
    // Increment view count
    batch.update(
      _firestore
          .collection('courses')
          .doc(courseId)
          .collection('announcements')
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
  Future<Map<String, dynamic>> getTrackingStats(String announcementId) async {
    try {
      final snapshot = await _firestore
          .collection('announcementTracking')
          .where('announcementId', isEqualTo: announcementId)
          .get();
      
      int viewedCount = 0;
      int downloadedCount = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['hasViewed'] == true) viewedCount++;
        if (data['hasDownloaded'] == true) downloadedCount++;
      }
      
      return {
        'totalStudents': snapshot.docs.length,
        'viewedCount': viewedCount,
        'notViewedCount': snapshot.docs.length - viewedCount,
        'downloadedCount': downloadedCount,
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
      
      // Create comment
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
      
      // Increment comment count
      batch.update(
        _firestore
            .collection('courses')
            .doc(courseId)
            .collection('announcements')
            .doc(announcementId),
        {'commentCount': FieldValue.increment(1)},
      );
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Delete comment (soft delete)
  Future<void> deleteComment({
    required String commentId,
    required String courseId,
    required String announcementId,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Soft delete comment
      batch.update(
        _firestore.collection('comments').doc(commentId),
        {
          'isDeleted': true,
          'content': '[Comment deleted]',
        },
      );
      
      // Decrement comment count
      batch.update(
        _firestore
            .collection('courses')
            .doc(courseId)
            .collection('announcements')
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

  /// Get announcements for student (filtered by group)
  Stream<List<Map<String, dynamic>>> getStudentAnnouncementsStream({
    required String courseId,
    required String studentGroupId,
  }) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('announcements')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true) // Only sort by date
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) {
              final data = doc.data();
              final targetGroups = List<String>.from(data['targetGroupIds'] ?? []);
              
              // Show if: no target groups (all groups) OR student's group is in target
              return targetGroups.isEmpty || targetGroups.contains(studentGroupId);
            })
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            })
            .toList());
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