import 'package:flutter/material.dart';
import '../../data/models/course_model.dart';

class CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(child: _buildContent(context)),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          colors: _getGradientColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                image: DecorationImage(
                  image: NetworkImage(course.imageUrl),
                  fit: BoxFit.cover,
                  opacity: 0.1,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                course.code,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getGradientColors().first,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getStatusIcon(), size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    _getStatusText(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(course.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  course.instructor,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.group, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              SizedBox(width: 4),
              Text('${course.totalStudents} students',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              Spacer(),
              Icon(Icons.credit_card, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              SizedBox(width: 4),
              Text('${course.credits} credits',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ],
          ),
          Spacer(),
          if (course.status == 'active') ...[
            SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  Text('${course.progress.toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getProgressColor())),
                ]),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: course.progress / 100,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation(_getProgressColor()),
                  minHeight: 4,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          SizedBox(width: 4),
          Text(course.semester, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          Spacer(),
          Icon(Icons.arrow_forward_ios, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
        ],
      ),
    );
  }

  List<Color> _getGradientColors() {
    switch (course.status) {
      case 'active':
        return [Colors.blue.shade400, Colors.blue.shade600];
      case 'completed':
        return [Colors.green.shade400, Colors.green.shade600];
      case 'paused':
        return [Colors.orange.shade400, Colors.orange.shade600];
      case 'archived':
        return [Colors.grey.shade400, Colors.grey.shade600];
      default:
        return [Colors.blue.shade400, Colors.blue.shade600];
    }
  }

  Color _getStatusColor() {
    switch (course.status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'paused':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  IconData _getStatusIcon() {
    switch (course.status) {
      case 'active':
        return Icons.play_circle;
      case 'completed':
        return Icons.check_circle;
      case 'paused':
        return Icons.pause_circle;
      case 'archived':
        return Icons.archive;
      default:
        return Icons.play_circle;
    }
  }

  String _getStatusText() {
    switch (course.status) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Done';
      case 'paused':
        return 'Paused';
      case 'archived':
        return 'Archived';
      default:
        return 'Active';
    }
  }

  Color _getProgressColor() {
    if (course.progress >= 80) return Colors.green;
    if (course.progress >= 50) return Colors.orange;
    return Colors.blue;
  }
}
