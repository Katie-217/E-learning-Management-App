import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/data/repositories/course/enrollment_repository.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';

class PeopleTab extends StatefulWidget {
  final CourseModel course;
  
  const PeopleTab({super.key, required this.course});

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  List<Map<String, dynamic>> _classmates = [];
  bool _isLoading = true;
  String? _instructorName;
  String? _instructorEmail;

  @override
  void initState() {
    super.initState();
    _loadPeopleData();
  }

  Future<void> _loadPeopleData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load instructor info
      _instructorName = widget.course.instructor;
      
      // Try to get instructor email from users collection
      try {
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('name', isEqualTo: _instructorName)
            .limit(1)
            .get();
        
        if (usersSnapshot.docs.isNotEmpty) {
          _instructorEmail = usersSnapshot.docs.first.data()['email'];
        }
      } catch (e) {
        print('Error loading instructor email: $e');
      }

      // Load classmates
      final enrollmentRepo = EnrollmentRepository();
      final enrollments = await enrollmentRepo.getStudentsInCourse(widget.course.id);
      
      // Get current user to exclude from classmates list
      final currentUser = FirebaseAuth.instance.currentUser;
      
      // Convert enrollments to classmates list
      final classmates = <Map<String, dynamic>>[];
      for (var enrollment in enrollments) {
        // Exclude current user from classmates
        if (currentUser != null && enrollment.userId == currentUser.uid) {
          continue;
        }
        
        classmates.add({
          'userId': enrollment.userId,
          'name': enrollment.studentName,
          'email': enrollment.studentEmail,
        });
      }

      setState(() {
        _classmates = classmates;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading people data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.pink,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
    ];
    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Teachers Section
              const Text(
                'Teachers',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (_instructorName != null && _instructorName!.isNotEmpty)
                _buildTeacherItem(_instructorName!, _instructorEmail),
              const SizedBox(height: 32),
              
              // Divider
              Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 32),
              
              // Classmates Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Classmates',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${_classmates.length} students',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_classmates.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No classmates found',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                ..._classmates.map((classmate) => _buildClassmateItem(
                      classmate['name'] as String,
                      classmate['email'] as String?,
                    )),
            ],
          );
  }

  Widget _buildTeacherItem(String name, String? email) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name and email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (email != null && email.isNotEmpty)
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassmateItem(String name, String? email) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getAvatarColor(name),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name and email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (email != null && email.isNotEmpty)
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
