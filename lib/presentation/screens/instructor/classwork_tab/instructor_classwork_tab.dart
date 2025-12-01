import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/domain/models/material_model.dart'
    as model;
import 'package:elearning_management_app/data/repositories/assignment/assignment_repository.dart';
import 'package:elearning_management_app/data/repositories/group/group_repository.dart';
import 'package:elearning_management_app/data/repositories/material/material_repository.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/create_assignment_page.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/material/create_material_page.dart';
import 'package:elearning_management_app/presentation/screens/instructor/classwork_tab/assignment/assignment_detail_card.dart';
import 'package:elearning_management_app/presentation/screens/instructor/classwork_tab/material/material_detail_card.dart';

// StreamProvider for real-time assignment updates
final assignmentStreamProvider =
    StreamProvider.family<List<Assignment>, String>((ref, courseId) {
  return AssignmentRepository.listenToAssignments(courseId: courseId);
});

// StreamProvider for real-time material updates
final materialStreamProvider =
    StreamProvider.family<List<model.MaterialModel>, String>((ref, courseId) {
  return MaterialRepository.listenToMaterials(courseId);
});

class InstructorClassworkTab extends ConsumerStatefulWidget {
  final CourseModel course;
  const InstructorClassworkTab({super.key, required this.course});

  @override
  ConsumerState<InstructorClassworkTab> createState() =>
      _InstructorClassworkTabState();
}

