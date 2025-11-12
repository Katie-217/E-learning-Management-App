// Quiz card widget
import 'package:flutter/material.dart';
import '../../../../../domain/models/quiz_model.dart';

class QuizCard extends StatelessWidget {
  final Quiz quiz;
  const QuizCard({super.key, required this.quiz});

  Color _bg() {
    switch (quiz.status) {
      case 'available': return Colors.green.withOpacity(0.12);
      case 'upcoming': return Colors.orange.withOpacity(0.12);
      default: return Colors.blue.withOpacity(0.12);
    }
  }
  Color _textColor() {
    switch (quiz.status) {
      case 'available': return Colors.greenAccent;
      case 'upcoming': return Colors.orangeAccent;
      default: return Colors.lightBlueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[700]!),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(quiz.dueDate, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: _bg(),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _bg().withOpacity(0.8)),
                ),
                child: Text(quiz.status, style: TextStyle(color: _textColor(), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Row(children: [const Icon(Icons.access_time, size: 14), const SizedBox(width: 6), Text(quiz.duration, style: TextStyle(color: Colors.grey[400], fontSize: 12))]),
              const SizedBox(width: 12),
              Row(children: [const Icon(Icons.article_outlined, size: 14), const SizedBox(width: 6), Text('${quiz.questions} questions', style: TextStyle(color: Colors.grey[400], fontSize: 12))]),
            ],
          )
        ],
      ),
    );
  }
}
