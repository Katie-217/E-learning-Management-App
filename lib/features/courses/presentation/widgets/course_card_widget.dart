import 'package:flutter/material.dart';
import '../../../../data/models/course_model.dart';

class CourseCardWidget extends StatefulWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const CourseCardWidget({super.key, required this.course, required this.onTap});

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
                gradient: const LinearGradient(colors: [Colors.blue, Colors.cyan]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _chip(c.code),
                        _chip(c.group),
                      ]),
                  const Spacer(),
                  Text(c.name,
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
                    Row(children: [
                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(c.instructor,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey, fontSize: 13))),
                    ]),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${c.sessions} sessions',
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('${c.students} students',
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    const Text('Progress',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Stack(children: [
                      Container(
                          height: 6,
                          decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8))),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 6,
                        width: MediaQuery.of(context).size.width * (c.progress / 100) / 3,
                        decoration: BoxDecoration(
                            color: Colors.indigo[500],
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text('${c.progress}%',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.indigo)),
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
}