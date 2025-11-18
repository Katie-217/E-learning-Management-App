import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/presentation/screens/instructor/instructor_courses/instructor_course_detail_page.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/presentation/widgets/course/Student_Course/course_card_widget.dart';
import 'package:elearning_management_app/application/controllers/course/course_instructor_provider.dart';

class InstructorCoursesPage extends ConsumerStatefulWidget {
  // 🆕 Callback
  final VoidCallback? onCreateCoursePressed;
  
  const InstructorCoursesPage({
    super.key,
    this.onCreateCoursePressed,
  });

  @override
  ConsumerState<InstructorCoursesPage> createState() =>
      _InstructorCoursesPageState();
}

class _InstructorCoursesPageState extends ConsumerState<InstructorCoursesPage> {
  String _selectedSemester = 'HK1/24-25';

  @override
  void initState() {
    super.initState();
    // Load instructor courses when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courseInstructorProvider.notifier).loadInstructorCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final instructorCoursesState = ref.watch(courseInstructorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Teaching Courses',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                // Add Course Button
                ElevatedButton.icon(
                  onPressed: widget.onCreateCoursePressed,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Course'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Semester Dropdown
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSemester,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white),
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color(0xFF1F2937),
                      items: ['HK1/24-25', 'HK2/23-24', 'HK1/23-24']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedSemester = newValue;
                          });
                          // Filter courses by semester
                          ref
                              .read(courseInstructorProvider.notifier)
                              .filterCoursesBySemester(newValue);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Manage and monitor your teaching courses',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
        const SizedBox(height: 24),

        // Results Summary
        Text(
          'Results: ${instructorCoursesState.filteredCourses.length} courses',
          style: TextStyle(
            color: Colors.indigo[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // Handle loading, error, and courses display
        Expanded(
          child: _buildCoursesContent(instructorCoursesState),
        ),
      ],
    );
  }

  Widget _buildCoursesContent(InstructorCourseState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading courses',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(courseInstructorProvider.notifier)
                    .refreshInstructorCourses();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No courses found',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t created any courses yet',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 3
            : constraints.maxWidth > 800
                ? 2
                : 1;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.25,
          ),
          itemCount: state.filteredCourses.length,
          itemBuilder: (context, index) {
            final course = state.filteredCourses[index];
            return CourseCardWidget(
              course: course,
              onTap: () {
                // Navigate to instructor course detail
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        InstructorCourseDetailPage(courseId: course.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}