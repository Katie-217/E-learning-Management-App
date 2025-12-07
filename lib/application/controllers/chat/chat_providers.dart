import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/conversation_model.dart';
import '../../../domain/models/private_message_model.dart';
import '../../../domain/models/user_model.dart';
import '../../../data/repositories/chat/chat_repository.dart';
import 'chat_controller.dart';

// ========================================
// PROVIDERS
// ========================================

final chatRepositoryProvider = Provider<IChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance);
});

// ✅ Provider để lấy UID từ SharedPreferences với đúng key
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // ✅ ĐÚNG KEY: 'user_uid' (theo user_session_service.dart)
    String? uid = prefs.getString('user_uid');
    
    if (uid == null || uid.isEmpty) {

      
      // Debug: In ra tất cả keys
      final allKeys = prefs.getKeys();

      
      // Kiểm tra các thông tin khác
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final email = prefs.getString('user_email');
      final role = prefs.getString('user_role');

      
      return null;
    }
    

    return uid;
    
  } catch (e, stackTrace) {

    return null;
  }
});

// Stream lấy Inbox (Danh sách chat)
final myConversationsStreamProvider = StreamProvider.autoDispose<List<ConversationModel>>((ref) async* {
  final repo = ref.watch(chatRepositoryProvider);
  
  // ✅ Lấy UID từ SharedPreferences
  final uidAsync = await ref.watch(currentUserIdProvider.future);
  
  if (uidAsync == null || uidAsync.isEmpty) {
    yield [];
    return;
  }
  
  
  yield* repo.getConversationsStream(uidAsync);
});

// Stream lấy tin nhắn chi tiết
final chatMessagesStreamProvider = StreamProvider.autoDispose.family<List<PrivateMessageModel>, String>((ref, conversationId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getMessagesStream(conversationId);
});

// Provider lấy thông tin người chat cùng
final otherParticipantProvider = FutureProvider.autoDispose.family<UserModel?, ConversationModel>((ref, conversation) async {
  final repo = ref.watch(chatRepositoryProvider);
  
  // ✅ Lấy UID từ SharedPreferences
  final myId = await ref.watch(currentUserIdProvider.future);
  
  if (myId == null || myId.isEmpty) {
    return null;
  }
  
  final otherId = conversation.getOtherParticipantId(myId);
  
  if (otherId.isNotEmpty) {
    return repo.getUserProfile(otherId);
  }
  return null;
});

// Provider lấy tất cả sinh viên
final allStudentsProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  
  // ✅ Lấy UID từ SharedPreferences
  final instructorId = await ref.watch(currentUserIdProvider.future);
  
  if (instructorId == null || instructorId.isEmpty) {
    return [];
  }
  
  return repo.getMyStudents(instructorId);
});

// Provider cho search query
final studentSearchQueryProvider = StateProvider<String>((ref) => '');

// ========================================
// PROVIDERS CHO STUDENT
// ========================================

// Provider lấy thông tin giảng viên duy nhất (admin)
final singleInstructorProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  
  try {
    // Lấy admin user (uid = 0VN0wPukCUKLD7FmMWXm)
    const adminUid = '0VN0wPukCUKLD7FmMWXm';
    final instructor = await repo.getUserProfile(adminUid);
    
    if (instructor != null) {
    } else {
    }
    
    return instructor;
  } catch (e) {
    return null;
  }
});

// Provider kiểm tra/lấy conversation ID giữa student và instructor
final studentConversationWithInstructorProvider = FutureProvider.autoDispose.family<String?, String>(
  (ref, instructorUid) async {
    final repo = ref.watch(chatRepositoryProvider);
    final myId = await ref.watch(currentUserIdProvider.future);
    
    if (myId == null || myId.isEmpty) {
      return null;
    }
    
    try {
      // Tạo conversation ID theo format
      final ids = [myId, instructorUid]..sort();
      final conversationId = 'chat_${ids[0]}_${ids[1]}';
      
      
      // Kiểm tra conversation có tồn tại không
      final conversations = await repo.getConversationsStream(myId).first;
      final exists = conversations.any((c) => c.id == conversationId);
      
      if (exists) {
        return conversationId;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  },
);

// Provider cấp phát ChatController
final chatControllerProvider = StateNotifierProvider<ChatController, AsyncValue<void>>((ref) {
  // Lấy repo từ provider
  final chatRepository = ref.watch(chatRepositoryProvider);
  
  // Trả về instance của ChatController (đã định nghĩa ở Bước 1)
  return ChatController(chatRepository: chatRepository);
});