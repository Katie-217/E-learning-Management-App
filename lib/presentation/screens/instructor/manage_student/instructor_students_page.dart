import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../application/controllers/student/student_controller.dart';
import '../../../../application/controllers/course/course_instructor_controller.dart';
import '../../../../application/controllers/group/group_controller.dart';
import '../../../../application/controllers/course/enrollment_controller.dart';
import '../../../../domain/models/user_model.dart';
import '../../../../domain/models/course_model.dart';
import '../../../../domain/models/group_model.dart';
import '../../../../data/repositories/auth/auth_repository.dart';
import '../../../../data/repositories/group/group_repository.dart';
import 'instructor_student_create.dart';
import '../csv_import/csv_import_screen.dart';
import 'edit_students.dart';

class InstructorStudentsPage extends StatefulWidget {
  // Callbacks
  final VoidCallback? onCreateStudentPressed;
  final VoidCallback? onImportCSVPressed;

  const InstructorStudentsPage({
    super.key,
    this.onCreateStudentPressed,
    this.onImportCSVPressed,
  });

  @override
  State<InstructorStudentsPage> createState() => _InstructorStudentsPageState();
}

class _InstructorStudentsPageState extends State<InstructorStudentsPage> {
  late StudentController _studentController;
  StudentEditController? _editController; // Made nullable for safety
  late CourseInstructorController _courseController;
  late GroupController _groupController;
  late EnrollmentController _enrollmentController;

  List<UserModel> students = [];
  List<UserModel> filteredStudents = [];
  bool isLoading = false;
  String searchQuery = '';

  // Filter state
  List<CourseModel> _courses = [];
  List<GroupModel> _groups = [];
  CourseModel? _selectedCourse;
  GroupModel? _selectedGroup;
  bool _isLoadingGroups = false;

  // Controllers for dropdowns to show selected values
  final TextEditingController _courseFilterController =
      TextEditingController(text: 'All Courses');
  final TextEditingController _groupFilterController =
      TextEditingController(text: 'All Groups');

  final TextEditingController _searchController = TextEditingController();

