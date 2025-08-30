// ========================================
// FILE: google_signin_demo.dart
// MÔ TẢ: Demo screen để test chức năng Google Sign-In
// ========================================

import 'package:flutter/material.dart';
import 'google_auth_service.dart';
import '../../../core/enums/user_role.dart';

// ========================================
// CLASS: GoogleSignInDemo
// MÔ TẢ: Màn hình demo để test Google Sign-In
// ========================================
class GoogleSignInDemo extends StatefulWidget {
  const GoogleSignInDemo({super.key});

  @override
  State<GoogleSignInDemo> createState() => _GoogleSignInDemoState();
}

// ========================================
// CLASS: _GoogleSignInDemoState
// MÔ TẢ: State quản lý demo Google Sign-In
// ========================================
class _GoogleSignInDemoState extends State<GoogleSignInDemo> {
  bool _isLoading = false;
  GoogleUserInfo? _currentUser;
  String? _errorMessage;

  // ========================================
  // HÀM: _signInWithGoogle()
  // MÔ TẢ: Test đăng nhập Google
  // ========================================
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await GoogleAuthService.instance.signInWithGoogle();
      
      if (result.isSuccess && result.user != null) {
        setState(() {
          _currentUser = result.user;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thành công: ${result.user!.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = result.errorMessage;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Đăng nhập thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ========================================
  // HÀM: _signOut()
  // MÔ TẢ: Test đăng xuất Google
  // ========================================
  Future<void> _signOut() async {
    await GoogleAuthService.instance.signOut();
    setState(() {
      _currentUser = null;
      _errorMessage = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đăng xuất'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // ========================================
  // HÀM: _checkSignInStatus()
  // MÔ TẢ: Kiểm tra trạng thái đăng nhập
  // ========================================
  Future<void> _checkSignInStatus() async {
    final isSignedIn = await GoogleAuthService.instance.isSignedIn();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSignedIn ? 'Đã đăng nhập' : 'Chưa đăng nhập'),
        backgroundColor: isSignedIn ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========================================
            // PHẦN: User Info Card
            // MÔ TẢ: Hiển thị thông tin người dùng hiện tại
            // ========================================
            if (_currentUser != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin người dùng:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('ID: ${_currentUser!.id}'),
                      Text('Email: ${_currentUser!.email}'),
                      Text('Tên: ${_currentUser!.displayName}'),
                      if (_currentUser!.photoUrl != null)
                        Text('Ảnh: ${_currentUser!.photoUrl}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ========================================
            // PHẦN: Error Message
            // MÔ TẢ: Hiển thị thông báo lỗi nếu có
            // ========================================
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  'Lỗi: $_errorMessage',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ========================================
            // PHẦN: Action Buttons
            // MÔ TẢ: Các nút thao tác
            // ========================================
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _signInWithGoogle,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_isLoading ? 'Đang đăng nhập...' : 'Đăng nhập Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _currentUser == null ? null : _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 12),
            
            OutlinedButton.icon(
              onPressed: _checkSignInStatus,
              icon: const Icon(Icons.info),
              label: const Text('Kiểm tra trạng thái'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 24),

            // ========================================
            // PHẦN: Info Card
            // MÔ TẢ: Thông tin về demo
            // ========================================
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hướng dẫn sử dụng:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Nhấn "Đăng nhập Google" để test chức năng'),
                    Text('2. Kiểm tra thông tin người dùng hiển thị'),
                    Text('3. Nhấn "Đăng xuất" để thoát'),
                    Text('4. Nhấn "Kiểm tra trạng thái" để xem trạng thái hiện tại'),
                    SizedBox(height: 8),
                    Text(
                      'Lưu ý: Đây là demo với dữ liệu giả. Để sử dụng thực tế, cần cấu hình Firebase và Google Sign-In.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
