import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/presentation/screens/instructor/instructor_dashboard.dart';
import 'package:elearning_management_app/presentation/widgets/common/main_shell.dart';
import 'package:elearning_management_app/application/controllers/course/course_instructor_provider.dart';
import 'package:elearning_management_app/application/controllers/instructor/instructor_kpi_provider.dart';
import 'package:elearning_management_app/data/repositories/semester/semester_repository.dart';

class RoleBasedDashboard extends ConsumerStatefulWidget {
  const RoleBasedDashboard({super.key});

  @override
  ConsumerState<RoleBasedDashboard> createState() => _RoleBasedDashboardState();
}

class _RoleBasedDashboardState extends ConsumerState<RoleBasedDashboard> {
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      // Lấy role từ Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      final role = (data['role'] ?? '').toString().toLowerCase();
      
      setState(() {
        _userRole = role;
      });
    } catch (e) {
      print('DEBUG: ❌ Error getting role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Data đã được preload trong AuthWrapper, chỉ cần hiển thị dashboard
    final role = _userRole;
    if (role == 'teacher' || role == 'instructor') {
      return const InstructorDashboard();
    }

    return const MainShell();
  }
}
