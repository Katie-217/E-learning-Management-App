import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/comment_model.dart';
import '../../../domain/models/user_model.dart'; // Import user model của bạn
import '../../../data/repositories/announcement/announcement_repository.dart';
// ===========================================================================
// 1. STREAMS PROVIDERS (Dữ liệu Realtime)
// ===========================================================================

// Provider lấy danh sách thông báo theo CourseId
final announcementListProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, courseId) {
  final repo = ref.watch(announcementRepositoryProvider);
  return repo.getAnnouncementsStream(courseId);
});

// Provider lấy danh sách comments theo AnnouncementId
final commentListProvider = StreamProvider.family<List<CommentModel>, String>((ref, announcementId) {
  final repo = ref.watch(announcementRepositoryProvider);
  return repo.getCommentsStream(announcementId);
});

// ===========================================================================
// 2. ANNOUNCEMENT ACTION CONTROLLER
// ===========================================================================

class AnnouncementController extends StateNotifier<AsyncValue<void>> {
  final AnnouncementRepository _repo;
  final Ref _ref;

  AnnouncementController(this._repo, this._ref) : super(const AsyncValue.data(null));

  /// Hàm gọi khi sinh viên mở xem chi tiết thông báo
  /// (Logic Auto-Tracking nằm ở đây)
  Future<void> markAsViewed({
    required String announcementId,
    required String courseId,
    required UserModel currentUser, // Lấy từ UserProvider
    required String? groupId,       // Lấy từ logic lớp học phần
  }) async {
    // Chỉ tracking nếu user là Student
    if (!currentUser.isStudent) return;

    try {
      // Gọi repository để upsert tracking data
      await _repo.trackView(
        announcementId: announcementId,
        studentId: currentUser.uid, // Dùng UID làm studentId (theo discussion cũ)
        courseId: courseId,
        groupId: groupId ?? 'ungrouped', // Xử lý trường hợp không có nhóm
      );
    } catch (e, st) {
      // Tracking thất bại không nên chặn UI, chỉ log lỗi
      print('Tracking view error: $e');
    }
  }

  /// Hàm gọi khi sinh viên bấm nút download file
  Future<void> markAsDownloaded({
    required String announcementId,
    required String courseId,
    required UserModel currentUser,
    required String? groupId,
  }) async {
    if (!currentUser.isStudent) return;

    try {
      await _repo.trackDownload(
        announcementId: announcementId,
        studentId: currentUser.uid,
        courseId: courseId,
        groupId: groupId ?? 'ungrouped',
      );
    } catch (e) {
      print('Tracking download error: $e');
    }
  }

  /// Gửi bình luận
  Future<void> sendComment({
    required String announcementId,
    required String courseId,
    required String content,
    required UserModel currentUser,
  }) async {
    state = const AsyncValue.loading();
    try {
      final comment = CommentModel(
        id: '', // Repository sẽ tạo ID
        announcementId: announcementId,
        courseId: courseId,
        content: content,
        authorId: currentUser.uid,
        authorName: currentUser.displayName,
        authorRole: currentUser.role.name, // 'student' hoặc 'instructor'
        createdAt: DateTime.now(),
      );

      await _repo.addComment(comment);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Create a new announcement
  Future<bool> createAnnouncement({
    required String courseId,
    required String title,
    required String content,
    required UserModel currentUser,
  }) async {
    // Set loading state
    state = const AsyncValue.loading();

    try {
      // Prepare data map
      final announcementData = {
        'courseId': courseId,
        'title': title,
        'content': content,
        'authorId': currentUser.uid,
        'authorName': currentUser.displayName,
        'authorAvatar': currentUser.photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'attachmentCount': 0, // Default
        'viewCount': 0,       // Default
      };

      // Call repository
      await _repo.addAnnouncement(
        courseId: courseId,
        data: announcementData,
      );

      // Success
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      // Error
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // ... inside AnnouncementController class

  /// Update announcement
  Future<bool> updateAnnouncement({
    required String courseId,
    required String announcementId,
    required String title,
    required String content,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateAnnouncement(
        courseId: courseId,
        announcementId: announcementId,
        title: title,
        content: content,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete announcement
  Future<void> deleteAnnouncement({
    required String courseId,
    required String announcementId,
  }) async {
    // We don't necessarily need to set loading state for delete 
    // because the item will disappear from the stream automatically.
    try {
      await _repo.deleteAnnouncement(
        courseId: courseId,
        announcementId: announcementId,
      );
    } catch (e) {
      // Handle error (e.g., show toast)
      print("Delete failed: $e");
    }
  }
}

// Provider cho Controller
final announcementControllerProvider = StateNotifierProvider<AnnouncementController, AsyncValue<void>>((ref) {
  final repo = ref.watch(announcementRepositoryProvider);
  return AnnouncementController(repo, ref);
});
