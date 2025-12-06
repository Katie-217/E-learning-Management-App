import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/application/controllers/course/course_provider.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          // Tính toán width responsive
          final semesterWidth = screenWidth > 600 
              ? 220.0 
              : screenWidth > 400 
                  ? (screenWidth - 100) * 0.5 
                  : (screenWidth - 80) * 0.5;
          final resultWidth = screenWidth > 600 
              ? 200.0 
              : screenWidth > 400 
                  ? (screenWidth - 100) * 0.45 
                  : (screenWidth - 80) * 0.45;
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Semester Filter - bên trái với chiều rộng giới hạn
              Flexible(
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
                      constraints: BoxConstraints(maxWidth: semesterWidth),
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
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.white),
                          items: courseNotifier
                              .getAvailableSemesters()
                              .map((semester) {
                            return DropdownMenuItem<String>(
                              value: semester,
                              child: Text(
                                semester == 'All' ? 'Tất cả học kì' : semester,
                                style: const TextStyle(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
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
              SizedBox(width: screenWidth > 600 ? 16 : 8),
              // Results Display - bên phải với chiều rộng giới hạn
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Kết quả',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: BoxConstraints(maxWidth: resultWidth),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 600 ? 16 : 12,
                        vertical: screenWidth > 600 ? 12 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.indigo.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${courseState.filteredCourses.length} khóa học',
                        style: TextStyle(
                          color: Colors.indigo,
                          fontSize: screenWidth > 600 ? 16 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
