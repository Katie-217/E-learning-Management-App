import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Import models & providers cũ
import '../../../domain/models/user_model.dart';
import '../../../domain/models/private_message_model.dart';
import '../../../application/controllers/chat/chat_providers.dart';

// ========================================
// RE-DESIGNED: Student Chat - Messenger Style (Dark Forum Theme)
// ========================================
class StudentChatScreen extends ConsumerStatefulWidget {
  const StudentChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends ConsumerState<StudentChatScreen> {
  // Màu sắc lấy từ instructor_forum_screen.dart
  static const Color _bgCard = Color(0xFF1F2937);      // Nền chính
  static const Color _bgInput = Color(0xFF111827);     // Nền input/search
  static const Color _textGrey = Color(0xFF9CA3AF);    // Grey[400]
  static const Color _bubbleOther = Color(0xFF374151); // Màu bubble người khác
  
  @override
  Widget build(BuildContext context) {
    // 1. Lấy thông tin giảng viên (admin)
    final instructorAsync = ref.watch(singleInstructorProvider);

    return Scaffold(
      backgroundColor: _bgInput, // Nền tổng thể tối thẫm
      body: instructorAsync.when(
        data: (instructor) {
          if (instructor == null) return _buildNoInstructor();

          // 2. Lấy conversation ID
          final conversationAsync = ref.watch(
            studentConversationWithInstructorProvider(instructor.uid)
          );

          return Row(
            children: [
              // --- LEFT SIDEBAR (Danh sách hội thoại) ---
              Container(
                width: 350, // Fixed width cho sidebar
                decoration: BoxDecoration(
                  color: _bgCard,
                  border: Border(right: BorderSide(color: Colors.grey[800]!)),
                ),
                child: Column(
                  children: [
                    _buildSidebarHeader(),
                    Expanded(
                      child: _buildContactItem(instructor, isActive: true),
                    ),
                  ],
                ),
              ),

              // --- RIGHT MAIN CHAT ---
              Expanded(
                child: conversationAsync.when(
                  data: (conversationId) {
                    if (conversationId == null) {
                      return _buildStartChatView(instructor);
                    }
                    return ChatDetailScreen(
                      conversationId: conversationId,
                      otherUser: instructor,
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.indigo),
                  ),
                  error: (error, stack) => _buildErrorView(error, instructor),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.indigo)),
        error: (error, stack) => _buildErrorLoadingInstructor(error),
      ),
    );
  }

  // --- Sidebar Components ---

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.indigo, Colors.purple],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Tin nhắn',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(UserModel instructor, {required bool isActive}) {
    // Giả lập giao diện list item giống Card trong Forum nhưng nhỏ gọn
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.indigo.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive ? Border.all(color: Colors.indigo.withOpacity(0.3)) : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _bgInput,
                  backgroundImage: instructor.photoUrl != null && instructor.photoUrl!.isNotEmpty
                      ? NetworkImage(instructor.photoUrl!)
                      : null,
                  child: (instructor.photoUrl == null || instructor.photoUrl!.isEmpty)
                      ? Text(
        // SỬA TẠI ĐÂY
        instructor.displayName.isNotEmpty ? instructor.displayName[0].toUpperCase() : 'GV',
        style: const TextStyle(fontSize: 32, color: Colors.white),
      )
                      : null,
                ),
                // Online indicator dot
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green[400],
                      shape: BoxShape.circle,
                      border: Border.all(color: _bgCard, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              instructor.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Icon(Icons.school, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Giảng viên',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Main Area States ---

  Widget _buildNoInstructor() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.person_off_outlined, size: 80, color: _textGrey),
          SizedBox(height: 16),
          Text(
            'Chưa có giảng viên phụ trách',
            style: TextStyle(fontSize: 18, color: _textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildStartChatView(UserModel instructor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Colors.indigo, Colors.purple]),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: _bgCard,
              backgroundImage: instructor.photoUrl != null && instructor.photoUrl!.isNotEmpty
                  ? NetworkImage(instructor.photoUrl!)
                  : null,
              child: (instructor.photoUrl == null || instructor.photoUrl!.isEmpty)
                  ? Text(
        instructor.displayName.isNotEmpty 
            ? instructor.displayName[0].toUpperCase() 
            : 'GV', // ✅ Fallback nếu tên rỗng
        style: const TextStyle(fontSize: 32, color: Colors.white),
      )
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            instructor.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bắt đầu trao đổi việc học tập với giảng viên',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _startConversation(instructor),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Tạo cuộc hội thoại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(Object error, UserModel instructor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 60, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text('Có lỗi xảy ra', style: TextStyle(color: Colors.red[400])),
          TextButton(
            onPressed: () => ref.refresh(studentConversationWithInstructorProvider(instructor.uid)),
            child: const Text('Thử lại', style: TextStyle(color: Colors.indigoAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorLoadingInstructor(Object error) {
    return const Center(child: Text('Lỗi tải giảng viên', style: TextStyle(color: Colors.red)));
  }

Future<void> _startConversation(UserModel instructor) async {
    // 1. Lấy Current User ID từ Provider
    // Lưu ý: .value có thể null nếu chưa load xong, nên dùng .asData?.value hoặc check null
    final currentUserId = ref.read(currentUserIdProvider).value;

    if (currentUserId == null) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.indigo),
      ),
    );

    try {
      // 2. Gọi Controller với đúng tham số
      final conversationId = await ref
          .read(chatControllerProvider.notifier)
          .initializeConversation(
            currentUserId: currentUserId,
            otherUserId: instructor.uid,
          );

      if (!mounted) return;
      Navigator.pop(context); // Đóng loading

      if (conversationId != null) {
        // Refresh provider để UI tự động chuyển sang màn hình Chat
        // Sử dụng unused result để đảm bảo refresh
        ref.invalidate(studentConversationWithInstructorProvider(instructor.uid));
      } else {
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }
}

// ========================================
// CHAT DETAIL SCREEN (Messenger Style)
// ========================================
class ChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final UserModel otherUser;

  const ChatDetailScreen({
    Key? key,
    required this.conversationId,
    required this.otherUser,
  }) : super(key: key);

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  
  // Theme colors
  static const Color _bgCard = Color(0xFF1F2937);
  static const Color _bgInput = Color(0xFF111827);

 @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final myId = ref.read(currentUserIdProvider).value;
      if (myId != null) {
        // Gọi repo trực tiếp hoặc qua controller nếu controller hỗ trợ
        // Ở đây gọi repo thông qua provider cho nhanh gọn vì controller hàm markAsRead ở trên chưa hoàn thiện logic ID
        ref.read(chatRepositoryProvider).markConversationAsRead(widget.conversationId, myId);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.conversationId));

    return Column(
      children: [
        // --- CHAT HEADER ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: _bgCard,
            border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
          // --- Trong ChatDetailScreen ---
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.otherUser.photoUrl != null && widget.otherUser.photoUrl!.isNotEmpty
                ? NetworkImage(widget.otherUser.photoUrl!)
                : null,
            backgroundColor: Colors.indigo,
            child: (widget.otherUser.photoUrl == null || widget.otherUser.photoUrl!.isEmpty)
                // SỬA TẠI ĐÂY: Kiểm tra isNotEmpty trước khi lấy [0]
                ? Text(
                    widget.otherUser.displayName.isNotEmpty 
                        ? widget.otherUser.displayName[0].toUpperCase() 
                        : '?', 
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Đang hoạt động',
                    style: TextStyle(color: Colors.green[400], fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.info_outline, color: Colors.grey[400]),
                onPressed: () {}, // Info action placeholder
              )
            ],
          ),
        ),

        // --- MESSAGES LIST ---
        Expanded(
          child: Container(
            color: const Color(0xFF111827), // Nền vùng chat tối hơn sidebar
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.waving_hand, size: 48, color: Colors.grey[700]),
                        const SizedBox(height: 16),
                        Text(
                          'Hãy nói xin chào!',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(24),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // Kiểm tra an toàn index
                    if (index >= messages.length) return const SizedBox.shrink();

                    final message = messages[index];
                    final isMe = message.senderId != widget.otherUser.uid;
                    
                    // Logic kiểm tra tin nhắn liền kề an toàn hơn
                    bool isSequence = false;
                    if (index < messages.length - 1) {
                      // Chỉ kiểm tra phần tử tiếp theo nếu index chưa phải là cuối cùng
                      isSequence = messages[index + 1].senderId == message.senderId;
                    }

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      showAvatar: !isMe && !isSequence,
                      otherUser: widget.otherUser,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.indigo)),
              error: (e, s) => Center(child: Text('Lỗi: $e', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ),

        // --- INPUT AREA ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _bgCard,
            border: Border(top: BorderSide(color: Colors.grey[800]!)),
          ),
          child: Row(
            children: [
              // Nút đính kèm ảnh (Placeholder UI)
              IconButton(
                icon: Icon(Icons.image, color: Colors.indigo[300]),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              
              // Input Field
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: _bgInput, // Style giống search bar forum
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Send Button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.indigo, Colors.purple]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 20, height: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // 1. Lấy Current User ID
    final currentUserId = ref.read(currentUserIdProvider).value;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi xác thực: Không tìm thấy ID người dùng')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // 2. Gọi Controller gửi tin
      await ref.read(chatControllerProvider.notifier).sendTextMessage(
            conversationId: widget.conversationId,
            senderId: currentUserId, // QUAN TRỌNG: Phải truyền ID người gửi
            content: content,
          );

      _messageController.clear();
      
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi tin: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}

// ========================================
// MESSAGE BUBBLE - FORUM STYLE
// ========================================
class MessageBubble extends StatelessWidget {
  final PrivateMessageModel message;
  final bool isMe;
  final bool showAvatar;
  final UserModel otherUser;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.otherUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: showAvatar || isMe ? 8 : 2),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
// --- Trong MessageBubble ---
            if (showAvatar)
              CircleAvatar(
                radius: 14,
                backgroundImage: otherUser.photoUrl != null && otherUser.photoUrl!.isNotEmpty
                    ? NetworkImage(otherUser.photoUrl!)
                    : null,
                backgroundColor: Colors.indigo,
                child: (otherUser.photoUrl == null || otherUser.photoUrl!.isEmpty)
                    // SỬA TẠI ĐÂY: Thêm kiểm tra isNotEmpty
                    ? Text(
                        otherUser.displayName.isNotEmpty ? otherUser.displayName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 10, color: Colors.white)
                      )
                    : null,
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                // Style Bubble
                gradient: isMe 
                  ? const LinearGradient(colors: [Colors.indigo, Colors.purple]) // Gradient cho Me
                  : null,
                color: isMe ? null : const Color(0xFF374151), // Màu tối xám cho Others
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: Colors.white, // Text luôn trắng trên nền tối/gradient
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.sentAt),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[400],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}