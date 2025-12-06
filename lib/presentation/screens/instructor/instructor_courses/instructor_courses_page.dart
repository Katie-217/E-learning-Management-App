import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/presentation/screens/instructor/instructor_courses/instructor_course_detail_page.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/widget_course/course_card_widget.dart';
import 'package:elearning_management_app/application/controllers/course/course_instructor_provider.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/widget_course/semester_filter_instructor.dart';
import 'package:elearning_management_app/presentation/screens/instructor/csv_import/csv_import_semester.dart';
import 'package:elearning_management_app/application/controllers/semester/semester_provider.dart';
import 'package:elearning_management_app/presentation/screens/instructor/instructor_courses/instructor_course_create.dart';

class InstructorCoursesPage extends ConsumerStatefulWidget {
  const InstructorCoursesPage({
    super.key,
  });

  @override
  ConsumerState<InstructorCoursesPage> createState() =>
      _InstructorCoursesPageState();
}

class _InstructorCoursesPageState extends ConsumerState<InstructorCoursesPage> {
  String? _selectedSemesterId;
  bool _showImportView = false; // State để điều khiển hiển thị import view
  bool _showDetailView = false;
  String? _selectedCourseId;

  // Constants for uniform sizing
  static const double kImportButtonWidth = 160.0; // Compact for Import CSV
  static const double kSemesterDropdownWidth = 280.0; // Wide for semester names
  static const double kActionButtonHeight =
      50.0; // Uniform height for all action buttons

  void _navigateToCreateCourse() {
    print('🚀 InstructorCoursesPage: About to navigate to CreateCoursePage');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateCoursePage(
          onSuccess: () {
            print('🔄 Course created successfully! Refreshing courses...');
            // Refresh courses list without resetting filters
            ref
                .read(courseInstructorProvider.notifier)
                .refreshInstructorCourses();
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Load instructor courses when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courseInstructorProvider.notifier).loadInstructorCourses();
    });
  }

  Widget _buildImportMenu({
    double? buttonWidth,
    double? buttonHeight,
    bool isSmallScreen = false,
  }) {
    final width = buttonWidth ?? kImportButtonWidth;
    final height = buttonHeight ?? kActionButtonHeight;
    final iconSize = isSmallScreen ? 14.0 : 16.0;
    final fontSize = isSmallScreen ? 12.0 : 14.0;
    final horizontalPadding = isSmallScreen ? 8.0 : 12.0;
    final verticalPadding = isSmallScreen ? 6.0 : 8.0;
    final spacing = isSmallScreen ? 4.0 : 6.0;
    
    return MenuAnchor(
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
        return SizedBox(
          width: width,
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
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              fixedSize: Size(double.infinity, height),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.file_upload, size: iconSize),
                SizedBox(width: spacing),
                Flexible(
                  child: Text(
                    'Import CSV',
                    style: TextStyle(fontSize: fontSize),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: spacing),
                Icon(Icons.keyboard_arrow_down, size: iconSize),
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showDetailView
          ? _buildCourseDetailView()
          : _buildCourseOverview(instructorCoursesState),
    );
  }

  Widget _buildCourseOverview(InstructorCourseState instructorCoursesState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: const ValueKey('instructor-course-list'),
      children: [
        // Header Section - Responsive layout: buttons move to next line on small screens
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isSmallScreen = screenWidth < 600;
            
            // Responsive sizing
            final titleSize = isSmallScreen ? 20.0 : 28.0;
            final iconSize = isSmallScreen ? 22.0 : 28.0;
            final buttonSpacing = isSmallScreen ? 8.0 : 12.0;
            final importButtonWidth = isSmallScreen ? 140.0 : kImportButtonWidth;
            final semesterDropdownWidth = isSmallScreen ? 200.0 : kSemesterDropdownWidth;
            final buttonHeight = isSmallScreen ? 44.0 : kActionButtonHeight;
            
            if (isSmallScreen) {
              // Small screen: Title on first line, buttons on second line
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First line: Title + Add Icon
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'My Teaching Courses',
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6.0),
                      IconButton(
                        onPressed: () => _navigateToCreateCourse(),
                        icon: Icon(
                          Icons.add_circle,
                          size: iconSize,
                          color: Colors.indigo,
                        ),
                        tooltip: 'Create Course',
                        padding: EdgeInsets.all(4.0),
                        constraints: BoxConstraints(
                          minWidth: 36.0,
                          minHeight: 36.0,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Second line: Action buttons
                  Row(
                    children: [
                      _buildImportMenu(
                        buttonWidth: importButtonWidth,
                        buttonHeight: buttonHeight,
                        isSmallScreen: isSmallScreen,
                      ),
                      SizedBox(width: buttonSpacing),
                      Expanded(
                        child: SizedBox(
                          height: buttonHeight,
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
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // Large screen: Everything on one line
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Block: Title + Add Icon
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'My Teaching Courses',
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.0),
                        IconButton(
                          onPressed: () => _navigateToCreateCourse(),
                          icon: Icon(
                            Icons.add_circle,
                            size: iconSize,
                            color: Colors.indigo,
                          ),
                          tooltip: 'Create Course',
                          padding: EdgeInsets.all(8.0),
                          constraints: BoxConstraints(
                            minWidth: 48.0,
                            minHeight: 48.0,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right Block: Action buttons
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildImportMenu(
                          buttonWidth: importButtonWidth,
                          buttonHeight: buttonHeight,
                          isSmallScreen: isSmallScreen,
                        ),
                        SizedBox(width: buttonSpacing),
                        SizedBox(
                          width: semesterDropdownWidth,
                          height: buttonHeight,
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

  Widget _buildCourseDetailView() {
    return InstructorCourseDetailContent(
      key: ValueKey('instructor-course-detail-${_selectedCourseId ?? ''}'),
      courseId: _selectedCourseId!,
      onBack: _closeDetailView,
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
                _openCourseDetail(course.id);
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

  void _openCourseDetail(String courseId) {
    setState(() {
      _selectedCourseId = courseId;
      _showDetailView = true;
    });
  }

  void _closeDetailView() {
    setState(() {
      _showDetailView = false;
      _selectedCourseId = null;
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
