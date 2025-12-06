import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';

class CourseCardWidget extends StatefulWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const CourseCardWidget(
      {super.key, required this.course, required this.onTap});

  @override
  State<CourseCardWidget> createState() => _CourseCardWidgetState();
}

class _CourseCardWidgetState extends State<CourseCardWidget> {
  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Gradient - chiếm trọn chiều rộng
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: [Colors.blue, Colors.cyan]),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _chip(c.code),
                    const Spacer(),
                    Flexible(
                      child: Text(c.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
              // Content section - giảm padding và spacing
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(c.instructor,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13))),
                    ]),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${c.sessions} sessions',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        // TODO: Replace with async enrollment count
                        // Use EnrollmentRepository.countStudentsInCourse(c.id)
                        Text('Loading students...',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Status',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.status == 'active'
                            ? Colors.green.shade100
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        c.status == 'active' ? 'Active' : 'Archived',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: c.status == 'active'
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 11)),
      );
}
