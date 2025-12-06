// FILE: application/controllers/chat/chat_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/chat/chat_repository.dart';

class ChatController extends StateNotifier<AsyncValue<void>> {
  final IChatRepository _chatRepository;

  ChatController({required IChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const AsyncData(null));

  // ==========================================================
  // CÁCH CŨ (GIỮ NGUYÊN ĐỂ KHÔNG LỖI BÊN GIẢNG VIÊN)
  // Giảng viên vẫn dùng hàm này, không cần sửa code bên đó
  // ==========================================================
  Future<void> sendMessage({
    required String currentUserId,
    required String otherUserId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;
    state = const AsyncLoading();
    try {
      final conversationId = await _chatRepository.startOrGetConversation(
        currentUserId,
        otherUserId
      );
      await _chatRepository.sendMessage(
        conversationId: conversationId,
        senderId: currentUserId,
        content: content,
      );
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  // ==========================================================
  // CÁCH MỚI (DÀNH RIÊNG CHO SINH VIÊN - GIAO DIỆN MESSENGER)
  // Tách hàm để xử lý logic mượt hơn
  // ==========================================================
  
  // 1. Chỉ tạo conversation (khi bấm nút "Bắt đầu")
  Future<String?> initializeConversation({
    required String currentUserId,
    required String otherUserId,
  }) async {
    state = const AsyncLoading();
    try {
      final conversationId = await _chatRepository.startOrGetConversation(
        currentUserId,
        otherUserId
      );
      state = const AsyncData(null);
      return conversationId;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return null;
    }
  }

  // 2. Chỉ gửi tin nhắn (khi đã vào màn hình chat)
  Future<void> sendTextMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;
    // Không set state loading để tránh reload cả màn hình chat
    try {
      await _chatRepository.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        content: content,
      );
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow; 
    }
  }

  // Hàm tiện ích
  Future<void> markAsRead(String conversationId, String currentUserId) async {
    try {
      await _chatRepository.markConversationAsRead(conversationId, currentUserId);
    } catch (e) {
      // Ignore error
    }
  }
}