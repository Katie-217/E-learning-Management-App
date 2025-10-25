import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/course_provider.dart';
import '../../../../core/theme/app_colors.dart';

class CourseFilterWidget extends ConsumerWidget {
  const CourseFilterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseState = ref.watch(courseProvider);
    final courseNotifier = ref.read(courseProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bộ lọc học kì - bên trái
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Học kì',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: courseState.selectedSemester,
                      isExpanded: true,
                      dropdownColor: AppColors.bgInput,
                      style: const TextStyle(color: Colors.white),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      items: courseNotifier.getAvailableSemesters().map((semester) {
                        return DropdownMenuItem<String>(
                          value: semester,
                          child: Text(
                            semester == 'All' 
                                ? 'Tất cả học kì' 
                                : semester,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          courseNotifier.filterCoursesBySemester(newValue);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Hiển thị thống kê - bên phải
          SizedBox(
            width: 200,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.indigo.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kết quả',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${courseState.filteredCourses.length} khóa học',
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
