import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/quiz_model.dart';
import 'package:intl/intl.dart';

class StudentQuizCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onTap;

  const StudentQuizCard({
    super.key,
    required this.quiz,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = quiz.status == 'available';
    final isUpcoming = quiz.status == 'upcoming';
    final isClosed = quiz.status == 'closed';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(quiz.status),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status badge
              Row(
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    color: _getStatusColor(quiz.status),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      quiz.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusBadge(quiz.status),
                ],
              ),
              const SizedBox(height: 12),

              // Quiz info
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.help_outline,
                    label: '${quiz.questions} Questions',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    icon: Icons.timer_outlined,
                    label: quiz.duration,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Schedule info
              if (quiz.openDate != null)
                Row(
                  children: [
                    Icon(
                      isUpcoming ? Icons.schedule : Icons.event_available,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isUpcoming
                          ? 'Opens: ${DateFormat('MMM dd, yyyy • h:mm a').format(quiz.openDate!)}'
                          : 'Opened: ${DateFormat('MMM dd, yyyy • h:mm a').format(quiz.openDate!)}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

              if (quiz.closeDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.event_busy,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Closes: ${DateFormat('MMM dd, yyyy • h:mm a').format(quiz.closeDate!)}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],

              // Action button
              if (isAvailable) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else if (isUpcoming) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Not yet available',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'available':
        bgColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        label = 'Available';
        break;
      case 'upcoming':
        bgColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        label = 'Upcoming';
        break;
      case 'closed':
        bgColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        label = 'Closed';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'upcoming':
        return Colors.orange;
      case 'closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
