import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/data/repositories/course/enrollment_repository.dart';

class CourseCard extends StatefulWidget {
  final CourseModel course;
  final VoidCallback? onTap;

  const CourseCard({super.key, required this.course, this.onTap});

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  final EnrollmentRepository _enrollmentRepo = EnrollmentRepository();
  int? _studentCount;
  bool _isLoadingCount = true;

  @override
  void initState() {
    super.initState();
    _loadStudentCount();
  }

  Future<void> _loadStudentCount() async {
    try {
      final count =
          await _enrollmentRepo.countStudentsInCourse(widget.course.id);
      if (mounted) {
        setState(() {
          _studentCount = count;
          _isLoadingCount = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _studentCount = 0;
          _isLoadingCount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Gradient
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Colors.indigo, Colors.purple]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _chip(widget.course.code),
                        _statusChip(widget.course.status),
                      ]),
                  const Spacer(),
                  Text(widget.course.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instructor Row
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(widget.course.instructor,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13))),
                    ]),
                    const SizedBox(height: 8),

                    // Semester Row
                    Row(children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(widget.course.semester,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13))),
                    ]),
                    const SizedBox(height: 8),

                    // Sessions Count & Student Count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${widget.course.sessions} sessions',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        Text(
                            _isLoadingCount
                                ? 'Students: ...'
                                : 'Students: $_studentCount',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),

                    // Actions Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Manage',
                              style: TextStyle(fontSize: 12)),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.indigo.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Icon(Icons.more_horiz,
                              size: 12, color: Colors.indigo),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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

  Widget _statusChip(String status) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: status == 'active'
              ? Colors.green.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status == 'active' ? 'Active' : 'Archived',
          style: TextStyle(
            color: status == 'active' ? Colors.green : Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
