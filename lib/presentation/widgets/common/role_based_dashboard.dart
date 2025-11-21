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
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final hasError = snapshot.hasError;
          final isEmpty = snapshot.data?.docs.isEmpty ?? true;
          if (hasError || isEmpty) {
            print('DEBUG: ⚠️ RoleBasedDashboard - No user document found, defaulting to MainShell');
            return const MainShell();
          }
          final doc = snapshot.data!.docs.first;
          final data = doc.data();
          final role = (data['role'] ?? '').toString().toLowerCase();
          print('DEBUG: 🔍 RoleBasedDashboard - Role from Firestore: $role');
          if (role == 'teacher' || role == 'instructor') {
            print('DEBUG: ✅ RoleBasedDashboard - Navigating to InstructorDashboard');
            return InstructorDashboard();
          }
          print('DEBUG: ✅ RoleBasedDashboard - Navigating to MainShell (student)');
          // Sử dụng MainShell cho student để có navigation
          return MainShell();
        },
      ),
    );
  }
}
