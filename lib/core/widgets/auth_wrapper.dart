import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_session_service.dart';
import '../config/users-role.dart';
import '../../features/auth/presentation/pages/auth_overlay_screen.dart';
import 'role_based_dashboard.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Check and restore user session
      final sessionRestored = await UserSessionService.checkAndRestoreSession();
      
      if (sessionRestored) {
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
        return;
      }
      
      // Check current Firebase Auth user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await UserSessionService.saveUserSession(firebaseUser);
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Dashboard',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: _buildCurrentScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _buildCurrentScreen() {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang kiểm tra đăng nhập...'),
            ],
          ),
        ),
      );
    }

    if (_isAuthenticated) {
      return const RoleBasedDashboard();
    } else {
      return const AuthOverlayScreen(initialRole: UserRole.student);
    }
  }
}
