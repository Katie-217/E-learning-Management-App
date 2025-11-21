import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/course_model.dart'; // ✅ Import Model chính

class CourseCard extends StatelessWidget {
  final CourseModel course;
  // Callback khi nhấn vào card
  final VoidCallback? onTap; 

  const CourseCard({
    super.key, 
    required this.course,
    this.onTap,
  });

  // Helper để lấy màu (nếu Model chưa có field color, ta tạo màu giả lập dựa trên ID)
  Color get _courseColor {
    // Logic giả lập màu sắc dựa trên hash của ID để mỗi khóa học có màu cố định
    final colors = [Colors.blue, Colors.indigo, Colors.teal, Colors.orange, Colors.purple];
    return colors[course.id.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _courseColor;

    return GestureDetector( // ✅ Thêm GestureDetector để bắt sự kiện tap
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!, width: 1),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.15),
                    const Color(0xFF111827)
                  ],
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
                    color: color.withOpacity(0.2),
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12)),
                    border: Border(
                        bottom: BorderSide(
                            color: color.withOpacity(0.3), width: 1)),
                  ),
                  child: Text(
                    course.name, // ✅ Sửa title -> name
                    style: const TextStyle(
                        fontSize: 13, // Tăng font một chút cho dễ đọc
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                // BODY: GIẢNG VIÊN + THỜI GIAN
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Code: ${course.code}', // ✅ Hiển thị mã môn
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        _infoRow(Icons.calendar_today, course.semester),
                        const SizedBox(height: 4),
                        _infoRow(Icons.class_, '${course.sessions} Sessions'),
                      ],
                    ),
                  ),
                ),
                // FOOTER: NÚT
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(color: Colors.grey[800]!, width: 1))),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 28,
                          child: ElevatedButton(
                            onPressed: onTap, // Gọi callback onTap
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                            child: const Text(
                              'Manage',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
