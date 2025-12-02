import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/comment_model.dart';
import '../../../domain/models/user_model.dart';
import '../../../data/repositories/announcement/announcement_repository.dart';

// ===========================================================================
// 1. STREAMS PROVIDERS (Dữ liệu Realtime)
// ===========================================================================

// Provider lấy danh sách thông báo theo CourseId
final announcementListProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, courseId) {
  final repo = ref.watch(AnnouncementRepositoryProvider);
  return repo.getAnnouncementsStream(courseId);
});

// Provider lấy danh sách comments theo AnnouncementId
final commentListProvider = StreamProvider.family<List<CommentModel>, String>((ref, announcementId) {
  final repo = ref.watch(AnnouncementRepositoryProvider);
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
    required UserModel currentUser,
  }) async {
    // Chỉ tracking nếu user là Student
    if (!currentUser.isStudent) return;

    try {
      await _repo.trackView(
        announcementId: announcementId,
        studentId: currentUser.uid,
        courseId: courseId,
      );
    } catch (e) {
      // Tracking thất bại không nên chặn UI, chỉ log lỗi
      print('Tracking view error: $e');
    }
  }

  /// Hàm gọi khi sinh viên bấm nút download file
  Future<void> markAsDownloaded({
    required String announcementId,
    required String courseId,
    required UserModel currentUser,
  }) async {
    if (!currentUser.isStudent) return;

    try {
      await _repo.trackDownload(
        announcementId: announcementId,
        studentId: currentUser.uid,
        courseId: courseId,
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
      await _repo.addComment(
        announcementId: announcementId,
        courseId: courseId,
        content: content,
        authorId: currentUser.uid,
        authorName: currentUser.displayName,
        authorRole: currentUser.role.name,
      );
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Create a new announcement - WITHOUT isPinned
  Future<bool> createAnnouncement({
    required String courseId,
    required String title,
    required String content,
    required UserModel currentUser,
    List<Map<String, dynamic>> attachments = const [],
    List<String> targetGroupIds = const [],
  }) async {
    state = const AsyncValue.loading();

    try {
      await _repo.createAnnouncement(
        courseId: courseId,
        title: title,
        content: content,
        authorId: currentUser.uid,
        authorName: currentUser.displayName,
        authorAvatar: currentUser.photoUrl,
        attachments: attachments,
        targetGroupIds: targetGroupIds,
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Update announcement - WITHOUT isPinned
  Future<bool> updateAnnouncement({
    required String courseId,
    required String announcementId,
    required String title,
    required String content,
    List<Map<String, dynamic>>? attachments,
    List<String>? targetGroupIds,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateAnnouncement(
        courseId: courseId,
        announcementId: announcementId,
        title: title,
        content: content,
        attachments: attachments,
        targetGroupIds: targetGroupIds,
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
    try {
      await _repo.deleteAnnouncement(
        courseId: courseId,
        announcementId: announcementId,
      );
    } catch (e) {
      print("Delete failed: $e");
    }
  }
}

// Provider cho Controller
final announcementControllerProvider = StateNotifierProvider<AnnouncementController, AsyncValue<void>>((ref) {
  final repo = ref.watch(AnnouncementRepositoryProvider);
  return AnnouncementController(repo, ref);
});