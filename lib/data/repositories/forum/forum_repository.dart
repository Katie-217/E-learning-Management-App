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
        .map((snapshot) {
          print('📊 Topics snapshot for course $courseId: ${snapshot.docs.length} documents');
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        })
        .handleError((error, stackTrace) {
          print('❌ Error in getTopicsStream for course $courseId: $error');
          print('Stack trace: $stackTrace');
          // Trả về empty list khi có lỗi
          return <Map<String, dynamic>>[];
        });
  }

  /// Get single topic by ID
  Future<Map<String, dynamic>?> getTopicById({
    required String courseId,
    required String topicId,
  }) async {
    try {
      final doc = await _firestore
          .collection('forums')
          .doc(courseId)
          .collection('topics')
          .doc(topicId)
          .get();
      
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data();
      if (data == null) {
        return null;
      }
      
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('❌ Error getting topic by ID: $e');
      return null;
    }
  }

  /// Get single topic stream by ID
  Stream<Map<String, dynamic>?> getTopicStream({
    required String courseId,
    required String topicId,
  }) {
    return _firestore
        .collection('forums')
        .doc(courseId)
        .collection('topics')
        .doc(topicId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return null;
          }
          
          final data = snapshot.data();
          if (data == null) {
            return null;
          }
          
          data['id'] = snapshot.id;
          return data;
        })
        .handleError((error, stackTrace) {
          print('❌ Error in getTopicStream: $error');
          print('Stack trace: $stackTrace');
          return null;
        });
  }

  /// Create new topic with validation
/// Create new topic with validation
  Future<String> createTopic({
    required String courseId,
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    List<String> attachments = const [],
  }) async {
    print("🔥 [Repo] Bắt đầu ghi vào Firestore...");
    print("   Path: forums/$courseId/topics");
    
    // Validation
    if (title.trim().isEmpty) throw Exception('Tiêu đề trống');
    if (content.trim().isEmpty) throw Exception('Nội dung trống');

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
      
      print("✅ [Repo] Ghi thành công! Doc ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print("❌ [Repo] LỖI GHI FIRESTORE: $e"); // Log lỗi đỏ lòm
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
        .map((snapshot) {
          print('📊 Replies snapshot for topic $topicId: ${snapshot.docs.length} documents');
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        })
        .handleError((error, stackTrace) {
          print('❌ Error in getRepliesStream for topic $topicId: $error');
          print('Stack trace: $stackTrace');
          // Re-throw error để UI có thể hiển thị
          throw error;
        });
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

      // Create reply document chính trong collection replies của topic
      final repliesCollection = _firestore
          .collection('forums')
          .doc(courseId)
          .collection('topics')
          .doc(topicId)
          .collection('replies');

      final replyRef = repliesCollection.doc();

      final replyData = <String, dynamic>{
        'topicId': topicId,
        'content': content.trim(),
        'authorId': authorId,
        'authorName': authorName,
        'replyToId': replyToId, // id comment cha (nếu có)
        'authorReplyTo': authorReplyTo, // tên người được reply (nếu có)
        'createdAt': FieldValue.serverTimestamp(),
        'attachments': attachments,
      };

      // Lưu reply chính
      batch.set(replyRef, replyData);

      // Nếu đây là reply cho một comment khác, lưu thêm vào subcollection replies_to
      if (replyToId != null && replyToId.isNotEmpty) {
        final parentReplyRef = repliesCollection.doc(replyToId);
        final nestedReplyRef =
            parentReplyRef.collection('replies_to').doc(replyRef.id);

        batch.set(nestedReplyRef, replyData);
      }

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