import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/application/controllers/group/group_controller.dart';
import 'package:elearning_management_app/application/controllers/course/enrollment_controller.dart';
import 'package:elearning_management_app/presentation/widgets/course/instructor_course_people/export_student_CSV.dart';
import 'package:elearning_management_app/presentation/widgets/course/instructor_course_people/edit_student_group.dart';
import 'package:elearning_management_app/presentation/widgets/course/instructor_course_people/create_group_dialog.dart';

class InstructorPeopleTab extends ConsumerStatefulWidget {
  final CourseModel course;
  const InstructorPeopleTab({super.key, required this.course});

  @override
  ConsumerState<InstructorPeopleTab> createState() =>
      _InstructorPeopleTabState();
}

class _InstructorPeopleTabState extends ConsumerState<InstructorPeopleTab> {
  String selectedGroup = 'All Groups';
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load groups when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(groupControllerProvider.notifier)
          .getGroupsByCourse(widget.course.id);
    });
  }

  // Helper methods for working with GroupController
  List<DropdownMenuEntry<String>> _buildGroupDropdownEntries() {
    final groupsState = ref.watch(groupControllerProvider);

    return groupsState.when(
      data: (groups) {
        final List<String> groupNames = ['All Groups'];
        groupNames.addAll(groups.map((group) => group.name));

        return groupNames.map<DropdownMenuEntry<String>>((String group) {
          return DropdownMenuEntry<String>(
            value: group,
            label: group,
            style: MenuItemButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: selectedGroup == group
                  ? Colors.indigo.withOpacity(0.2)
                  : Colors.transparent,
            ),
            leadingIcon: Icon(Icons.group, color: Colors.indigo[400], size: 18),
            trailingIcon: selectedGroup == group
                ? Icon(Icons.check, color: Colors.indigo[400], size: 16)
                : null,
          );
        }).toList();
      },
      loading: () => [
        const DropdownMenuEntry<String>(
          value: 'All Groups',
          label: 'Loading...',
        ),
      ],
      error: (_, __) => [
        const DropdownMenuEntry<String>(
          value: 'All Groups',
          label: 'Error loading groups',
        ),
      ],
    );
  }

  List<String> _getAvailableGroupNames() {
    final groupsState = ref.watch(groupControllerProvider);

    return groupsState.when(
      data: (groups) {
        final List<String> groupNames = ['All Groups'];
        groupNames.addAll(groups.map((group) => group.name));
        return groupNames;
      },
      loading: () => ['All Groups'],
      error: (_, __) => ['All Groups'],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 600;
        final isMediumScreen = screenWidth < 900;
        
        // Responsive sizing
        final padding = isSmallScreen ? 12.0 : 16.0;
        final teacherTitleSize = isSmallScreen ? 16.0 : 18.0;
        final teacherIconSize = isSmallScreen ? 20.0 : 24.0;
        final teacherAvatarSize = isSmallScreen ? 40.0 : 48.0;
        final teacherPersonIconSize = isSmallScreen ? 20.0 : 24.0;
        final teacherNameSize = isSmallScreen ? 14.0 : 16.0;
        final teacherRoleSize = isSmallScreen ? 12.0 : 14.0;
        final sectionSpacing = isSmallScreen ? 16.0 : 20.0;
        final studentsTitleSize = isSmallScreen ? 16.0 : 18.0;
        final toolbarHeight = isSmallScreen ? 44.0 : 48.0;
        final listHeight = isSmallScreen ? 300.0 : 400.0;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teacher Section
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Teacher',
                          style: TextStyle(
                            fontSize: teacherTitleSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Icon(Icons.school, color: Colors.indigo[400], size: teacherIconSize),
                      ],
                    ),
                    SizedBox(height: padding),
                    Row(
                      children: [
                        Container(
                          width: teacherAvatarSize,
                          height: teacherAvatarSize,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                colors: [Colors.indigo, Colors.purple]),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person,
                              color: Colors.white, size: teacherPersonIconSize),
                        ),
                        SizedBox(width: isSmallScreen ? 10.0 : 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.course.instructor,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: teacherNameSize,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Course Instructor',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: teacherRoleSize),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.email_outlined, 
                              color: Colors.grey, 
                              size: isSmallScreen ? 20.0 : 24.0),
                          padding: EdgeInsets.all(isSmallScreen ? 4.0 : 8.0),
                          constraints: BoxConstraints(
                            minWidth: isSmallScreen ? 32.0 : 48.0,
                            minHeight: isSmallScreen ? 32.0 : 48.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: sectionSpacing),

              // Khu vực 1: Group Control Bar
              _buildGroupControlBar(),

              SizedBox(height: padding),

              // Students Section Title
              Text(
                'Students',
                style: TextStyle(
                  fontSize: studentsTitleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: isSmallScreen ? 10.0 : 12.0),

              // Khu vực 2: Student Toolbar
              SizedBox(
                height: toolbarHeight,
                child: _buildStudentToolbar(),
              ),

              SizedBox(height: padding),

              // Khu vực 3: Student List
              Container(
                height: listHeight,
                child: _buildStudentList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Khu vực 1: Group Control Bar - Responsive Layout with Constraints
  Widget _buildGroupControlBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile breakpoint
        bool isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          // Mobile layout: Horizontal row with proper spacing
          return Row(
            children: [
              // Group selector - takes available space
              Expanded(
                child: _buildGroupSplitButton(),
              ),
              const SizedBox(width: 8),
              // Import CSV button
              _buildImportCSVButton(),
            ],
          );
        } else {
          // Desktop layout: Horizontal row
          return Row(
            children: [
              // Group selector with FIXED constraint (no stretch)
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 280, // Giới hạn tối đa 280px
                  minWidth: 250, // Không nhỏ hơn 250px
                ),
                child: _buildGroupSplitButton(),
              ),
              const Spacer(), // Đẩy nút Import CSV về phải
              // Import CSV Dropdown (Far Right aligned)
              _buildImportCSVButton(),
            ],
          );
        }
      },
    );
  }

  // MenuAnchor Group Split Button: Group Selector + Create Group
  Widget _buildGroupSplitButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 600;
        
        final buttonHeight = isSmallScreen ? 44.0 : 48.0;
        final iconSize = isSmallScreen ? 18.0 : 20.0;
        final addButtonWidth = isSmallScreen ? 40.0 : 48.0;
        final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
        final verticalPadding = isSmallScreen ? 10.0 : 12.0;
        final fontSize = isSmallScreen ? 14.0 : 16.0;
        
        return Container(
          height: buttonHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Row(
            children: [
              // DropdownMenu với Search Filtering Logic
              Expanded(
                child: DropdownMenu<String>(
                  width: null, // Auto width
                  menuHeight: 150, // Giới hạn chiều cao 150px
                  enableFilter: true, // Bật tính năng filter
                  enableSearch: true, // Bật tính năng search
                  requestFocusOnTap: true,
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: fontSize),
                  ),
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize,
                  ),
                  menuStyle: MenuStyle(
                    backgroundColor:
                        MaterialStateProperty.all(const Color(0xFF1F2937)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  trailingIcon:
                      Icon(Icons.arrow_drop_down, color: Colors.grey, size: iconSize),
                  selectedTrailingIcon:
                      Icon(Icons.arrow_drop_up, color: Colors.grey, size: iconSize),
                  leadingIcon:
                      Icon(Icons.group, color: Colors.indigo[400], size: iconSize),
                  initialSelection: selectedGroup,
                  hintText: 'Search groups...',
                  // Filter function cho search logic
                  filterCallback:
                      (List<DropdownMenuEntry<String>> entries, String filter) {
                    if (filter.isEmpty) return entries;

                    return entries.where((entry) {
                      return entry.label
                          .toLowerCase()
                          .contains(filter.toLowerCase());
                    }).toList();
                  },
                  onSelected: (String? value) {
                    if (value != null) {
                      setState(() {
                        selectedGroup = value;
                      });
                    }
                  },
                  dropdownMenuEntries: _buildGroupDropdownEntries(),
                ),
              ),
              // Separator
              Container(
                width: 1,
                height: double.infinity,
                color: Colors.grey[700],
              ),
              // Create Group Button
              InkWell(
                onTap: _showCreateGroupDialog,
                child: Container(
                  width: addButtonWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.indigo[600],
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(7),
                      bottomRight: Radius.circular(7),
                    ),
                  ),
                  child: Icon(Icons.add, color: Colors.white, size: iconSize),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // TRUE MenuAnchor Import CSV Button (Anchored Dropdown)
  Widget _buildImportCSVButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 600;
        
        final buttonHeight = isSmallScreen ? 36.0 : 48.0;
        final iconSize = isSmallScreen ? 16.0 : 20.0;
        final fontSize = isSmallScreen ? 12.0 : 14.0;
        final horizontalPadding = isSmallScreen ? 10.0 : 16.0;
        final verticalPadding = isSmallScreen ? 8.0 : 12.0;
        final spacing = isSmallScreen ? 4.0 : 8.0;
        
        return MenuAnchor(
          alignmentOffset: const Offset(0, 5), // Neo sát xuống dưới
          style: MenuStyle(
            backgroundColor: MaterialStateProperty.all(const Color(0xFF1F2937)),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          builder: (context, controller, child) {
            return GestureDetector(
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              child: Container(
                height: buttonHeight,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_file, size: iconSize, color: Colors.white),
                    SizedBox(width: spacing),
                    Text('Import CSV',
                        style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.w500,
                            fontSize: fontSize)),
                    SizedBox(width: spacing / 2),
                    Icon(Icons.arrow_drop_down, color: Colors.white, size: iconSize),
                  ],
                ),
              ),
            );
          },
          menuChildren: [
            // Constrained Menu with fixed height 150px
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 150, // Giới hạn 150px
                minWidth: 200,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1F2937),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MenuItemButton(
                      onPressed: () => _showImportStudentsDialog(),
                      child: SizedBox(
                        height: isSmallScreen ? 44.0 : 48.0,
                        child: Row(
                          children: [
                            Icon(Icons.person_add, color: Colors.indigo, size: iconSize),
                            SizedBox(width: spacing),
                            Text('Import Students',
                                style: TextStyle(color: Colors.white, fontSize: fontSize)),
                          ],
                        ),
                      ),
                    ),
                    MenuItemButton(
                      onPressed: () => _showImportGroupsDialog(),
                      child: SizedBox(
                        height: isSmallScreen ? 44.0 : 48.0,
                        child: Row(
                          children: [
                            Icon(Icons.group_add, color: Colors.green, size: iconSize),
                            SizedBox(width: spacing),
                            Text('Import Groups',
                                style: TextStyle(color: Colors.white, fontSize: fontSize)),
                          ],
                        ),
                      ),
                    ),
                    MenuItemButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Download CSV Template'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      child: SizedBox(
                        height: isSmallScreen ? 44.0 : 48.0,
                        child: Row(
                          children: [
                            Icon(Icons.download, color: Colors.blue, size: iconSize),
                            SizedBox(width: spacing),
                            Text('Download Template',
                                style: TextStyle(color: Colors.white, fontSize: fontSize)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Khu vực 2: Student Toolbar
  Widget _buildStudentToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 600;
        
        final iconSize = isSmallScreen ? 18.0 : 20.0;
        final fontSize = isSmallScreen ? 13.0 : 14.0;
        final hintSize = isSmallScreen ? 12.0 : 14.0;
        final spacing = isSmallScreen ? 6.0 : 12.0;
        
        return Row(
          children: [
            // Smart Search Bar with integrated Add Student button
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Colors.white, fontSize: fontSize),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: isSmallScreen ? 'Search...' : 'Search by name or email...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: hintSize),
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: iconSize),
                  suffixIcon: Container(
                    margin: EdgeInsets.all(isSmallScreen ? 3.0 : 4.0),
                    decoration: BoxDecoration(
                      color: Colors.indigo[600],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      onPressed: _showAddSingleStudentDialog,
                      icon: Icon(Icons.add, color: Colors.white, size: iconSize),
                      tooltip: 'Add Single Student',
                      padding: EdgeInsets.all(isSmallScreen ? 4.0 : 8.0),
                      constraints: BoxConstraints(
                        minWidth: isSmallScreen ? 32.0 : 40.0,
                        minHeight: isSmallScreen ? 32.0 : 40.0,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.indigo),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1F2937),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10.0 : 12.0,
                    vertical: isSmallScreen ? 10.0 : 12.0,
                  ),
                  isDense: isSmallScreen,
                ),
              ),
            ),
            SizedBox(width: spacing),
            // Export List Button - Tách component
            ExportStudentCSV(
              selectedGroup: selectedGroup,
              onExport: () {}, // Empty callback since component handles its own logic
              isSmallScreen: isSmallScreen,
            ),
          ],
        );
      },
    );
  }

  // Khu vực 3: Student List (Group-filtered)
  Widget _buildStudentList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getFilteredStudents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isSmallScreen = screenWidth < 600;
              
              final iconSize = isSmallScreen ? 48.0 : 64.0;
              final titleSize = isSmallScreen ? 16.0 : 18.0;
              final errorSize = isSmallScreen ? 12.0 : 14.0;
              final spacing = isSmallScreen ? 12.0 : 16.0;
              
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: iconSize, color: Colors.red[400]),
                    SizedBox(height: spacing),
                    Text(
                      'Error loading students',
                      style: TextStyle(
                        fontSize: titleSize,
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallScreen ? 6.0 : 8.0),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 24.0),
                      child: Text(
                        '${snapshot.error}',
                        style: TextStyle(
                          fontSize: errorSize,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }

        final filteredStudents = snapshot.data ?? [];

        if (filteredStudents.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isSmallScreen = screenWidth < 600;
              
              final iconSize = isSmallScreen ? 48.0 : 64.0;
              final titleSize = isSmallScreen ? 14.0 : 16.0;
              final subtitleSize = isSmallScreen ? 12.0 : 14.0;
              final spacing = isSmallScreen ? 12.0 : 16.0;
              
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: iconSize, color: Colors.grey[600]),
                    SizedBox(height: spacing),
                    Text(
                      selectedGroup == 'All Groups'
                          ? 'No students found'
                          : 'No students in $selectedGroup',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: titleSize,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallScreen ? 6.0 : 8.0),
                    Text(
                      'Try adding students to this group',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: subtitleSize,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );
        }

        return ListView.builder(
          itemCount: filteredStudents.length,
          itemBuilder: (context, index) {
            if (index >= filteredStudents.length)
              return const SizedBox.shrink();

            final student = filteredStudents[index];
            if (student.isEmpty) return const SizedBox.shrink();

            // Generate initials and color for avatar
            final name = (student['name'] as String?) ?? 'Unknown';
            final initials = name.isNotEmpty
                ? name
                    .split(' ')
                    .map((e) => e.isNotEmpty ? e[0] : '')
                    .take(2)
                    .join()
                    .toUpperCase()
                : '?';
            final color =
                Colors.primaries[name.hashCode % Colors.primaries.length];

            return LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isSmallScreen = screenWidth < 600;
                
                final avatarSize = isSmallScreen ? 36.0 : 40.0;
                final nameSize = isSmallScreen ? 14.0 : 16.0;
                final emailSize = isSmallScreen ? 11.0 : 12.0;
                final idSize = isSmallScreen ? 10.0 : 11.0;
                final initialsSize = isSmallScreen ? 12.0 : 14.0;
                final padding = isSmallScreen ? 10.0 : 12.0;
                final spacing = isSmallScreen ? 10.0 : 12.0;
                
                return Container(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 6.0 : 8.0),
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: initialsSize,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: spacing),
                      // Student Info (Name, Email, MSSV)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: nameSize,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isSmallScreen ? 1.0 : 2.0),
                            Text(
                              (student['email'] as String?) ?? 'No email',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: emailSize,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isSmallScreen ? 1.0 : 2.0),
                            Text(
                              (student['studentId'] as String?) ?? 'No ID',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: idSize,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Actions Menu - Tách component
                      EditStudentGroup(
                        student: student,
                        availableGroups: _getAvailableGroupNames(),
                        currentGroup: selectedGroup,
                        onMoveStudent: (student) {
                          // Handle move student logic
                          setState(() {
                            // Refresh the student list
                          });
                        },
                        onRemoveStudent: (student) {
                          // Handle remove student logic
                          setState(() {
                            // Refresh the student list
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Helper Methods
  Future<List<Map<String, dynamic>>> _getFilteredStudents() async {
    try {
      // Get enrollments for this course from EnrollmentController
      final enrollmentController = EnrollmentController();
      final enrollments =
          await enrollmentController.getEnrolledStudents(widget.course.id);

      // Get groups to map group IDs to group names
      final groupsState = ref.read(groupControllerProvider);
      Map<String, String> groupIdToName = {};

      groupsState.whenData((groups) {
        for (final group in groups) {
          groupIdToName[group.id] = group.name;
        }
      });

      var students = enrollments
          .map((enrollment) => {
                'name': enrollment.studentName ?? 'Unknown',
                'email': enrollment.studentEmail ?? 'Unknown',
                'studentId': enrollment.userId,
                'group': groupIdToName[enrollment.groupId] ?? 'Unknown Group',
                'enrollmentId': enrollment.id,
                'groupId': enrollment.groupId,
              })
          .toList();

      // Filter by group
      if (selectedGroup != 'All Groups') {
        students = students.where((s) {
          final group = s['group'];
          return group != null && group == selectedGroup;
        }).toList();
      }

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        students = students.where((s) {
          final name = s['name']?.toString().toLowerCase() ?? '';
          final email = s['email']?.toString().toLowerCase() ?? '';
          final studentId = s['studentId']?.toString().toLowerCase() ?? '';
          final query = searchQuery.toLowerCase();
          return name.contains(query) ||
              email.contains(query) ||
              studentId.contains(query);
        }).toList();
      }

      return students;
    } catch (e) {
      debugPrint('Error filtering students: $e');
      rethrow; // Let FutureBuilder handle the error
    }
  }

  // Dialog Methods - Using Tách component
  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateGroupDialog(
        onCreateGroup: (String groupName, String groupCode) async {
          try {
            // Create group using GroupController
            await ref.read(groupControllerProvider.notifier).createGroup(
                  courseId: widget.course.id,
                  groupName: groupName,
                  groupCode: groupCode,
                );

            // Set the new group as selected
            setState(() {
              selectedGroup = groupName;
            });

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Group "$groupName" created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }

            debugPrint('Created new group: $groupName with code: $groupCode');
          } catch (e) {
            // Show error message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error creating group: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showAddSingleStudentDialog() {
    // Implement add single student dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add student to $selectedGroup'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  void _showImportStudentsDialog() {
    // Implement import students functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import Students CSV functionality'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showImportGroupsDialog() {
    // Implement import groups functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import Groups CSV functionality'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Mock student data removed - now using real data from EnrollmentController
// Student data will be loaded from Firebase through EnrollmentController
// when the enrollment system integration is complete
