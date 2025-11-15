import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:elearning_management_app/presentation/screens/instructor/instructor_dashboard.dart';
import 'package:elearning_management_app/presentation/widgets/common/main_shell.dart';

class RoleBasedDashboard extends StatelessWidget {
  const RoleBasedDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const MainShell();
    }
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const MainShell();
          }
          final data = snapshot.data?.data();
          final role = (data?['role'] ?? '').toString().toLowerCase();
          if (role == 'teacher' || role == 'instructor') {
            return const InstructorDashboard();
          }
          // Sử dụng MainShell cho student để có navigation
          return const MainShell();
        },
      ),
    );
  }
}
