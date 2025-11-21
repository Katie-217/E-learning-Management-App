import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Sửa lại đường dẫn import cho phù hợp với dự án của bạn
import '../../../domain/models/comment_model.dart';
import '../../../domain/models/announcement_tracking_model.dart';
class AnnouncementRepository {
  final FirebaseFirestore _firestore;

  AnnouncementRepository(this._firestore);

  // ===========================================================================
  // 1. ANNOUNCEMENT FETCHING (Lấy danh sách thông báo)
  // ===========================================================================
  
  // Lấy danh sách thông báo của một khóa học
  Stream<List<Map<String, dynamic>>> getAnnouncementsStream(String courseId) {
    // Giả sử AnnouncementModel nằm trong sub-collection: courses/{courseId}/announcements
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              // Lưu ý: Ở đây tôi trả về Map để linh hoạt, 
              // bạn nên map sang AnnouncementModel.fromFirestore(doc)
              final data = doc.data();
              data['id'] = doc.id; 
              return data; 
            }).toList());
  }

  // ===========================================================================
  // 2. TRACKING LOGIC (Quan trọng: Logic Composite ID)
  // ===========================================================================

  /// Đánh dấu sinh viên đã XEM thông báo
  Future<void> trackView({
    required String announcementId,
    required String studentId,
    required String courseId,
    required String groupId,
  }) async {
    // 1. Tạo Composite ID: [announcementId]_[studentId]
    final trackingId = AnnouncementTrackingModel.generateId(
      announcementId: announcementId,
      studentId: studentId,
    );

    // 2. Chuẩn bị dữ liệu Tracking
    // Lưu ý: Chúng ta không tạo full model ở đây để tránh ghi đè field 'hasDownloaded'
    // Chúng ta chỉ update các field liên quan đến View
    final Map<String, dynamic> updateData = {
      'id': trackingId,
      'announcementId': announcementId,
      'studentId': studentId,
      'courseId': courseId, // Denormalized
      'groupId': groupId,   // Denormalized
      'hasViewed': true,
      'lastViewedAt': FieldValue.serverTimestamp(),
    };

    // 3. Upsert vào Root Collection (merge: true để không mất hasDownloaded nếu đã có)
    await _firestore
        .collection('announcementTracking')
        .doc(trackingId)
        .set(updateData, SetOptions(merge: true));
  }

  /// Đánh dấu sinh viên đã TẢI file đính kèm
  Future<void> trackDownload({
    required String announcementId,
    required String studentId,
    required String courseId,
    required String groupId,
  }) async {
    final trackingId = AnnouncementTrackingModel.generateId(
      announcementId: announcementId,
      studentId: studentId,
    );

    final Map<String, dynamic> updateData = {
      'id': trackingId,
      'announcementId': announcementId,
      'studentId': studentId,
      'courseId': courseId,
      'groupId': groupId,
      'hasDownloaded': true,
      'lastDownloadedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('announcementTracking')
        .doc(trackingId)
        .set(updateData, SetOptions(merge: true));
  }

  // ===========================================================================
  // 3. COMMENT LOGIC (Simplified - Flat Structure)
  // ===========================================================================

  /// Lấy danh sách comment của một thông báo
  Stream<List<CommentModel>> getCommentsStream(String announcementId) {
    // Query trực tiếp theo announcementId (không quan tâm parentId nữa)
    return _firestore
        .collection('comments') // Hoặc sub-collection tùy thiết kế DB của bạn
        .where('announcementId', isEqualTo: announcementId)
        .orderBy('createdAt', descending: false) // Cũ nhất lên đầu
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CommentModel.fromMap(doc.data())).toList();
    });
  }

  /// Thêm một comment mới
  Future<void> addComment(CommentModel comment) async {
    // Tạo document reference mới để lấy ID
    final docRef = _firestore.collection('comments').doc();
    
    // Update ID vào model
    final newComment = comment.copyWith(id: docRef.id);
    
    // Ghi lên Firestore
    await docRef.set(newComment.toMap());
  }

  /// Xóa comment (Soft delete hoặc Hard delete tùy logic, ở đây dùng Soft delete)
  Future<void> deleteComment(String commentId) async {
    await _firestore.collection('comments').doc(commentId).update({
      'isDeleted': true,
      'content': '[Bình luận đã bị xóa]',
    });
  }

  // ===========================================================================
  // NEW: CREATE ANNOUNCEMENT
  // ===========================================================================

  /// Create a new announcement in the sub-collection
  Future<void> addAnnouncement({
    required String courseId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Path: courses/{courseId}/announcements
      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('announcements')
          .add(data);
    } catch (e) {
      throw Exception('Failed to add announcement: $e');
    }
  }

  // ===========================================================================
  // EDIT & DELETE OPERATIONS
  // ===========================================================================

  /// Update an existing announcement
  Future<void> updateAnnouncement({
    required String courseId,
    required String announcementId,
    required String title,
    required String content,
  }) async {
    try {
      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('announcements')
          .doc(announcementId)
          .update({
        'title': title,
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(), // Update timestamp
        'isEdited': true,
      });
    } catch (e) {
      throw Exception('Failed to update announcement: $e');
    }
  }

  /// Delete an announcement
  Future<void> deleteAnnouncement({
    required String courseId,
    required String announcementId,
  }) async {
    try {
      // Soft delete or Hard delete? Here we use Hard Delete for simplicity
      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('announcements')
          .doc(announcementId)
          .delete();
          
      // Note: Ideally, you should also delete related comments and tracking data
      // via Cloud Functions to keep the DB clean.
    } catch (e) {
      throw Exception('Failed to delete announcement: $e');
    }
  }
}

// Provider cho Repository
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository(FirebaseFirestore.instance);
});
