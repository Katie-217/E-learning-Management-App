import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InstructorGradesPage extends StatelessWidget {
  const InstructorGradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grades'),
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
              'Grade Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildGradeCard('CS450 - Advanced Web Development', 'Nguyen Van A', 8.5),
                  _buildGradeCard('CS450 - Advanced Web Development', 'Tran Thi B', 9.0),
                  _buildGradeCard('CS380 - Database Systems', 'Le Van C', 7.5),
                  _buildGradeCard('CS380 - Database Systems', 'Pham Thi D', 8.0),
                  _buildGradeCard('CS420 - Software Engineering', 'Hoang Van E', 9.5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeCard(String course, String student, double grade) {
    Color gradeColor = grade >= 8.0
        ? Colors.green
        : grade >= 6.5
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: gradeColor.withOpacity(0.2),
          child: Text(
            grade.toStringAsFixed(1),
            style: TextStyle(color: gradeColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(student, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(course),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {},
        ),
      ),
    );
  }
}

