import 'package:flutter/material.dart';
import '../../assignment/assignment_card.dart';
import '../../quiz/quiz_card.dart';
import '../../material/material_card.dart';

class ClassworkTab extends StatelessWidget {
  const ClassworkTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Assignments & Quizzes',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white)),
        SizedBox(height: 8),
        // AssignmentCard(assignment: null),
        // QuizCard(quiz: null),
        SizedBox(height: 24),
        Text('Course Materials',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white)),
        SizedBox(height: 8),
        // MaterialCard(),
      ],
    );
  }
}
