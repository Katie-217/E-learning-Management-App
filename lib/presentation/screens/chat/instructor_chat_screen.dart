import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/user_model.dart';
import '../../../application/controllers/chat/chat_providers.dart';

// Đảm bảo import đúng file màn hình chat chi tiết của bạn
// import 'package:elearning_management_app/presentation/screens/chat/chat_detail_screen.dart'; 

class SelectStudentScreen extends ConsumerStatefulWidget {
  const SelectStudentScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SelectStudentScreen> createState() => _SelectStudentScreenState();
}

class _SelectStudentScreenState extends ConsumerState<SelectStudentScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _filterStudents(List<UserModel> students) {
    if (_searchQuery.isEmpty) return students;
    
    final query = _searchQuery.toLowerCase();
    return students.where((student) {
      return student.name.toLowerCase().contains(query) ||
             student.email.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(myStudentsProvider);

    // 🔴 SỬA: Dùng Column thay vì Scaffold để tránh lỗi lồng giao diện trong Dashboard
    return Column(
      children: [
        // Header thay thế cho AppBar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          color: Colors.white,
          child: const Text(
            'Chọn người chat',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            onChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
            style: const TextStyle(color: Color(0xFF1A1A1A)),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc email...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        
        // Student list
        Expanded(
          child: studentsAsync.when(
            data: (students) {
              final filteredStudents = _filterStudents(students);
              
              if (students.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.person_outline,
                  title: 'Không có sinh viên',
                  subtitle: 'Bạn chưa có sinh viên nào.',
                );
              }
              
              if (filteredStudents.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.search_off,
                  title: 'Không tìm thấy',
                  subtitle: 'Không có sinh viên nào khớp với "$_searchQuery"',
                );
              }
              
              return _buildStudentList(filteredStudents);
            },
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Đang tải danh sách...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            error: (error, stack) => _buildErrorState(error),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Lỗi khi tải danh sách',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(myStudentsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(List<UserModel> students) {
    return Column(
      children: [
        // Results count
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Text(
            'Tìm thấy ${students.length} sinh viên',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A90E2),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: students.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE5E5E5),
              indent: 72,
            ),
            itemBuilder: (context, index) {
              final student = students[index];
              return _StudentTile(student: student);
            },
          ),
        ),
      ],
    );
  }
}

class _StudentTile extends ConsumerWidget {
  final UserModel student;

  const _StudentTile({required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _startConversation(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF4A90E2),
                backgroundImage: student.photoUrl != null 
                    ? NetworkImage(student.photoUrl!)
                    : null,
                child: student.photoUrl == null
                    ? Text(
                        student.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startConversation(BuildContext context, WidgetRef ref) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
        ),
      ),
    );

    try {
      final conversationId = await ref
          .read(chatControllerProvider.notifier)
          .startConversation(student.uid);

      if (!context.mounted) return;
      
      // Close loading
      Navigator.pop(context);

      if (conversationId != null) {
        // 🔴 SỬA: Dùng Navigator.push thay vì pushReplacement 
        // để user có thể Back quay lại Dashboard
        Navigator.push( 
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              conversationId: conversationId,
              otherUser: student,
            ),
          ),
        );
      } else {
        _showError(context, 'Không thể tạo cuộc trò chuyện');
      }
    } catch (e) {
      if (!context.mounted) return;
      // Close loading
      Navigator.pop(context);
      _showError(context, e.toString());
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ========================================
// ⚠️ QUAN TRỌNG: Bạn cần chắc chắn class ChatDetailScreen 
// đã được định nghĩa ở một file khác và import vào.
// Dưới đây là placeholder nếu bạn chưa có file đó.
// Nếu đã có file thật, hãy XÓA class dưới đây đi.
// ========================================

class ChatDetailScreen extends StatelessWidget {
  final String conversationId;
  final UserModel? otherUser;

  const ChatDetailScreen({
    Key? key,
    required this.conversationId,
    this.otherUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(otherUser?.name ?? 'Chat'),
      ),
      body: Center(
        child: Text('Chat ID: $conversationId\nUser: ${otherUser?.name}'),
      ),
    );
  }
}