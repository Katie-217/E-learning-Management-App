import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';

class InstructorPeopleTab extends StatelessWidget {
  final CourseModel course;
  const InstructorPeopleTab({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teacher Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Teacher',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Icon(Icons.school, color: Colors.indigo[400], size: 24),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Colors.indigo, Colors.purple]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.instructor,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Course Instructor',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon:
                          const Icon(Icons.email_outlined, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Students Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                // TODO: Replace with async enrollment count
                // Use EnrollmentRepository.countStudentsInCourse(course.id)
                'Students (Loading...)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.person_add_outlined,
                        color: Colors.indigo),
                    tooltip: 'Invite Students',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon:
                        const Icon(Icons.download_outlined, color: Colors.grey),
                    tooltip: 'Export List',
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Student List
          Expanded(
            child: ListView.builder(
              itemCount: _mockStudents.length,
              itemBuilder: (context, index) {
                final student = _mockStudents[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: student['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            student['initials'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              student['email'] as String,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: student['isActive'] == true
                              ? Colors.green.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          student['isActive'] == true ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: student['isActive'] == true
                                ? Colors.green
                                : Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: Colors.grey, size: 18),
                        color: const Color(0xFF1F2937),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'email', child: Text('Send Email')),
                          const PopupMenuItem(
                              value: 'grades', child: Text('View Grades')),
                          const PopupMenuItem(
                              value: 'remove', child: Text('Remove')),
                        ],
                        onSelected: (value) {
                          // Handle menu actions
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Mock student data
final List<Map<String, dynamic>> _mockStudents = [
  {
    'name': 'Nguyen Van A',
    'email': 'student.a@example.com',
    'initials': 'NA',
    'color': Colors.blue,
    'isActive': true,
  },
  {
    'name': 'Tran Thi B',
    'email': 'student.b@example.com',
    'initials': 'TB',
    'color': Colors.green,
    'isActive': true,
  },
  {
    'name': 'Le Van C',
    'email': 'student.c@example.com',
    'initials': 'LC',
    'color': Colors.orange,
    'isActive': false,
  },
  {
    'name': 'Pham Thi D',
    'email': 'student.d@example.com',
    'initials': 'PD',
    'color': Colors.purple,
    'isActive': true,
  },
  {
    'name': 'Hoang Van E',
    'email': 'student.e@example.com',
    'initials': 'HE',
    'color': Colors.red,
    'isActive': true,
  },
];
