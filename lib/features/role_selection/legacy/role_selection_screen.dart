// ========================================
// FILE: role_selection_screen.dart
// MÔ TẢ: Màn hình chọn vai trò người dùng (Student/Teacher)
// ========================================

import 'package:flutter/material.dart';
import '../../auth/presentation/auth_overlay_screen.dart';
import '../../../core/enums/user_role.dart';

// ========================================
// CLASS: RoleSelectionScreen
// MÔ TẢ: Widget chính cho màn hình chọn vai trò
// ========================================
class RoleSelectionScreen extends StatefulWidget {
  @override
  _RoleSelectionScreenState createState() => _RoleSelectionScreenState();
}

// ========================================
// CLASS: _RoleSelectionScreenState
// MÔ TẢ: State quản lý trạng thái của màn hình chọn vai trò
// ========================================
class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  // ========================================
  // BIẾN: Trạng thái và Animation Controllers
  // MÔ TẢ: Các biến quản lý trạng thái và hiệu ứng
  // ========================================
  UserRole? selectedRole;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // ========================================
  // HÀM: initState()
  // MÔ TẢ: Khởi tạo các animation controllers và animations
  // ========================================
  @override
  void initState() {
    super.initState();
    // ========================================
    // PHẦN: Khởi tạo Fade Animation Controller
    // MÔ TẢ: Controller cho hiệu ứng fade in
    // ========================================
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    // ========================================
    // PHẦN: Khởi tạo Scale Animation Controller
    // MÔ TẢ: Controller cho hiệu ứng scale
    // ========================================
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    // ========================================
    // PHẦN: Cấu hình Fade Animation
    // MÔ TẢ: Thiết lập hiệu ứng fade từ 0 đến 1
    // ========================================
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // ========================================
    // PHẦN: Cấu hình Scale Animation
    // MÔ TẢ: Thiết lập hiệu ứng scale từ 0.8 đến 1.0
    // ========================================
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // ========================================
    // PHẦN: Bắt đầu animations
    // MÔ TẢ: Khởi chạy các hiệu ứng khi màn hình load
    // ========================================
    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 300), () {
      _scaleController.forward();
    });
  }

  // ========================================
  // HÀM: dispose()
  // MÔ TẢ: Dọn dẹp resources khi widget bị hủy
  // ========================================
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // ========================================
  // HÀM: buildRoleCard()
  // MÔ TẢ: Tạo card hiển thị thông tin vai trò
  // ========================================
  Widget buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required List<String> features,
  }) {
    bool isSelected = selectedRole == role;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedRole = role;
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              padding: EdgeInsets.all(25),
              // ========================================
              // PHẦN: Decoration cho card
              // MÔ TẢ: Thiết lập gradient, border và shadow
              // ========================================
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected ? gradientColors : [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isSelected 
                        ? gradientColors[1].withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: isSelected ? 15 : 10,
                    offset: Offset(0, isSelected ? 8 : 5),
                  ),
                ],
                border: Border.all(
                  color: isSelected ? gradientColors[1] : Colors.grey[200]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  // ========================================
                  // PHẦN: Icon và Title
                  // MÔ TẢ: Hiển thị icon, tiêu đề và trạng thái chọn
                  // ========================================
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.2) : gradientColors[0].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          icon,
                          size: 40,
                          color: isSelected ? Colors.white : gradientColors[1],
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.check,
                            color: gradientColors[1],
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // ========================================
                  // PHẦN: Danh sách tính năng
                  // MÔ TẢ: Hiển thị các tính năng của vai trò
                  // ========================================
                  Column(
                    children: features.map((feature) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: isSelected ? Colors.white.withOpacity(0.8) : gradientColors[1].withOpacity(0.7),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                feature,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ========================================
  // HÀM: navigateToLogin()
  // MÔ TẢ: Điều hướng đến màn hình đăng nhập
  // ========================================
  void navigateToLogin() {
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng chọn vai trò của bạn!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AuthOverlayScreen(userRole: selectedRole!),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }

  // ========================================
  // HÀM: build()
  // MÔ TẢ: Xây dựng giao diện chính của màn hình
  // ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // ========================================
        // PHẦN: Background Image
        // MÔ TẢ: Hình nền của màn hình
        // ========================================
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/icons/background-roler.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // ========================================
          // PHẦN: Gradient Overlay
          // MÔ TẢ: Lớp gradient phủ lên background
          // ========================================
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.5),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  SizedBox(height: 40),
                  
                  // ========================================
                  // PHẦN: Header
                  // MÔ TẢ: Tiêu đề chào mừng
                  // ========================================
                  Text(
                    'Chào mừng!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Bạn là ai?',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 40),
                  
                  // ========================================
                  // PHẦN: Role Cards Container
                  // MÔ TẢ: Container chứa các card vai trò
                  // ========================================
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // ========================================
                          // PHẦN: Student Card
                          // MÔ TẢ: Card cho vai trò học sinh
                          // ========================================
                          buildRoleCard(
                            role: UserRole.student,
                            title: 'Học sinh',
                            subtitle: 'Tham gia các khóa học và bài kiểm tra',
                            icon: Icons.school,
                            gradientColors: [
                              Color(0xFF667eea),
                              Color(0xFF764ba2),
                            ],
                            features: [
                              'Truy cập khóa học',
                              'Làm bài kiểm tra trực tuyến',
                              'Xem điểm và tiến độ học tập',
                              'Tương tác với giáo viên',
                              'Tải tài liệu học tập',
                            ],
                          ),
                          
                          // ========================================
                          // PHẦN: Teacher Card
                          // MÔ TẢ: Card cho vai trò giáo viên
                          // ========================================
                          buildRoleCard(
                            role: UserRole.teacher,
                            title: 'Giáo viên',
                            subtitle: 'Quản lý khóa học và học sinh',
                            icon: Icons.person_pin,
                            gradientColors: [
                              Color(0xFFff7675),
                              Color(0xFFe84393),
                            ],
                            features: [
                              'Tạo và quản lý khóa học',
                              'Tạo bài kiểm tra và đánh giá',
                              'Theo dõi tiến độ học sinh',
                              'Tương tác với học sinh',
                              'Thống kê và báo cáo',
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // ========================================
                  // PHẦN: Continue Button
                  // MÔ TẢ: Nút tiếp tục để chuyển sang màn hình đăng nhập
                  // ========================================
                  Padding(
                    padding: EdgeInsets.all(30),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: navigateToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedRole != null ? Colors.white : Colors.white.withOpacity(0.3),
                          foregroundColor: selectedRole != null ? Color(0xFF6c5ce7) : Colors.white.withOpacity(0.7),
                          padding: EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: selectedRole != null ? 10 : 5,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Tiếp tục',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}