import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Import các model và provider cũ của bạn (giữ nguyên logic)
import '../../../domain/models/user_model.dart';
import '../../../domain/models/conversation_model.dart';
import '../../../domain/models/private_message_model.dart';
import '../../../application/controllers/chat/chat_providers.dart' hide studentSearchQueryProvider, allStudentsProvider;
import '../../../application/controllers/chat/chat_student_providers.dart'; 
import '../../../domain/models/conversation_model.dart';
// ========================================
// CONFIG: FORUM THEME COLORS
// ========================================
class ForumTheme {
  static const bgMain = Color(0xFF0F1720);      // Nền chính tối nhất
  static const bgCard = Color(0xFF1F2937);      // Nền sidebar/header
  static const bgInput = Color(0xFF111827);     // Nền ô nhập liệu
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF9CA3AF); // Grey[400]
  static final border = Colors.grey[800]!;
  
  // Gradient đặc trưng của forum
  static const primaryGradient = LinearGradient(
    colors: [Colors.indigo, Colors.purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ========================================
// MAIN SCREEN: Responsive Messenger Layout
// ========================================
// ========================================
// MAIN SCREEN: Responsive Messenger Layout
// ========================================
class InstructorChatScreen extends ConsumerStatefulWidget {
  const InstructorChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InstructorChatScreen> createState() => _InstructorChatScreenState();
}

class _InstructorChatScreenState extends ConsumerState<InstructorChatScreen> {
  // State: Chỉ giữ user đang chọn
  UserModel? _selectedStudent;

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách hội thoại để check ID khi render ChatWindow bên phải
    final conversationsAsync = ref.watch(myConversationsStreamProvider);

    return Scaffold(
      backgroundColor: ForumTheme.bgMain,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // --- DESKTOP / TABLET (> 800px) ---
          if (constraints.maxWidth > 800) {
            return Row(
              children: [
                // Cột trái: Sidebar
                SizedBox(
                  width: 350,
                  child: _buildSidebar(isMobile: false),
                ),
                VerticalDivider(width: 1, color: ForumTheme.border),
                
                // Cột phải: Khung chat
                Expanded(
                  child: _selectedStudent == null
                      ? _buildWelcomeScreen()
                      : conversationsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator(color: Colors.indigo)),
                          error: (_, __) => _buildWelcomeScreen(), // Fallback nếu lỗi
                          data: (conversations) {
                            // LOGIC TÌM CONVERSATION ID:
                            // Tìm xem user đang chọn có trong list conversation chưa
                            final conversation = conversations.cast<ConversationModel?>().firstWhere(
                              (c) => c != null && c.id.contains(_selectedStudent!.uid), // Check ID khớp
                              orElse: () => null,
                            );
                            
                            // Nếu có thì lấy ID cũ, nếu không thì tạo ID ảo 'new_UID'
                            final activeConvId = conversation?.id ?? 'new_${_selectedStudent!.uid}';

                            return _ChatWindow(
                              key: ValueKey(activeConvId), // Key quan trọng để rebuild khi đổi người
                              conversationId: activeConvId,
                              otherUser: _selectedStudent!,
                            );
                          },
                        ),
                ),
              ],
            );
          } 
          // --- MOBILE ---
          else {
            return _buildSidebar(isMobile: true);
          }
        },
      ),
    );
  }

  // --- Sidebar Component ---
  Widget _buildSidebar({required bool isMobile}) {
    final allStudentsAsync = ref.watch(allStudentsProvider);
    final conversationsAsync = ref.watch(myConversationsStreamProvider);

    return Container(
      color: ForumTheme.bgCard,
      child: Column(
        children: [
          // Header & Search
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: ForumTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.people_alt, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Contacts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ForumTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    ref.read(studentSearchQueryProvider.notifier).state = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    hintStyle: TextStyle(color: ForumTheme.textSecondary),
                    prefixIcon: Icon(Icons.search, color: ForumTheme.textSecondary),
                    filled: true,
                    fillColor: ForumTheme.bgInput,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: ForumTheme.border),

          // Danh sách sinh viên
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final query = ref.watch(studentSearchQueryProvider);
                
                // 1. TRƯỜNG HỢP TÌM KIẾM
                if (query.isNotEmpty) {
                  final searchAsync = ref.watch(searchedStudentsProvider);
                  return searchAsync.when(
                    data: (students) => ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return _StudentItem(
                          student: student,
                          conversation: null,
                          isSelected: _selectedStudent?.uid == student.uid,
                          onTap: () => _handleStudentTap(student, null, isMobile),
                        );
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.indigo)),
                    error: (_,__) => const SizedBox(),
                  );
                }

                // 2. TRƯỜNG HỢP DANH SÁCH MẶC ĐỊNH (MERGE)
                return allStudentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.indigo)),
                  error: (_, __) => Center(child: Text('Error loading list', style: TextStyle(color: Colors.red[400]))),
                  data: (allStudents) {
                    return conversationsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: Colors.indigo)),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (conversations) {
                        
                        // Merge logic
                        final List<Map<String, dynamic>> mergedList = allStudents.map((student) {
                          final conversation = conversations.cast<ConversationModel?>().firstWhere(
                            (c) => c != null && c.id.contains(student.uid),
                            orElse: () => null,
                          );
                          return {
                            'student': student,
                            'conversation': conversation,
                          };
                        }).toList();

                        // Sort
                        mergedList.sort((a, b) {
                          final convA = a['conversation'] as ConversationModel?;
                          final convB = b['conversation'] as ConversationModel?;
                          if (convA != null && convB != null) return convB.lastMessageAt.compareTo(convA.lastMessageAt);
                          if (convA != null) return -1;
                          if (convB != null) return 1;
                          return (a['student'] as UserModel).name.compareTo((b['student'] as UserModel).name);
                        });

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: mergedList.length,
                          separatorBuilder: (ctx, i) => Divider(height: 1, color: ForumTheme.border.withOpacity(0.5), indent: 70),
                          itemBuilder: (context, index) {
                            final item = mergedList[index];
                            final student = item['student'] as UserModel;
                            final conversation = item['conversation'] as ConversationModel?;
                            
                            return _StudentItem(
                              student: student,
                              conversation: conversation,
                              isSelected: _selectedStudent?.uid == student.uid,
                              onTap: () => _handleStudentTap(student, conversation, isMobile),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper xử lý khi bấm vào sinh viên
  void _handleStudentTap(UserModel student, ConversationModel? conversation, bool isMobile) {
    setState(() {
      _selectedStudent = student;
    });

    if (isMobile) {
      final conversationId = conversation?.id ?? 'new_${student.uid}';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: ForumTheme.bgMain,
            appBar: AppBar(
              backgroundColor: ForumTheme.bgCard,
              title: Text(student.name),
              leading: const BackButton(color: Colors.white),
            ),
            body: _ChatWindow(
              conversationId: conversationId,
              otherUser: student,
            ),
          ),
        ),
      );
    }
  }

  // Màn hình chờ
  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ForumTheme.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[800]!, width: 2),
            ),
            child: Icon(Icons.forum_outlined, size: 64, color: Colors.indigo[300]),
          ),
          const SizedBox(height: 24),
          const Text(
            'Select a student',
            style: TextStyle(
              color: ForumTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select from the left list to start messaging',
            style: TextStyle(color: ForumTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ========================================
// COMPONENT: Chat Window (Khung chat chính)
// ========================================
class _ChatWindow extends ConsumerStatefulWidget {
  final String conversationId;
  final UserModel otherUser;

  const _ChatWindow({
    Key? key,
    required this.conversationId,
    required this.otherUser,
  }) : super(key: key);

  @override
  ConsumerState<_ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends ConsumerState<_ChatWindow> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark as read
    Future.microtask(() {
      final myId = ref.read(currentUserIdProvider).valueOrNull;
      if (myId != null) {
        ref.read(chatControllerProvider.notifier).markAsRead(widget.conversationId, myId);
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
  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // 1. Lấy ID của chính mình (Giảng viên) từ Provider
    // (Dùng .valueOrNull để an toàn nếu chưa load xong)
    final currentUserId = ref.read(currentUserIdProvider).valueOrNull;

    if (currentUserId == null) {
      print('User ID not retrieved yet');
      return;
    }

    // 2. Gọi hàm sendMessage với đầy đủ 3 tham số
    ref.read(chatControllerProvider.notifier).sendMessage(
      currentUserId: currentUserId,     // ID của bạn
      otherUserId: widget.otherUser.uid, // ID học sinh (lấy từ widget)
      content: content,
    );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.conversationId));

    return Column(
      children: [
        // 1. Chat Header (Avatar + Name)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: ForumTheme.bgCard,
            border: Border(bottom: BorderSide(color: ForumTheme.border)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.indigo,
                backgroundImage: widget.otherUser.photoUrl != null
                    ? NetworkImage(widget.otherUser.photoUrl!)
                    : null,
                child: widget.otherUser.photoUrl == null
                    ? Text(widget.otherUser.name[0], style: const TextStyle(color: Colors.white))
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.name,
                    style: const TextStyle(
                      color: ForumTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Online', // Logic check online có thể thêm sau
                        style: TextStyle(color: ForumTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.info_outline, color: ForumTheme.textSecondary),
                onPressed: () {}, // Info details
              ),
            ],
          ),
        ),

        // 2. Message List Area
        Expanded(
          child: Container(
            color: ForumTheme.bgMain, // Nền tối nhất cho khu vực chat
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.indigo)),
              error: (_, __) => Center(child: Icon(Icons.error, color: Colors.red[400])),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text('Start the conversation!', style: TextStyle(color: ForumTheme.textSecondary)),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId != widget.otherUser.uid;
                    final showAvatar = index == 0 || messages[index - 1].senderId != message.senderId;

                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      showAvatar: showAvatar,
                      otherUser: widget.otherUser,
                    );
                  },
                );
              },
            ),
          ),
        ),

        // 3. Input Area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ForumTheme.bgCard,
            border: Border(top: BorderSide(color: ForumTheme.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: ForumTheme.textSecondary),
                    filled: true,
                    fillColor: ForumTheme.bgInput,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.sentiment_satisfied_alt, color: Colors.grey),
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: const BoxDecoration(
                  gradient: ForumTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ========================================
// COMPONENT: Item trong Sidebar (Conversation Tile)
// ========================================
class _ConversationItem extends ConsumerWidget {
  final ConversationModel conversation;
  final bool isSelected;
  final Function(UserModel) onTap;

  const _ConversationItem({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserAsync = ref.watch(otherParticipantProvider(conversation));

    return otherUserAsync.when(
      loading: () => const SizedBox(height: 72),
      error: (_, __) => const SizedBox.shrink(),
      data: (otherUser) {
        if (otherUser == null) return const SizedBox.shrink();

        // Style khi được chọn
        final bgColor = isSelected ? Colors.indigo.withOpacity(0.15) : Colors.transparent;
        final borderLeft = isSelected 
            ? const Border(left: BorderSide(color: Colors.indigo, width: 3)) 
            : null;

        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: borderLeft,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            onTap: () => onTap(otherUser),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF374151), // Dark grey
                  backgroundImage: otherUser.photoUrl != null ? NetworkImage(otherUser.photoUrl!) : null,
                  child: otherUser.photoUrl == null
                      ? Text(otherUser.name[0], style: const TextStyle(color: Colors.white))
                      : null,
                ),
                if (!conversation.isRead)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              otherUser.name,
              style: TextStyle(
                color: ForumTheme.textPrimary,
                fontWeight: !conversation.isRead ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    conversation.lastMessageContent,
                    style: TextStyle(
                      color: !conversation.isRead ? Colors.white70 : ForumTheme.textSecondary,
                      fontWeight: !conversation.isRead ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(conversation.lastMessageAt),
                  style: TextStyle(color: ForumTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    // Logic format time đơn giản
    final now = DateTime.now();
    if (now.difference(dateTime).inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    }
    return DateFormat('dd/MM').format(dateTime);
  }
}

// ========================================
// COMPONENT: Chat Bubble (Messenger Style)
// ========================================
class _MessageBubble extends StatelessWidget {
  final PrivateMessageModel message;
  final bool isMe;
  final bool showAvatar;
  final UserModel otherUser;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.otherUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar bên trái (của người khác)
          if (!isMe) ...[
            if (showAvatar)
              CircleAvatar(
                radius: 14,
                backgroundImage: otherUser.photoUrl != null ? NetworkImage(otherUser.photoUrl!) : null,
                backgroundColor: Colors.grey[700],
                child: otherUser.photoUrl == null 
                  ? Text(otherUser.name[0], style: const TextStyle(fontSize: 10, color: Colors.white)) 
                  : null,
              )
            else
              const SizedBox(width: 28), // Placeholder cho avatar để thẳng hàng
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                // Me: Gradient Indigo-Purple, Them: Dark Gray (0xFF374151)
                gradient: isMe ? ForumTheme.primaryGradient : null,
                color: isMe ? null : const Color(0xFF374151),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white, // Chữ luôn trắng trên nền tối/gradient
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          
          // Khoảng trống nếu là tin nhắn của tôi
          if (isMe) const SizedBox(width: 8), 
        ],
      ),
    );
  }
}
// --- THÊM CLASS NÀY VÀO CUỐI FILE instructor_chat_screen.dart ---

class _StudentItem extends StatelessWidget {
  final UserModel student;
  final ConversationModel? conversation;
  final bool isSelected;
  final VoidCallback onTap;

  const _StudentItem({
    required this.student,
    this.conversation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected ? Colors.indigo.withOpacity(0.15) : Colors.transparent;
    final borderLeft = isSelected 
        ? const Border(left: BorderSide(color: Colors.indigo, width: 3)) 
        : null;

    // Logic hiển thị
    final bool hasChat = conversation != null;
    final bool isUnread = hasChat && !conversation!.isRead;
    
    // Nếu chưa chat bao giờ -> Hiện text mời gọi
    final String subtitleText = hasChat 
        ? conversation!.lastMessageContent 
        : '👋 Click to start chat now'; 
    
    final Color subtitleColor = hasChat
        ? (isUnread ? Colors.white : ForumTheme.textSecondary)
        : Colors.indigoAccent; // Màu nổi bật cho người chưa chat

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: borderLeft,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: onTap,
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF374151),
              backgroundImage: student.photoUrl != null ? NetworkImage(student.photoUrl!) : null,
              child: student.photoUrl == null
                  ? Text(student.name[0].toUpperCase(), style: const TextStyle(color: Colors.white))
                  : null,
            ),
            // Chấm đỏ nếu có tin nhắn mới
            if (isUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1F2937), width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          student.name,
          style: TextStyle(
            color: ForumTheme.textPrimary,
            fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                subtitleText,
                style: TextStyle(
                  color: subtitleColor,
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                  fontStyle: hasChat ? FontStyle.normal : FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Chỉ hiện giờ nếu đã từng chat
            if (hasChat) ...[
              const SizedBox(width: 8),
              Text(
                _formatTime(conversation!.lastMessageAt),
                style: TextStyle(color: ForumTheme.textSecondary, fontSize: 11),
              ),
            ]
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    if (now.difference(dateTime).inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    }
    return DateFormat('dd/MM').format(dateTime);
  }
}