class _InstructorClassworkTabState
    extends ConsumerState<InstructorClassworkTab> {
  final GlobalKey _createButtonKey = GlobalKey();
  final GlobalKey _categoryFilterButtonKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedGroupId; // null = "All Groups"
  String _selectedGroupName = 'All Groups';
  List<Map<String, String>> _availableGroups = []; // {id, name}
  String _searchQuery = '';

  String? _selectedCategory; // null = "All Types"
  String _selectedCategoryName = 'All Types';
  final List<Map<String, String>> _categories = [
    {'id': 'assignment', 'name': 'Assignments'},
    {'id': 'quiz', 'name': 'Quizzes'},
    {'id': 'material', 'name': 'Materials'},
  ];

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await GroupRepository.getGroupsByCourse(widget.course.id);

      setState(() {
        _availableGroups =
            groups.map((g) => {'id': g.id, 'name': g.name}).toList();
      });
    } catch (e) {
      print('Error loading groups: $e');
      setState(() {
        _availableGroups = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Assignment Button with Anchor Menu
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              key: _createButtonKey,
              onTap: () => _showCreateMenu(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.indigo[600],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Create',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down,
                        color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Filter Section (Group and Category)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Filter Row (Searchable)
                Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.grey[400], size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter by Group:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 120,
                          maxWidth: 280,
                        ),
                        child: DropdownMenu<String>(
                          initialSelection: _selectedGroupName,
                          leadingIcon: Icon(
                            _selectedGroupId != null
                                ? Icons.people
                                : Icons.group,
                            size: 18,
                            color: _selectedGroupId != null
                                ? Colors.indigo
                                : Colors.grey[400],
                          ),
                          textStyle: TextStyle(
                            color: _selectedGroupId != null
                                ? Colors.indigo
                                : Colors.grey[300],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          inputDecorationTheme: InputDecorationTheme(
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
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
                              borderSide: const BorderSide(
                                  color: Colors.indigo, width: 2),
                            ),
                          ),
                          menuStyle: MenuStyle(
                            backgroundColor: WidgetStateProperty.all(
                                const Color(0xFF1F2937)),
                            maximumSize: WidgetStateProperty.all(
                                const Size.fromHeight(300)),
                          ),
                          onSelected: (String? value) {
                            if (value != null) {
                              setState(() {
                                if (value == 'All Groups') {
                                  _selectedGroupId = null;
                                  _selectedGroupName = 'All Groups';
                                } else {
                                  final group = _availableGroups
                                      .firstWhere((g) => g['name'] == value);
                                  _selectedGroupId = group['id'];
                                  _selectedGroupName = value;
                                }
                              });
                            }
                          },
                          dropdownMenuEntries: [
                            DropdownMenuEntry<String>(
                              value: 'All Groups',
                              label: 'All Groups',
                              leadingIcon: Icon(Icons.group,
                                  color: Colors.grey[400], size: 18),
                              style: ButtonStyle(
                                foregroundColor:
                                    WidgetStateProperty.all(Colors.white),
                                backgroundColor: WidgetStateProperty.all(
                                    _selectedGroupName == 'All Groups'
                                        ? Colors.indigo.withOpacity(0.2)
                                        : Colors.transparent),
                              ),
                            ),
                            ..._availableGroups.map((group) {
                              final groupName = group['name'] as String;
                              return DropdownMenuEntry<String>(
                                value: groupName,
                                label: groupName,
                                leadingIcon: Icon(Icons.people,
                                    color: Colors.indigo[400], size: 18),
                                style: ButtonStyle(
                                  foregroundColor:
                                      WidgetStateProperty.all(Colors.white),
                                  backgroundColor: WidgetStateProperty.all(
                                      _selectedGroupName == groupName
                                          ? Colors.indigo.withOpacity(0.2)
                                          : Colors.transparent),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Category Filter Row (Compact)
                Row(
                  children: [
                    Icon(Icons.category_outlined,
                        color: Colors.grey[400], size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter by Type:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 120,
                          maxWidth: 250,
                        ),
                        child: InkWell(
                          key: _categoryFilterButtonKey,
                          onTap: () => _showCategoryFilterMenu(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _selectedCategory != null
                                    ? Colors.indigo
                                    : Colors.grey[700]!,
                                width: _selectedCategory != null ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _selectedCategory != null
                                      ? Icons.check_box_outlined
                                      : Icons.category,
                                  size: 18,
                                  color: _selectedCategory != null
                                      ? Colors.indigo
                                      : Colors.grey[400],
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _selectedCategoryName,
                                    style: TextStyle(
                                      color: _selectedCategory != null
                                          ? Colors.indigo
                                          : Colors.grey[300],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_drop_down,
                                    size: 20, color: Colors.grey[400]),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Class Materials',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.sort, size: 18),
                label: const Text('Sort'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo[400],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Search Box for Assignments
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search assignments by title...',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon:
                          Icon(Icons.clear, color: Colors.grey[400], size: 20),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.indigo, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),

          const SizedBox(height: 20),

          // Merged Assignments and Materials List (Sorted by createdAt)
          Consumer(
            builder: (context, ref, child) {
              final assignmentsAsync =
                  ref.watch(assignmentStreamProvider(widget.course.id));
              final materialsAsync =
                  ref.watch(materialStreamProvider(widget.course.id));

              // Wait for both streams to load
              if (assignmentsAsync.isLoading || materialsAsync.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                  ),
                );
              }

              // Handle errors
              if (assignmentsAsync.hasError || materialsAsync.hasError) {
                final error = assignmentsAsync.hasError
                    ? assignmentsAsync.error
                    : materialsAsync.error;
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading classwork',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // Get data from both streams
              final assignments = assignmentsAsync.value ?? [];
              final materials = materialsAsync.value ?? [];

              // Apply group filter to assignments
              var filteredAssignments = _selectedGroupId == null
                  ? assignments
                  : assignments
                      .where((assignment) =>
                          assignment.groupIds.contains(_selectedGroupId))
                      .toList();

              // Apply search filter to assignments
              if (_searchQuery.isNotEmpty) {
                filteredAssignments = filteredAssignments
                    .where((assignment) =>
                        assignment.title.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              // Apply search filter to materials
              var filteredMaterials = materials;
              if (_searchQuery.isNotEmpty) {
                filteredMaterials = materials
                    .where((material) =>
                        material.title.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              // Apply category filter
              if (_selectedCategory != null) {
                if (_selectedCategory == 'assignment') {
                  filteredMaterials = []; // Hide materials
                } else if (_selectedCategory == 'material') {
                  filteredAssignments = []; // Hide assignments
                }
                // For 'quiz', hide both for now (not implemented yet)
                else if (_selectedCategory == 'quiz') {
                  filteredAssignments = [];
                  filteredMaterials = [];
                }
              }

              // Create merged list with type information
              List<Map<String, dynamic>> mergedItems = [];

              // Add assignments with type marker
              for (var assignment in filteredAssignments) {
                mergedItems.add({
                  'type': 'assignment',
                  'data': assignment,
                  'createdAt': assignment.createdAt,
                });
              }

              // Add materials with type marker
              for (var material in filteredMaterials) {
                mergedItems.add({
                  'type': 'material',
                  'data': material,
                  'createdAt': material.createdAt,
                });
              }

              // Sort merged list by createdAt (newest first)
              mergedItems.sort((a, b) {
                final aTime = a['createdAt'] as DateTime;
                final bTime = b['createdAt'] as DateTime;
                return bTime.compareTo(aTime); // Descending order
              });

              // Check if empty
              if (mergedItems.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined,
                          size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No results found for "$_searchQuery"'
                            : _selectedCategory != null
                                ? 'No ${_selectedCategoryName.toLowerCase()} yet'
                                : _selectedGroupId == null
                                    ? 'No classwork yet'
                                    : 'No classwork for $_selectedGroupName',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Try a different search term'
                            : 'Create your first assignment or material using the button above',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              // Render merged list
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: mergedItems.map((item) {
                  final type = item['type'] as String;

                  if (type == 'assignment') {
                    final assignment = item['data'] as Assignment;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AssignmentDetailCard(
                        assignment: assignment,
                        courseId: widget.course.id,
                        type: 'Assignment',
                        icon: Icons.assignment_outlined,
                        color: Colors.blue,
                        onReviewWork: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Review page coming soon'),
                            ),
                          );
                        },
                      ),
                    );
                  } else if (type == 'material') {
                    final material = item['data'] as model.MaterialModel;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MaterialDetailCard(
                        material: material,
                        courseId: widget.course.id,
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 16), // Bottom padding
        ],
      ),
    );
  }

  void _showCreateMenu(BuildContext context) {
    final RenderBox renderBox =
        _createButtonKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height + 8,
        position.dx + size.width,
        position.dy + size.height + 8,
      ),
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      items: [
        PopupMenuItem(
          value: 'assignment',
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue[600]?.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assignment_outlined,
                    color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Assignment',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Create a new assignment',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'quiz',
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green[600]?.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.quiz_outlined,
                    color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Quiz',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Create a quiz or test',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'material',
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange[600]?.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book_outlined,
                    color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Material',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Upload course materials',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleMenuSelection(context, value);
      }
    });
  }

  void _showCategoryFilterMenu(BuildContext context) {
    final RenderBox renderBox = _categoryFilterButtonKey.currentContext!
        .findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height + 8,
        position.dx + size.width,
        position.dy + size.height + 8,
      ),
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      items: <PopupMenuEntry<String?>>[
        // "All Types" option
        PopupMenuItem<String?>(
          value: null,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _selectedCategory == null
                      ? Colors.indigo.withOpacity(0.2)
                      : Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.category,
                  color:
                      _selectedCategory == null ? Colors.indigo : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'All Types',
                  style: TextStyle(
                    color: _selectedCategory == null
                        ? Colors.indigo
                        : Colors.white,
                    fontWeight: _selectedCategory == null
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              if (_selectedCategory == null)
                const Icon(Icons.check, color: Colors.indigo, size: 20),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        // Category options
        ..._categories.map((category) {
          final categoryId = category['id']!;
          final categoryName = category['name']!;
          final isSelected = _selectedCategory == categoryId;

          IconData icon;
          Color color;
          switch (categoryId) {
            case 'assignment':
              icon = Icons.assignment_outlined;
              color = Colors.blue;
              break;
            case 'quiz':
              icon = Icons.quiz_outlined;
              color = Colors.green;
              break;
            case 'material':
              icon = Icons.menu_book_outlined;
              color = Colors.orange;
              break;
            default:
              icon = Icons.description;
              color = Colors.grey;
          }

          return PopupMenuItem<String?>(
            value: categoryId,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.indigo.withOpacity(0.2)
                        : color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.indigo : color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      color: isSelected ? Colors.indigo : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: Colors.indigo, size: 20),
              ],
            ),
          );
        }),
      ],
    ).then((selectedValue) {
      if (selectedValue != null || selectedValue == null) {
        setState(() {
          _selectedCategory = selectedValue;
          if (selectedValue == null) {
            _selectedCategoryName = 'All Types';
          } else {
            _selectedCategoryName = _categories
                .firstWhere((c) => c['id'] == selectedValue)['name']!;
          }
        });
      }
    });
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'assignment':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateAssignmentPage(course: widget.course),
          ),
        );
        break;
      case 'quiz':
        // TODO: Navigate to Create Quiz page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz creation coming soon!')),
        );
        break;
      case 'material':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateMaterialPage(course: widget.course),
          ),
        );
        break;
    }
  }
}
