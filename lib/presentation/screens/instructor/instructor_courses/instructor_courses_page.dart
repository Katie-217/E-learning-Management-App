import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/presentation/screens/instructor/instructor_courses/instructor_course_detail_page.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/widget_course/course_card_widget.dart';
import 'package:elearning_management_app/application/controllers/course/course_instructor_provider.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/widget_course/semester_filter_instructor.dart';
import 'package:elearning_management_app/presentation/screens/instructor/csv_import/csv_import_semester.dart';
import 'package:elearning_management_app/application/controllers/semester/semester_provider.dart';

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
  String? _selectedSemesterId;
  bool _showImportView = false; // State để điều khiển hiển thị import view

  // Constants for uniform sizing
  static const double kImportButtonWidth = 160.0; // Compact for Import CSV
  static const double kSemesterDropdownWidth = 280.0; // Wide for semester names
  static const double kActionButtonHeight =
      50.0; // Uniform height for all action buttons

  @override
  void initState() {
    super.initState();
    // Load instructor courses when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courseInstructorProvider.notifier).loadInstructorCourses();
    });
  }

  Widget _buildImportMenu() {
    return MenuAnchor(
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
        return SizedBox(
          width: kImportButtonWidth, // Compact width for Import button
          child: ElevatedButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              fixedSize: const Size(double.infinity,
                  kActionButtonHeight), // Fixed height for alignment
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.file_upload, size: 16), // Added upload icon
                SizedBox(width: 6),
                Text('Import CSV'),
                SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down, size: 16),
              ],
            ),
          ),
        );
      },
      menuChildren: [
        MenuItemButton(
          onPressed: () {
            // TODO: Implement Import Courses functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Import Courses functionality will be implemented'),
                backgroundColor: Colors.indigo,
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text('Import Courses', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
        MenuItemButton(
          onPressed: () {
            _showSemesterImportView();
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text('Import Semesters', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Color(0xFF1F2937)),
        elevation: WidgetStatePropertyAll(8),
        fixedSize: WidgetStatePropertyAll(
            Size(180, double.infinity)), // Match button width
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instructorCoursesState = ref.watch(courseInstructorProvider);

    // If showing import view, return ONLY the import screen (full page replacement)
    if (_showImportView) {
      return CsvImportSemesterScreen(
        onImportComplete: _onImportComplete,
        onCancel: _hideImportView,
      );
    }

    // Normal courses view
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section - Block-based responsive layout
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available space for action buttons
            final availableWidth = constraints.maxWidth;
            final titleBlockWidth = 350; // Approximate width of title + icon
            final actionBlockWidth = kImportButtonWidth +
                kSemesterDropdownWidth +
                12; // 12 = spacing
            final needsWrapping = availableWidth <
                (titleBlockWidth + actionBlockWidth + 24); // 24 = margin

            if (needsWrapping) {
              // Mobile Layout - Stack vertically with blocks
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Block: Title + Add Icon (stays together)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'My Teaching Courses',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: widget.onCreateCoursePressed,
                        icon: const Icon(
                          Icons.add_circle,
                          size: 26,
                          color: Colors.indigo,
                        ),
                        tooltip: 'Create Course',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Right Block: Action buttons (move together, wrap when needed)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.end, // Right-align when wrapping
                      children: [
                        _buildImportMenu(),
                        SizedBox(
                          width: kSemesterDropdownWidth,
                          height:
                              kActionButtonHeight, // Fixed height for alignment
                          child: SemesterFilterInstructor(
                            selectedSemesterId: _selectedSemesterId,
                            onSemesterChanged: (String semesterId) {
                              setState(() {
                                _selectedSemesterId = semesterId;
                              });
                              ref
                                  .read(courseInstructorProvider.notifier)
                                  .filterCoursesBySemester(semesterId);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // Desktop Layout - Two blocks horizontally
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Block: Title + Add Icon
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'My Teaching Courses',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: widget.onCreateCoursePressed,
                        icon: const Icon(
                          Icons.add_circle,
                          size: 28,
                          color: Colors.indigo,
                        ),
                        tooltip: 'Create Course',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Right Block: Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildImportMenu(),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: kSemesterDropdownWidth,
                        height:
                            kActionButtonHeight, // Fixed height for alignment
                        child: SemesterFilterInstructor(
                          selectedSemesterId: _selectedSemesterId,
                          onSemesterChanged: (String semesterId) {
                            setState(() {
                              _selectedSemesterId = semesterId;
                            });
                            ref
                                .read(courseInstructorProvider.notifier)
                                .filterCoursesBySemester(semesterId);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
          },
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
            return CourseCard(
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

  void _showSemesterImportView() {
    // Show import screen embedded in current page body (preserve sidebar and header)
    setState(() {
      _showImportView = true;
    });
  }

  void _hideImportView() {
    setState(() {
      _showImportView = false;
    });
  }

  void _onImportComplete(bool success, String message) {
    // Ẩn import view
    _hideImportView();

    // Hiển thị kết quả
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );

    // Refresh data nếu thành công
    if (success && mounted) {
      // Refresh course data
      ref.read(courseInstructorProvider.notifier).loadInstructorCourses();

      // IMPORTANT: Refresh semester dropdown để hiển thị semester mới
      // Invalidate the semesterListProvider to force reload
      ref.invalidate(semesterListProvider);

      print('DEBUG: 🔄 Refreshed semester list after successful import');
    }
  }
}
