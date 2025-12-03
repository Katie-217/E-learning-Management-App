// ========================================
// FILE: forum_provider.dart
// DESCRIPTION: Simplified Forum Provider - Core Operations Only
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/data/repositories/forum/forum_repository.dart';
import 'package:elearning_management_app/domain/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ===========================================================================
// STREAM PROVIDERS
// ===========================================================================

/// Provider for topics stream
final topicsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, courseId) {
  final repo = ref.watch(forumRepositoryProvider);
  return repo.getTopicsStream(courseId);
});

/// Provider for search topics stream
final searchTopicsProvider = StreamProvider.family<List<Map<String, dynamic>>, ({String courseId, String query})>((ref, params) {
  final repo = ref.watch(forumRepositoryProvider);
  return repo.searchTopics(courseId: params.courseId, query: params.query);
});

/// Provider for replies stream
final repliesProvider = StreamProvider.family<List<Map<String, dynamic>>, ({String courseId, String topicId})>((ref, params) {
  final repo = ref.watch(forumRepositoryProvider);
  return repo.getRepliesStream(courseId: params.courseId, topicId: params.topicId);
});

/// Provider for course forums list (lấy danh sách các khóa học có forum)
final courseForumsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Lấy tất cả courses
    final coursesSnapshot = await firestore.collection('course_of_study').get();
    
    List<Map<String, dynamic>> forums = [];
    
    for (var courseDoc in coursesSnapshot.docs) {
      final courseData = courseDoc.data();
      
      // Đếm số topics trong forum của course này
      final topicsSnapshot = await firestore
          .collection('forums')
          .doc(courseDoc.id)
          .collection('topics')
          .get();
      
      int totalReplies = 0;
      
      // Đếm tổng số replies
      for (var topicDoc in topicsSnapshot.docs) {
        final topicData = topicDoc.data();
        totalReplies += (topicData['replyCount'] as int? ?? 0);
      }
      
      forums.add({
        'id': courseDoc.id,
        'name': courseData['name'] ?? 'Unknown Course',
        'code': courseData['code'] ?? '',
        'topicCount': topicsSnapshot.docs.length,
        'replyCount': totalReplies,
      });
    }
    
    return forums;
  } catch (e) {
    print('Error loading course forums: $e');
    return [];
  }
});

// ===========================================================================
// STATE MANAGEMENT
// ===========================================================================

class ForumState {
  final bool isLoading;
  final String? error;
  
  const ForumState({
    this.isLoading = false,
    this.error,
  });
  
  ForumState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return ForumState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ===========================================================================
// CONTROLLER
// ===========================================================================

class ForumController extends StateNotifier<ForumState> {
  final ForumRepository _repo;

  ForumController(this._repo) : super(const ForumState());

  /// Create Topic - Sửa để trả về bool và nhận UserModel
  Future<bool> createTopic({
    required String courseId,
    required String title,
    required String content,
    required UserModel currentUser,
    List<String> attachments = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.createTopic(
        courseId: courseId,
        title: title,
        content: content,
        authorId: currentUser.uid,
        authorName: currentUser.name,
        attachments: attachments,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      print('Error creating topic: $e');
      return false;
    }
  }

  /// Update Topic - HÀM MỚI THÊM VÀO
  Future<bool> updateTopic({
    required String courseId,
    required String topicId,
    required String title,
    required String content,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Gọi Firestore để update topic
      await FirebaseFirestore.instance
          .collection('forums')
          .doc(courseId)
          .collection('topics')
          .doc(topicId)
          .update({
        'title': title.trim(),
        'content': content.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      print('Error updating topic: $e');
      return false;
    }
  }

  /// Add Reply - Sửa để trả về bool và nhận UserModel
  /// Note: replyToId và replyToAuthor được hỗ trợ ở UI level nhưng không lưu vào DB
  Future<bool> addReply({
    required String courseId,
    required String topicId,
    required String content,
    required UserModel currentUser,
    String? replyToId,
    String? replyToAuthor,
    List<String> attachments = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.addReply(
        courseId: courseId,
        topicId: topicId,
        content: content,
        authorId: currentUser.uid,
        authorName: currentUser.name,
        replyToId: replyToId,                // ← THÊM DÒNG NÀY
        authorReplyTo: replyToAuthor,        // ← (tùy chọn, để hiển thị "Replying to...")
        attachments: attachments,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      print('Error adding reply: $e');
      return false;
    }
  }

  /// Delete Topic (Instructor only - Content Administrator)
  Future<void> deleteTopic(String courseId, String topicId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.deleteTopic(courseId: courseId, topicId: topicId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Delete Reply (Instructor only - Content Administrator)
  Future<void> deleteReply(String courseId, String topicId, String replyId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.deleteReply(courseId: courseId, topicId: topicId, replyId: replyId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final forumControllerProvider = StateNotifierProvider<ForumController, ForumState>((ref) {
  final repo = ref.watch(forumRepositoryProvider);
  return ForumController(repo);
});