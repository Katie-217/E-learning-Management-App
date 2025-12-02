import 'package:flutter/material.dart';
import 'package:elearning_management_app/presentation/widgets/student/course/assignment/assignment_card.dart';
import 'package:elearning_management_app/presentation/widgets/student/course/material/material_card.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/data/repositories/assignment/assignment_repository.dart';
import 'package:elearning_management_app/data/repositories/material/material_repository.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/domain/models/material_model.dart';
import 'package:elearning_management_app/presentation/screens/student/course/tab_course/classwork/assignment_detail_page.dart';

class ClassworkTab extends StatefulWidget {
  final CourseModel course;

  const ClassworkTab({super.key, required this.course});

  @override
  State<ClassworkTab> createState() => _ClassworkTabState();
}

class _ClassworkTabState extends State<ClassworkTab>
    with AutomaticKeepAliveClientMixin {
  List<Assignment> _assignments = [];
  List<MaterialModel> _materials = [];
  bool _isLoading = true;
  bool _isLoadingMaterials = true;
  String? _error;
  String? _materialError;
  bool _hasLoaded = false;
  bool _hasLoadedMaterials = false;
  Assignment? _selectedAssignment;
  MaterialModel? _selectedMaterial;
  bool _showDetail = false;
  bool _showMaterialDetail = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
    _loadMaterials();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load assignments when tab becomes visible
    if (!_hasLoaded) {
      _loadAssignments();
    }
    if (!_hasLoadedMaterials) {
      _loadMaterials();
    }
  }

  void _showAssignmentDetail(Assignment assignment) {
    setState(() {
      _selectedAssignment = assignment;
      _showDetail = true;
    });
  }

  void _hideAssignmentDetail() {
    setState(() {
      _showDetail = false;
      _selectedAssignment = null;
    });
  }

  void _showMaterialDetailView(MaterialModel material) {
    setState(() {
      _selectedMaterial = material;
      _showMaterialDetail = true;
    });
  }

  void _hideMaterialDetail() {
    setState(() {
      _showMaterialDetail = false;
      _selectedMaterial = null;
    });
  }

  Future<void> _loadMaterials() async {
    try {
      setState(() {
        _isLoadingMaterials = true;
        _materialError = null;
      });

      if (widget.course.id.isEmpty) {
        setState(() {
          _materialError = 'Course ID is empty';
          _isLoadingMaterials = false;
        });
        return;
      }

      final materials =
          await MaterialRepository.getMaterialsByCourse(widget.course.id);

      setState(() {
        _materials = materials;
        _isLoadingMaterials = false;
        _hasLoadedMaterials = true;
      });
    } catch (e) {
      setState(() {
        _materialError = e.toString();
        _isLoadingMaterials = false;
      });
    }
  }

  Future<void> _loadAssignments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (widget.course.id.isEmpty) {
        setState(() {
          _error = 'Course ID is empty';
          _isLoading = false;
        });
        return;
      }

      final assignments =
          await AssignmentRepository.getAssignmentsByCourse(widget.course.id);

      setState(() {
        _assignments = assignments;
        _isLoading = false;
        _hasLoaded = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Show assignment detail view if selected
    if (_showDetail && _selectedAssignment != null) {
      return AssignmentDetailView(
        assignment: _selectedAssignment!,
        course: widget.course,
        onBack: _hideAssignmentDetail,
      );
    }


    // Show assignments and materials list
    return RefreshIndicator(
      onRefresh: () async {
        await _loadAssignments();
        await _loadMaterials();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Assignments & Quizzes',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white)),
          SizedBox(height: 8),

          // Loading state
          if (_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )

          // Error state
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Error loading assignments',
                      style: TextStyle(color: Colors.red),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAssignments,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            )

          // Empty state
          else if (_assignments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined,
                        color: Colors.grey, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'No assignments yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Assignments will appear here when they are created',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )

          // Assignments list
          else
            ..._assignments
                .map<Widget>((assignment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AssignmentCard(
                        assignment: assignment,
                        onTap: () => _showAssignmentDetail(assignment),
                      ),
                    ))
                .toList(),

          // QuizCard(quiz: null), // TODO: Add quiz loading
          SizedBox(height: 24),
          Text('Course Materials',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white)),
          SizedBox(height: 8),

          // Loading state for materials
          if (_isLoadingMaterials)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )

          // Error state for materials
          else if (_materialError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Error loading materials',
                      style: TextStyle(color: Colors.red),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _materialError!,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadMaterials,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            )

          // Empty state for materials
          else if (_materials.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.folder_outlined, color: Colors.grey, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'No materials yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Materials will appear here when they are added',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )

          // Materials list
          else
            ..._materials
                .map<Widget>((material) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MaterialCard(
                        material: material,
                        onTap: () => _showMaterialDetailView(material),
                      ),
                    ))
                .toList(),
        ],
      ),
    );
  }
}
