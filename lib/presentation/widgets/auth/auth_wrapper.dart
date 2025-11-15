// ========================================
// FILE: auth_wrapper.dart
// MÔ TẢ: Auth Wrapper sử dụng AuthRepository - Clean Architecture
// ========================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_repository.dart';
import 'package:elearning_management_app/data/repositories/auth/user_session_service.dart';
import 'package:elearning_management_app/domain/models/user_model.dart';
import 'package:elearning_management_app/core/config/users-role.dart';
import 'package:elearning_management_app/presentation/screens/auth/auth_overlay_screen.dart';
import 'package:elearning_management_app/presentation/widgets/common/role_based_dashboard.dart';
import 'dart:async';

// ========================================
// CLASS: AuthWrapper
// MÔ TẢ: Wrapper kiểm tra auth state - Clean Architecture
// ========================================
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

// ========================================
// CLASS: _AuthWrapperState
// MÔ TẢ: Auth state management sử dụng AuthRepository
// ========================================
class _AuthWrapperState extends State<AuthWrapper> {
  final AuthRepository _authRepository = AuthRepository.defaultClient();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  UserModel? _currentUser;
  StreamSubscription<User?>? _authStateSubscription;
  bool _hasCheckedInitialAuth = false;
  bool _isWaitingForAuthRestore = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // HÀM: _initializeAuth - Khởi tạo và lắng nghe auth state changes
  // MÔ TẢ: Sử dụng stream để lắng nghe thay đổi auth state, đảm bảo Firebase Auth đã restore session
  // ========================================
  void _initializeAuth() {
    print('DEBUG: 🔍 Initializing authentication...');

    // Lắng nghe thay đổi auth state (quan trọng cho web - Firebase có thể restore session sau)
    // Sử dụng cả authStateChanges và idTokenChanges để đảm bảo bắt được khi Firebase restore
    _authStateSubscription = _firebaseAuth.idTokenChanges().listen(
      (firebaseUser) async {
        print('DEBUG: 🔔 ID Token changed: ${firebaseUser?.email ?? "null"}');
        
        // Nếu đang đợi Firebase restore session và có user, xử lý ngay
        if (_isWaitingForAuthRestore && firebaseUser != null) {
          print('DEBUG: ✅ Firebase user restored via idToken stream!');
          _isWaitingForAuthRestore = false;
          await _handleAuthStateChange(firebaseUser);
        } 
        // Nếu đã check initial auth và có user, xử lý
        else if (_hasCheckedInitialAuth && firebaseUser != null) {
          await _handleAuthStateChange(firebaseUser);
        }
        // Nếu đã check initial auth và không có user, và không đang đợi restore
        else if (_hasCheckedInitialAuth && firebaseUser == null && !_isWaitingForAuthRestore) {
          await _handleAuthStateChange(firebaseUser);
        }
      },
      onError: (error) {
        print('DEBUG: ❌ ID Token error: $error');
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _isLoading = false;
          });
        }
      },
    );

    // Kiểm tra ngay lập tức (có thể Firebase đã restore session)
    _checkAuthStatus();
  }

  // HÀM: _handleAuthStateChange - Xử lý thay đổi auth state
  // ========================================
  Future<void> _handleAuthStateChange(User? firebaseUser) async {
    if (firebaseUser != null) {
      try {
        // Có Firebase user - lấy UserModel từ Firestore
        final user = await _authRepository.checkUserSession();
        if (user != null && mounted) {
          print('DEBUG: ✅ Firebase user authenticated: ${user.email}');
          _isWaitingForAuthRestore = false;
          await UserSessionService.saveUserSession(user);
          setState(() {
            _currentUser = user;
            _isAuthenticated = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('DEBUG: ❌ Error getting user data: $e');
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _isLoading = false;
          });
        }
      }
    } else {
      // Không có Firebase user - chỉ clear nếu đã check initial auth và không đang đợi restore
      if (mounted && _hasCheckedInitialAuth && !_isWaitingForAuthRestore) {
        final hasSession = await UserSessionService.hasValidSession();
        if (hasSession) {
          print('DEBUG: ⚠️ No Firebase user but SharedPreferences has session - clearing');
          await UserSessionService.clearUserSession();
        }
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    }
  }

  // HÀM: _checkAuthStatus - Kiểm tra auth status ban đầu
  // MÔ TẢ: Kiểm tra auth status khi app khởi động
  // ========================================
  Future<void> _checkAuthStatus() async {
    try {
      print('DEBUG: 🔍 Checking initial authentication status...');

      // Đợi một chút để Firebase Auth có thời gian khởi tạo hoàn toàn
      await Future.delayed(const Duration(milliseconds: 300));

      // 1. Kiểm tra Firebase Auth trước (Firebase tự động persist session trên web)
      final firebaseUser = _firebaseAuth.currentUser;
      
      if (firebaseUser != null) {
        print('DEBUG: ✅ Firebase user found: ${firebaseUser.email}');
        _hasCheckedInitialAuth = true;
        final user = await _authRepository.checkUserSession();
        if (user != null && mounted) {
          await UserSessionService.saveUserSession(user);
          setState(() {
            _currentUser = user;
            _isAuthenticated = true;
            _isLoading = false;
          });
          return;
        }
      }

      // 2. Nếu không có Firebase user, kiểm tra SharedPreferences
      final hasSession = await UserSessionService.hasValidSession();
      print('DEBUG: 📋 SharedPreferences session check: $hasSession');

      if (hasSession) {
        // Có session trong SharedPreferences - đợi Firebase Auth restore (stream sẽ xử lý)
        print('DEBUG: ⏳ Session found in SharedPreferences, waiting for Firebase Auth to restore...');
        _isWaitingForAuthRestore = true;
        _hasCheckedInitialAuth = true;
        
        // Đợi lâu hơn (5 giây) để Firebase restore session trên web
        // Stream sẽ xử lý nếu Firebase restore sớm hơn
        await Future.delayed(const Duration(seconds: 5));
        
        // Kiểm tra lại sau khi đợi
        if (_isWaitingForAuthRestore && mounted) {
          final firebaseUserAfterWait = _firebaseAuth.currentUser;
          if (firebaseUserAfterWait != null) {
            print('DEBUG: ✅ Firebase user restored after wait: ${firebaseUserAfterWait.email}');
            _isWaitingForAuthRestore = false;
            final user = await _authRepository.checkUserSession();
            if (user != null && mounted) {
              await UserSessionService.saveUserSession(user);
              setState(() {
                _currentUser = user;
                _isAuthenticated = true;
                _isLoading = false;
              });
              return;
            }
          } else {
            // Sau khi đợi mà vẫn không có Firebase user
            // Thử kiểm tra lại với idTokenChanges
            print('DEBUG: ⚠️ Firebase Auth did not restore after wait, checking idToken...');
            try {
              final currentUser = _firebaseAuth.currentUser;
              if (currentUser != null) {
                // Có user nhưng có thể token chưa sẵn sàng
                await currentUser.reload();
                final reloadedUser = _firebaseAuth.currentUser;
                if (reloadedUser != null) {
                  print('DEBUG: ✅ Firebase user found after reload: ${reloadedUser.email}');
                  _isWaitingForAuthRestore = false;
                  final user = await _authRepository.checkUserSession();
                  if (user != null && mounted) {
                    await UserSessionService.saveUserSession(user);
                    setState(() {
                      _currentUser = user;
                      _isAuthenticated = true;
                      _isLoading = false;
                    });
                    return;
                  }
                }
              }
            } catch (e) {
              print('DEBUG: ❌ Error reloading user: $e');
            }
            
            // Nếu vẫn không có, clear session và hiển thị login
            print('DEBUG: ⚠️ Clearing session - Firebase Auth did not restore');
            _isWaitingForAuthRestore = false;
            await UserSessionService.clearUserSession();
            if (mounted) {
              setState(() {
                _isAuthenticated = false;
                _isLoading = false;
              });
            }
            return;
          }
        }
      } else {
        // 3. Không có session trong SharedPreferences - hiển thị login ngay
        _hasCheckedInitialAuth = true;
        if (mounted) {
          print('DEBUG: ❌ No session found, showing login');
          setState(() {
            _isAuthenticated = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('DEBUG: ❌ Error checking auth status: $e');
      _hasCheckedInitialAuth = true;
      _isWaitingForAuthRestore = false;
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        title: 'E-Learning Management',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_isAuthenticated && _currentUser != null) {
      return const MaterialApp(
        title: 'E-Learning Management',
        debugShowCheckedModeBanner: false,
        home: RoleBasedDashboard(),
      );
    }

    return const MaterialApp(
      title: 'E-Learning Management',
      debugShowCheckedModeBanner: false,
      home: AuthOverlayScreen(initialRole: UserRole.student),
    );
  }
}
