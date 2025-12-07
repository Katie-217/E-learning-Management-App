import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Import models & providers
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
  // Colors from instructor_forum_screen.dart
  static const Color _bgCard = Color(0xFF1F2937);      // Main background
  static const Color _bgInput = Color(0xFF111827);     // Input/search background
  static const Color _textGrey = Color(0xFF9CA3AF);    // Grey[400]
  static const Color _bubbleOther = Color(0xFF374151); // Other user's bubble color
  
  @override
  Widget build(BuildContext context) {
    // 1. Get instructor (admin) information
    final instructorAsync = ref.watch(singleInstructorProvider);

    return Scaffold(
      backgroundColor: _bgInput, // Overall dark background
      body: instructorAsync.when(
        data: (instructor) {
          if (instructor == null) return _buildNoInstructor();

          // 2. Get conversation ID
          final conversationAsync = ref.watch(
            studentConversationWithInstructorProvider(instructor.uid)
          );

          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool showSidebar = constraints.maxWidth > 600;

              final Widget chatWidget = conversationAsync.when(
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
              );

              if (!showSidebar) {
                return chatWidget;
              }

              return Row(
                children: [
                  // --- LEFT SIDEBAR (Conversation list) ---
                  Container(
                    width: 350, // Fixed width for sidebar
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
                    child: chatWidget,
                  ),
                ],
              );
            },
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
            'Messages',
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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.indigo.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: Colors.indigo.withOpacity(0.3)) : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: _bgInput,
            backgroundImage: instructor.photoUrl != null && instructor.photoUrl!.isNotEmpty
                ? NetworkImage(instructor.photoUrl!)
                : null,
            child: (instructor.photoUrl == null || instructor.photoUrl!.isEmpty)
                ? Text(
                    instructor.displayName.isNotEmpty ? instructor.displayName[0].toUpperCase() : 'IN',
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  )
                : null,
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
                'Instructor',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
        ),
      ),
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
            'No assigned instructor yet',
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
                          : 'IN', // ✅ Fallback if name is empty
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
            'Start discussing learning matters with the instructor',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _startConversation(instructor),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Create conversation'),
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
          Text('An error occurred', style: TextStyle(color: Colors.red[400])),
          TextButton(
            onPressed: () => ref.refresh(studentConversationWithInstructorProvider(instructor.uid)),
            child: const Text('Try again', style: TextStyle(color: Colors.indigoAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorLoadingInstructor(Object error) {
    return const Center(child: Text('Error loading instructor', style: TextStyle(color: Colors.red)));
  }

  Future<void> _startConversation(UserModel instructor) async {
    // 1. Get Current User ID from Provider
    // Note: .value may be null if not loaded yet, so use .asData?.value or check null
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
      // 2. Call Controller with correct parameters
      final conversationId = await ref
          .read(chatControllerProvider.notifier)
          .initializeConversation(
            currentUserId: currentUserId,
            otherUserId: instructor.uid,
          );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (conversationId != null) {
        // Refresh provider so UI automatically switches to Chat screen
        // Use unused result to ensure refresh
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
        // Call repo directly or through controller if controller supports
        // Here call repo through provider for simplicity since controller markAsRead function above is not complete with ID logic
        ref.read(chatRepositoryProvider).markConversationAsRead(widget.conversationId, myId);
      }
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
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
              // --- In ChatDetailScreen ---
              CircleAvatar(
                radius: 20,
                backgroundImage: widget.otherUser.photoUrl != null && widget.otherUser.photoUrl!.isNotEmpty
                    ? NetworkImage(widget.otherUser.photoUrl!)
                    : null,
                backgroundColor: Colors.indigo,
                child: (widget.otherUser.photoUrl == null || widget.otherUser.photoUrl!.isEmpty)
                    ?  Text(
                        widget.otherUser.displayName.isNotEmpty 
                            ? widget.otherUser.displayName[0].toUpperCase() 
                            : '?',  // ✅ MUST ADD THIS LINE
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
                ],
              ),
            ],
          ),
        ),

        // --- MESSAGES LIST ---
        Expanded(
          child: Container(
            color: const Color(0xFF111827), // Chat area background darker than sidebar
            child: messagesAsync.when(
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.waving_hand, size: 48, color: Colors.grey[700]),
                        const SizedBox(height: 16),
                        Text(
                          'Say hello!',
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
                  physics: const BouncingScrollPhysics(),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // Safe index check
                    if (index >= messages.length) return const SizedBox.shrink();

                    final message = messages[index];
                    final isMe = message.senderId != widget.otherUser.uid;
                    
                    // Safer logic for checking consecutive messages
                    bool isSequence = false;
                    if (index < messages.length - 1) {
                      // Only check next element if index is not the last
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
              error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
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
              
              // Input Field
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter message...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: _bgInput, // Style like forum search bar
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

    // 1. Get Current User ID
    final currentUserId = ref.read(currentUserIdProvider).value;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error: User ID not found')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // 2. Call Controller to send message
      await ref.read(chatControllerProvider.notifier).sendTextMessage(
            conversationId: widget.conversationId,
            senderId: currentUserId, // IMPORTANT: Must pass sender ID
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
        SnackBar(content: Text('Message sending error: $e')),
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
            if (showAvatar)
              CircleAvatar(
                radius: 14,
                backgroundImage: otherUser.photoUrl != null && otherUser.photoUrl!.isNotEmpty
                    ? NetworkImage(otherUser.photoUrl!)
                    : null,
                backgroundColor: Colors.indigo,
                child: (otherUser.photoUrl == null || otherUser.photoUrl!.isEmpty)
                    ? Text(
                        otherUser.displayName.isNotEmpty 
                            ? otherUser.displayName[0].toUpperCase() 
                            : '?',  // ✅ MUST ADD THIS LINE
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
                // Bubble Style
                gradient: isMe 
                  ? const LinearGradient(colors: [Colors.indigo, Colors.purple]) // Gradient for Me
                  : null,
                color: isMe ? null : const Color(0xFF374151), // Dark gray for Others
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: Colors.white, // Text always white on dark/gradient background
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