  void _navigateToCreateStudent() {
    print('🚀 Navigate to Create Student');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateStudentPage(
          onSuccess: () {
            print('🔄 Student created successfully! Refreshing list...');
            _loadStudents(); // Refresh student list
          },
        ),
      ),
    );
  }

  void _navigateToImportCSV() {
    print('🚀 Navigate to Import CSV');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CsvImportScreen(
          dataType: 'students',
          onImportComplete: (success, message) {
            print('🔄 CSV import completed: $success - $message');
            if (success) {
              _loadStudents(); // Refresh student list
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _studentController = StudentController(
      authRepository: AuthRepository.defaultClient(),
    );
    _editController = StudentEditController(_studentController);
    _courseController = CourseInstructorController(
      authRepository: AuthRepository.defaultClient(),
    );
    _groupController = GroupController();
    _enrollmentController = EnrollmentController();

    _loadStudents();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await _courseController.getInstructorCourses();
      setState(() {
        _courses = courses;
      });
    } catch (e) {
      print('Error loading courses: $e');
    }
  }

  Future<void> _loadGroupsForCourse(String courseId) async {
    setState(() {
      _isLoadingGroups = true;
      _selectedGroup = null;
      _groups = [];
    });

    try {
      final groups = await GroupRepository.getGroupsByCourse(courseId);
      setState(() {
        _groups = groups;
        _isLoadingGroups = false;
      });
    } catch (e) {
      print('Error loading groups: $e');
      setState(() => _isLoadingGroups = false);
    }
  }

  Future<void> _loadStudents() async {
    setState(() => isLoading = true);

    try {
      final loadedStudents = await _studentController.getAllStudents();
      setState(() {
        students = loadedStudents;
        _applyFilter();
      });

      if (mounted) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _applyFilter() async {
    List<UserModel> filtered = students;

    // Apply course/group filter
    if (_selectedCourse != null) {
      try {
        final enrolledStudents = await _enrollmentController
            .getEnrolledStudents(_selectedCourse!.id);
        final enrolledEmails = enrolledStudents
            .map((e) => e.studentEmail?.toLowerCase())
            .whereType<String>()
            .toSet();

        if (_selectedGroup != null) {
          // Filter by specific group
          final groupEnrollments =
              enrolledStudents.where((e) => e.groupId == _selectedGroup!.id);
          final groupEmails = groupEnrollments
              .map((e) => e.studentEmail?.toLowerCase())
              .whereType<String>()
              .toSet();
          filtered = filtered
              .where((s) => groupEmails.contains(s.email.toLowerCase()))
              .toList();
        } else {
          // Filter by course only (all groups)
          filtered = filtered
              .where((s) => enrolledEmails.contains(s.email.toLowerCase()))
              .toList();
        }
      } catch (e) {
        print('Error filtering by course/group: $e');
      }
    }

    // Apply search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((s) =>
              s.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              s.email.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    setState(() {
      filteredStudents = filtered;
    });
  }

  void _showStudentDetail(UserModel student) {
    if (_editController == null) {
      // Initialize if not yet initialized (safety check)
      _editController = StudentEditController(_studentController);
    }

    showDialog(
      context: context,
      builder: (context) => StudentEditDialog(
        student: student,
        controller: _editController!,
        onUpdated: _loadStudents,
      ),
    );
  }

  // Các hàm edit/delete đã được chuyển vào edit_students.dart

  // Filter Bar with Cascading Dropdowns
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        children: [
          Expanded(child: _buildCourseDropdown()),
          const SizedBox(width: 12),
          Expanded(child: _buildGroupDropdown()),
        ],
      ),
    );
  }

  Widget _buildCourseDropdown() {
    // Add "All Courses" option
    final allCoursesOption = CourseModel(
      id: '',
      code: '',
      name: 'All Courses',
      instructor: '',
      semester: '',
      sessions: 0,
    );

    final dropdownItems = [allCoursesOption, ..._courses];

    return DropdownMenu<CourseModel>(
      controller:
          _courseFilterController, // Add controller to show selected value
      enableFilter: true,
      enableSearch: true,
      menuHeight: 150, // Max 3 items visible
      requestFocusOnTap: true,
      width: 400, // Fixed width for proper display
      label: const Text('Filter by Course'),
      hintText: 'Select course',
      leadingIcon: const Icon(Icons.school, size: 20),
      textStyle: const TextStyle(color: Colors.white, fontSize: 14),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
      ),
      onSelected: (CourseModel? course) {
        setState(() {
          _selectedCourse = (course?.id.isEmpty ?? true) ? null : course;
          _selectedGroup = null; // Reset group selection
          _groups = [];

          // Update controller text
          _courseFilterController.text = course?.name ?? 'All Courses';
          _groupFilterController.text = 'All Groups'; // Reset group to default
        });
        if (_selectedCourse != null) {
          _loadGroupsForCourse(_selectedCourse!.id);
        } else {
          // If "All Courses" selected, apply filter immediately
          _applyFilter();
        }
      },
      dropdownMenuEntries: dropdownItems.map((course) {
        return DropdownMenuEntry<CourseModel>(
          value: course,
          label: course.name,
          leadingIcon: Icon(
            course.id.isEmpty ? Icons.clear_all : Icons.book,
            color: course.id.isEmpty ? Colors.grey : Colors.blue[400],
            size: 16,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupDropdown() {
    final bool isEnabled = _selectedCourse != null && !_isLoadingGroups;

    // Add "All Groups" option
    final allGroupsOption = GroupModel(
      id: '',
      name: 'All Groups',
      code: '',
      courseId: '',
      createdAt: DateTime.now(),
      createdBy: '',
    );

    final dropdownItems =
        isEnabled ? [allGroupsOption, ..._groups] : [allGroupsOption];

    // Use single DropdownMenu widget for both states
    // Wrap in IgnorePointer to block clicks when disabled
    return IgnorePointer(
      ignoring: !isEnabled,
      child: DropdownMenu<GroupModel>(
        key: ValueKey(_selectedCourse?.id ??
            'no-course'), // Force rebuild when course changes
        controller:
            _groupFilterController, // Add controller to show selected value
        enableFilter: true,
        enableSearch: true,
        menuHeight: 150, // Max 3 items visible
        requestFocusOnTap: true,
        width: 400, // Fixed width for proper display
        label: const Text('Filter by Group'),
        hintText: isEnabled ? 'Select group' : 'Select course first',
        textStyle: TextStyle(
          color: isEnabled ? Colors.white : Colors.white38,
          fontSize: 14,
        ),
        leadingIcon: _isLoadingGroups
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.group,
                size: 20,
                color: isEnabled ? Colors.white : Colors.white38,
              ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: isEnabled ? Colors.grey[800] : Colors.grey[850],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isEnabled ? Colors.grey[600]! : Colors.grey[700]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isEnabled ? Colors.grey[600]! : Colors.grey[700]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          labelStyle: TextStyle(
            color: isEnabled ? Colors.white70 : Colors.white38,
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            color: isEnabled ? Colors.white54 : Colors.white38,
            fontSize: 14,
          ),
        ),
        onSelected: (GroupModel? group) {
          setState(() {
            _selectedGroup = (group?.id.isEmpty ?? true) ? null : group;

            // Update controller text
            _groupFilterController.text = group?.name ?? 'All Groups';
          });
          _applyFilter();
        },
        dropdownMenuEntries: dropdownItems.map((group) {
          return DropdownMenuEntry<GroupModel>(
            value: group,
            label: group.name,
            leadingIcon: Icon(
              group.id.isEmpty ? Icons.clear_all : Icons.group,
              color: group.id.isEmpty ? Colors.grey : Colors.green[400],
              size: 16,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStudentCard(UserModel student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: const Color(0xFF1F2937),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo[600],
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          student.name,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          '${student.email}',
          style: TextStyle(color: Colors.grey[400]),
        ),
        onTap: () => _showStudentDetail(student),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => _showStudentDetail(student),
        ),
      ),
    );
  }

  Widget _buildStudentsContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
        ),
      );
    }

    if (filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'No students found',
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) =>
          _buildStudentCard(filteredStudents[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Students',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _navigateToCreateStudent(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _navigateToImportCSV(),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Manage and monitor your students',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
        const SizedBox(height: 24),

        // Filter Bar
        _buildFilterBar(),

        // Search bar
        TextField(
          controller: _searchController,
          onChanged: (query) {
            setState(() {
              searchQuery = query;
              _applyFilter();
            });
          },
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search by name or email...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            filled: true,
            fillColor: const Color(0xFF1F2937),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        searchQuery = '';
                        _applyFilter();
                      });
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),

        // Results count
        Text(
          'Results: ${filteredStudents.length} students',
          style:
              TextStyle(color: Colors.indigo[400], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),

        // List
        Expanded(child: _buildStudentsContent()),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
