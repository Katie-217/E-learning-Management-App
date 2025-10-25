import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sidebar_model.dart';
import '../../features/student/presentation/pages/student_dashboard_page.dart';
import '../../features/courses/presentation/pages/course_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String activeKey = 'dashboard';
  String _userName = 'User';
  String? _userPhotoUrl;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Không tự động set route, để user tự chọn
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _userName = data['name'] ?? user.displayName ?? 'User';
            _userPhotoUrl = data['photoUrl'] ?? user.photoURL;
            _userEmail = data['email'] ?? user.email ?? '';
          });
        } else {
          // Fallback to Firebase Auth data
          setState(() {
            _userName = user.displayName ?? 'User';
            _userPhotoUrl = user.photoURL;
            _userEmail = user.email ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Widget _buildUserAvatar() {
    if (_userPhotoUrl != null && _userPhotoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _userPhotoUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo, Colors.purple]),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void onSelect(String key) {
    print('DEBUG: onSelect called with key = $key'); // Debug log
    setState(() {
      activeKey = key;
    });
  }

  Widget _buildCurrentPage() {
    print('DEBUG: _buildCurrentPage called with activeKey = $activeKey'); // Debug log
    switch (activeKey) {
      case 'dashboard':
        print('DEBUG: Building StudentDashboardPage'); // Debug log
        return const StudentDashboardPage(showSidebar: false);
      case 'courses':
        print('DEBUG: Building CoursePage'); // Debug log
        return const CoursePage(showSidebar: false);
      default:
        print('DEBUG: Building default StudentDashboardPage'); // Debug log
        return const StudentDashboardPage(showSidebar: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        title: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.indigo[600],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu_book),
          ),
          const SizedBox(width: 12),
          const Text('E-Learning', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        actions: [
          SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search courses, materials...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF111827),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(children: [
              _buildUserAvatar(),
              const SizedBox(width: 8),
              Text(_userName),
            ]),
          )
        ],
      ),
      body: Row(
        children: [
          const SizedBox(width: 0),
          if (MediaQuery.of(context).size.width > 800)
            SidebarWidget(onSelect: onSelect, activeKey: activeKey),
          Expanded(
            child: _buildCurrentPage(),
          ),
        ],
      ),
    );
  }
}


