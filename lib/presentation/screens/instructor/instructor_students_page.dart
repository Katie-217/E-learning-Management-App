import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InstructorStudentsPage extends StatelessWidget {
  const InstructorStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Students',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildStudentCard(
                      'Nguyen Van A', 'Student ID: SV001', 'CS450'),
                  _buildStudentCard('Tran Thi B', 'Student ID: SV002', 'CS450'),
                  _buildStudentCard('Le Van C', 'Student ID: SV003', 'CS380'),
                  _buildStudentCard('Pham Thi D', 'Student ID: SV004', 'CS380'),
                  _buildStudentCard(
                      'Hoang Van E', 'Student ID: SV005', 'CS420'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(String name, String studentId, String course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            name[0].toUpperCase(),
            style:
                TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(studentId),
            Text('Course: $course'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ),
    );
  }
}
