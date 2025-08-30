import 'package:flutter/material.dart';
import '../../../core/enums/user_role.dart';
// import '../../auth/legacy/login_screen.dart'; // Old path (legacy), replaced below
// import '../../auth/legacy/login_controller.dart'; // Not used and file not found
import '../../auth/legacy/login_screen.dart';

class RoleSelectionController {
  // Xử lý khi user chọn role
  void selectRole(String role, BuildContext context) {
    if (role == 'teacher') {
      _navigateToLogin(context, UserRole.teacher);
    } else if (role == 'student') {
      _navigateToLogin(context, UserRole.student);
    }
  }

  // Navigate đến register screen
  void navigateToRegister(BuildContext context, String role) {
    // NOTE: RegisterScreen not found in project. Commented to avoid unresolved reference.
    // If/when RegisterScreen is implemented, restore and import it correctly.
    // UserRole userRole = role == 'teacher' ? UserRole.teacher : UserRole.student;
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => RegisterScreen(userRole: userRole),
    //   ),
    // );
  }

  // Navigate đến trang login với role đã chọn
  void _navigateToLogin(BuildContext context, UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(userRole: role),
      ),
    );
  }
}

