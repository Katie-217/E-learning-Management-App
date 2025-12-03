// ========================================
// FILE: forum_repository.dart
// DESCRIPTION: Simplified Forum Repository - Core Operations Only
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForumRepository {
  final FirebaseFirestore _firestore;

  ForumRepository(this._firestore);

  // ===========================================================================
  // 1. TOPIC OPERATIONS
  // ===========================================================================

  /// Get topics stream for a course (sorted by lastReplyAt)
  Stream<List<Map<String, dynamic>>> getTopicsStream(String courseId) {
    return _firestore
        .collection('forums')
        .doc(courseId)
        .collection('topics')
        .orderBy('lastReplyAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Create new topic with validation
  Future<String> createTopic({
    required String courseId,
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    List<String> attachments = const [],
  }) async {
    // Validation
    if (title.trim().isEmpty) {
      throw Exception('Tiêu đề không được để trống');
    }
    if (content.trim().isEmpty) {
      throw Exception('Nội dung không được để trống');
    }

    try {
      final docRef = await _firestore
          .collection('forums')
          .doc(courseId)
          .collection('topics')
          .add({
        'courseId': courseId,
        'title': title.trim(),
        'content': content.trim(),
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
        'replyCount': 0,
        'lastReplyAt': FieldValue.serverTimestamp(),
        'attachments': attachments,
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Không thể tạo chủ đề: $e');
    }
  }

  /// Delete topic (Instructor only)
  Future<void> deleteTopic({
    required String courseId,
    required String topicId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Delete topic
      batch.delete(
        _firestore
            .collection('forums')
            .doc(courseId)
            .collection('topics')
            .doc(topicId),
      );

      // Delete all replies
      final repliesSnapshot = await _firestore
          .collection('forums')
          .doc(courseId)
          .collection('topics')
          .doc(topicId)
          .collection('replies')
          .get();

      for (var doc in repliesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Không thể xóa chủ đề: $e');
    }
  }

  /// Search topics by title or content
  Stream<List<Map<String, dynamic>>> searchTopics({
    required String courseId,
    required String query,
  }) {
    return _firestore
        .collection('forums')
        .doc(courseId)
        .collection('topics')
        .orderBy('lastReplyAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final allTopics = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (query.isEmpty) return allTopics;

      final lowerQuery = query.toLowerCase();
      return allTopics.where((topic) {
        final title = (topic['title'] ?? '').toString().toLowerCase();
        final content = (topic['content'] ?? '').toString().toLowerCase();
        return title.contains(lowerQuery) || content.contains(lowerQuery);
      }).toList();
    });
  }

  // ===========================================================================
  // 2. REPLY OPERATIONS (Threaded Replies)
  // ===========================================================================

  /// Get replies stream for a topic
  Stream<List<Map<String, dynamic>>> getRepliesStream({
    required String courseId,
    required String topicId,
  }) {
    return _firestore
        .collection('forums')
        .doc(courseId)
        .collection('topics')
        .doc(topicId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Add reply to topic with validation
  Future<void> addReply({
    required String courseId,
    required String topicId,
    required String content,
    required String authorId,
    required String authorName,
    String? replyToId,                    // ← Thêm tham số này
    String? authorReplyTo,
    List<String> attachments = const [],
  }) async {
    // Validation
    if (content.trim().isEmpty) {
      throw Exception('Nội dung phản hồi không được để trống');
    }

    try {
      final batch = _firestore.batch();

      // Create reply
      final replyRef = _firestore
          .collection('forums')
          .doc(courseId)
          .collection('topics')
          .doc(topicId)
          .collection('replies')
          .doc();

      batch.set(replyRef, {
        'topicId': topicId,
        'content': content.trim(),
        'authorId': authorId,
        'authorName': authorName,
        'replyToId': replyToId,                    // ← LƯU VÀO ĐÂY
        'authorReplyTo': authorReplyTo,            // ← (tùy chọn, để hiển thị tên)
        'createdAt': FieldValue.serverTimestamp(),
        'attachments': attachments,
      });

      // Update topic's reply count and last activity
      final topicRef = _firestore
          .collection('forums')
          .doc(courseId)
          .collection('topics')
          .doc(topicId);

      batch.update(topicRef, {
        'replyCount': FieldValue.increment(1),
        'lastReplyAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Không thể thêm phản hồi: $e');
    }
  }

  /// Delete reply (Instructor only)
  Future<void> deleteReply({
    required String courseId,
    required String topicId,
    required String replyId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Delete reply
      batch.delete(
        _firestore
            .collection('forums')
            .doc(courseId)
            .collection('topics')
            .doc(topicId)
            .collection('replies')
            .doc(replyId),
      );

      // Decrement reply count
      batch.update(
        _firestore
            .collection('forums')
            .doc(courseId)
            .collection('topics')
            .doc(topicId),
        {'replyCount': FieldValue.increment(-1)},
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Không thể xóa phản hồi: $e');
    }
  }
}

// ===========================================================================
// PROVIDER
// ===========================================================================

final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  return ForumRepository(FirebaseFirestore.instance);
});