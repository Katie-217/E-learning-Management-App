import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/auth/user_session_service.dart';
import '../../screens/profile/profile_page.dart';
import '../../screens/auth/auth_overlay_screen.dart';
import '../../../core/config/users-role.dart';

class UserMenuDropdown extends StatefulWidget {
  final String userName;
  final String? userPhotoUrl;
  final String userEmail;
  final VoidCallback? onReturnFromProfile;

  const UserMenuDropdown({
    super.key,
    required this.userName,
    this.userPhotoUrl,
    required this.userEmail,
    this.onReturnFromProfile,
  });

  @override
  State<UserMenuDropdown> createState() => _UserMenuDropdownState();
}

class _UserMenuDropdownState extends State<UserMenuDropdown> {
  bool _isDarkMode = true; // Default dark mode
  final AuthRepository _authRepository = AuthRepository.defaultClient();

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    });
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final newTheme = !_isDarkMode;
    await prefs.setBool('is_dark_mode', newTheme);
    setState(() {
      _isDarkMode = newTheme;
    });
    
    // Show snackbar to inform user (actual theme change would need MaterialApp rebuild)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newTheme 
              ? 'Đã chuyển sang chế độ tối' 
              : 'Đã chuyển sang chế độ sáng',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _authRepository.signOut();
        await UserSessionService.clearUserSession();
        
        if (mounted) {
          // Điều hướng về màn hình đăng nhập
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) =>
                  const AuthOverlayScreen(initialRole: UserRole.student),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi đăng xuất: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToProfile() {
    // Sử dụng push để mở profile page, không thay thế MainShell
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
        // Đảm bảo profile page không thay thế MainShell
        fullscreenDialog: false,
      ),
    ).then((result) {
      // Chỉ gọi callback khi thực sự quay lại từ profile (result != null hoặc khi pop)
      // Không gọi callback khi reload/restart vì không có profile page trong stack
      if (mounted && widget.onReturnFromProfile != null) {
        // Delay nhỏ để đảm bảo navigation đã hoàn tất
        Future.microtask(() {
          if (mounted) {
            widget.onReturnFromProfile!();
          }
        });
      }
    });
  }

  void _showMenu(BuildContext context) {
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    if (button == null) return;
    
    final OverlayState? overlay = Overlay.of(context);
    if (overlay == null) return;
    
    final RenderBox? overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;
    
    final Offset position = button.localToGlobal(Offset.zero, ancestor: overlayBox);

    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + button.size.height + 8,
        position.dx + button.size.width,
        position.dy + button.size.height + 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFF1F2937),
      elevation: 8,
      items: <PopupMenuEntry<void>>[
        // User Info Header
        PopupMenuItem(
          enabled: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.userEmail,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        // Theme Toggle
        PopupMenuItem(
          onTap: () {
            // PopupMenuItem tự động đóng menu trước khi onTap được gọi
            // Không cần delay, có thể gọi trực tiếp
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _toggleTheme();
              }
            });
          },
          child: Row(
            children: [
              Icon(
                _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                _isDarkMode ? 'Chế độ sáng' : 'Chế độ tối',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        // Edit Profile
        PopupMenuItem(
          onTap: () {
            // PopupMenuItem tự động đóng menu trước khi onTap được gọi
            // Không cần delay, có thể navigate trực tiếp
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _navigateToProfile();
              }
            });
          },
          child: const Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Colors.white70,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                'Thông tin cá nhân',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Logout
        PopupMenuItem(
          onTap: () {
            // PopupMenuItem tự động đóng menu trước khi onTap được gọi
            // Không cần delay, có thể gọi trực tiếp
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _handleLogout();
              }
            });
          },
          child: const Row(
            children: [
              Icon(
                Icons.logout,
                color: Colors.red,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showName = screenWidth > 700;

    return InkWell(
      onTap: () => _showMenu(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(),
            if (showName) ...[
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  widget.userName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          widget.userPhotoUrl!,
          width: 32,
          height: 32,
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
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo, Colors.purple]),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

