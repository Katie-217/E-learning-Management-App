import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/presentation/screens/instructor/instructor_dashboard.dart';
import 'package:elearning_management_app/presentation/widgets/common/main_shell.dart';
import 'package:elearning_management_app/presentation/screens/auth/auth_overlay_screen.dart';
import 'package:elearning_management_app/core/config/users-role.dart';

class RoleBasedDashboard extends StatelessWidget {
  const RoleBasedDashboard({super.key});

  Future<String?> _fetchRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) return null;
      return (doc.data()?['role'] as String?)?.toLowerCase();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _fetchRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return const AuthOverlayScreen(initialRole: UserRole.student);
        }
        final role = (snapshot.data ?? '').toLowerCase();
        if (role == 'instructor' || role == 'teacher') {
          return const InstructorDashboard();
        }
        return const MainShell();
      },
    );
  }
}


