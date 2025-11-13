import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final CourseModel course;

  const CourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
        boxShadow: [
          BoxShadow(color: course.color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [course.color.withOpacity(0.15), const Color(0xFF111827)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER: TÊN MÔN HỌC
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: course.color.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: course.color.withOpacity(0.3), width: 1)),
                ),
                child: Text(
                  course.title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              // BODY: GIẢNG VIÊN + THỜI GIAN + KHOA
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.teacher,
                        style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _infoRow(Icons.access_time, course.time),
                      const SizedBox(height: 4),
                      _infoRow(Icons.location_on, course.faculty),
                    ],
                  ),
                ),
              ),
              // FOOTER: NÚT
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[800]!, width: 1))),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: course.color,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text(
                          'Go to Class',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 28,
                      width: 28,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: course.color.withOpacity(0.5)),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: Icon(Icons.folder_open, size: 12, color: course.color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 10, color: Colors.grey[500]),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// MODEL: Dùng chung
class CourseModel {
  final String id, title, teacher, time, faculty;
  final Color color;
  CourseModel({
    required this.id,
    required this.title,
    required this.teacher,
    required this.time,
    required this.faculty,
    required this.color,
  });
}