// ========================================
// FILE: quiz_detail_card.dart
// MÔ TẢ: Card hiển thị Quiz trong Classwork tab (Instructor)
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:elearning_management_app/domain/models/quiz_model.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';

class QuizDetailCard extends ConsumerStatefulWidget {
  final Quiz quiz;
  final String courseId;
  final VoidCallback? onReviewWork; // Callback to switch to Grade tab

  const QuizDetailCard({
    super.key,
    required this.quiz,
    required this.courseId,
    this.onReviewWork,
  });

  @override
  ConsumerState<QuizDetailCard> createState() => _QuizDetailCardState();
}

class _QuizDetailCardState extends ConsumerState<QuizDetailCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • h:mm a').format(dateTime);
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours hr${hours > 1 ? 's' : ''}';
    return '$hours hr${hours > 1 ? 's' : ''} $mins min';
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = widget.quiz.closeDate != null &&
        DateTime.now().isAfter(widget.quiz.closeDate!);
    final bool isUpcoming = widget.quiz.openDate != null &&
        DateTime.now().isBefore(widget.quiz.openDate!);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header Section
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Quiz Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.quiz_outlined,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title and Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.quiz.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Metadata Row
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            // Type Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.green),
                              ),
                              child: const Text(
                                'Quiz',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            // Questions Count
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.help_outline,
                                    size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.quiz.questions} questions',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),

                            // Duration
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined,
                                    size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(
                                      widget.quiz.durationMinutes ?? 45),
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),

                            // Status
                            if (isOverdue)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      size: 14, color: Colors.red[400]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Closed',
                                    style: TextStyle(
                                      color: Colors.red[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            else if (isUpcoming)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.schedule,
                                      size: 14, color: Colors.orange[400]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Upcoming',
                                    style: TextStyle(
                                      color: Colors.orange[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 14, color: Colors.green[400]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      color: Colors.green[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expand/Collapse Icon
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                const Divider(color: AppColors.border, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      if (widget.quiz.description != null &&
                          widget.quiz.description!.isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.quiz.description!,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Quiz Details Grid
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Opens',
                              value: widget.quiz.openDate != null
                                  ? _formatDateTime(widget.quiz.openDate!)
                                  : 'Not set',
                              color: Colors.blue,
                            ),
                            if (widget.quiz.closeDate != null) ...[
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                icon: Icons.event_busy_outlined,
                                label: 'Closes',
                                value: _formatDateTime(widget.quiz.closeDate!),
                                color: Colors.red,
                              ),
                            ],
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              icon: Icons.repeat,
                              label: 'Attempts Allowed',
                              value: '${widget.quiz.maxAttempts}',
                              color: Colors.purple,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              icon: Icons.grade_outlined,
                              label: 'Total Points',
                              value: '${widget.quiz.points ?? 100}',
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Navigate to Quiz Detail/Edit page
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('View Details coming soon!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility_outlined,
                                  size: 18),
                              label: const Text('View Details'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: BorderSide(color: Colors.blue[700]!),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onReviewWork,
                              icon: const Icon(Icons.rate_review, size: 18),
                              label: const Text('Review Work'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Edit/Delete Buttons
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                // TODO: Navigate to Edit Quiz page
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Edit Quiz coming soon!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.orange[400],
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => _deleteQuiz(),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red[400],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _deleteQuiz() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title:
            const Text('Delete Quiz?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${widget.quiz.title}"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: Call repository to delete quiz
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quiz "${widget.quiz.title}" deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
