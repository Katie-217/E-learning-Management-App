import 'package:flutter/material.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/auth/user_session_service.dart';
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
  final AuthRepository _authRepository = AuthRepository.defaultClient();

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _authRepository.signOut();
        await UserSessionService.clearUserSession();
        
        if (mounted) {
          // Navigate to login screen
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
              content: Text('Logout error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
                'Logout',
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

