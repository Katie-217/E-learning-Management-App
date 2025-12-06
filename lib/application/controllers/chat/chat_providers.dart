import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import Models & Repo
import '../../../domain/models/conversation_model.dart';
import '../../../domain/models/private_message_model.dart';
import '../../../domain/models/user_model.dart';
import '../../../data/repositories/chat/chat_repository.dart';

// ✅ Import EXISTING AuthProvider
import '../auth/auth_provider.dart'; 

// ========================================
// PROVIDERS
// ========================================

// ✅ 1. Sử dụng existing AuthProvider
// QUAN TRỌNG: Phải là singleton instance được dùng trong toàn app
final authProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  final provider = AuthProvider();
  // ✅ CRITICAL: Check auth state khi provider được tạo
  provider.checkAuthState();
  return provider;
});

// 2. Chat Repository Provider
final chatRepositoryProvider = Provider<IChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance);
});

// 3. Stream lấy Inbox (Danh sách chat)
final myConversationsStreamProvider = StreamProvider.autoDispose<List<ConversationModel>>((ref) {
  final auth = ref.watch(authProvider);
  final repo = ref.watch(chatRepositoryProvider);
  
  if (auth.currentUser == null) return const Stream.empty();
  return repo.getConversationsStream(auth.currentUser!.uid);
});

// 4. Stream lấy tin nhắn chi tiết
final chatMessagesStreamProvider = StreamProvider.autoDispose.family<List<PrivateMessageModel>, String>((ref, conversationId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getMessagesStream(conversationId);
});

// 5. Provider lấy thông tin người chat cùng (Tên, Avatar)
final otherParticipantProvider = FutureProvider.autoDispose.family<UserModel?, ConversationModel>((ref, conversation) async {
  final auth = ref.read(authProvider);
  final repo = ref.read(chatRepositoryProvider);
  final myId = auth.currentUser?.uid;

  if (myId == null) return null;

  final otherId = conversation.getOtherParticipantId(myId);
  if (otherId.isNotEmpty) {
    return repo.getUserProfile(otherId);
  }
  return null;
});

// ========================================
// ✅ OPTIMIZED: Student List Provider với Caching
// ========================================

/// Provider lấy danh sách SINH VIÊN cho Giảng viên
/// ✅ Caching: Tự động cache kết quả
/// ✅ Auto-dispose: Tự động cleanup khi không dùng
/// ✅ Invalidate: Có thể force refresh
final myStudentsProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  // ✅ Watch auth provider để tự động rebuild khi user thay đổi
  final auth = ref.watch(authProvider);
  final user = auth.currentUser;

  print('╔════════════════════════════════════╗');
  print('║  myStudentsProvider ĐƯỢC GỌI       ║');
  print('╠════════════════════════════════════╣');
  print('║ UID: ${user?.uid}');
  print('║ Email: ${user?.email}');
  print('║ Name: ${user?.name}');
  print('║ Role: ${user?.role}');
  print('║ isInstructor: ${user?.isInstructor}');
  print('║ isLoading: ${auth.isLoading}');
  print('╚════════════════════════════════════╝');

  // ✅ Wait for auth to finish loading
  if (auth.isLoading) {
    print('⏳ Waiting for auth to finish loading...');
    // Return empty list temporarily, will rebuild when loading completes
    await Future.delayed(const Duration(milliseconds: 100));
    throw Exception('Auth still loading'); // This will trigger rebuild
  }

  if (user == null) {
    print('❌ BLOCKED: user == null (not authenticated)');
    return [];
  }
  
  if (!user.isInstructor) {
    print('❌ BLOCKED: !user.isInstructor (role: ${user.role})');
    return [];
  }

  print('✅ PASSED: Calling repo.getMyStudents(${user.uid})');
  final repo = ref.watch(chatRepositoryProvider);
  
  // ✅ Repository sẽ dùng StudentRepository.getAllStudents()
  return repo.getMyStudents(user.uid);
});

/// ✅ OPTIONAL: Cached version với manual refresh
/// Sử dụng StateNotifier để có thể refresh manually
class StudentsListNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final IChatRepository _repository;
  final String _instructorId;
  
  StudentsListNotifier(this._repository, this._instructorId) 
      : super(const AsyncValue.loading()) {
    loadStudents();
  }
  
  Future<void> loadStudents() async {
    state = const AsyncValue.loading();
    
    try {
      final students = await _repository.getMyStudents(_instructorId);
      state = AsyncValue.data(students);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  // ✅ Force refresh khi cần
  Future<void> refresh() async {
    await loadStudents();
  }
}

/// Provider cho cached students list
final cachedStudentsProvider = StateNotifierProvider.autoDispose<StudentsListNotifier, AsyncValue<List<UserModel>>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  final auth = ref.watch(authProvider);
  final instructorId = auth.currentUser?.uid ?? '';
  
  return StudentsListNotifier(repo, instructorId);
});

// ========================================
// CONTROLLER
// ========================================

/// Controller xử lý hành động (Gửi tin, tạo chat)
final chatControllerProvider = StateNotifierProvider<ChatController, AsyncValue<void>>((ref) {
  return ChatController(ref.watch(chatRepositoryProvider), ref.watch(authProvider));
});

class ChatController extends StateNotifier<AsyncValue<void>> {
  final IChatRepository _repository;
  final AuthProvider _authProvider;

  ChatController(this._repository, this._authProvider) : super(const AsyncData(null));

  Future<void> sendMessage(String conversationId, String content) async {
    final user = _authProvider.currentUser;
    if (user == null || content.trim().isEmpty) return;

    state = const AsyncLoading();
    try {
      await _repository.sendMessage(
        conversationId: conversationId, 
        senderId: user.uid, 
        content: content
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<String?> startConversation(String otherUserId) async {
    final user = _authProvider.currentUser;
    if (user == null) return null;

    state = const AsyncLoading();
    try {
      final conversationId = await _repository.startOrGetConversation(user.uid, otherUserId);
      state = const AsyncData(null);
      return conversationId;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow; 
    }
  }

  Future<void> markAsRead(String conversationId) async {
    final user = _authProvider.currentUser;
    if (user != null) {
      await _repository.markConversationAsRead(conversationId, user.uid);
    }
  }
}