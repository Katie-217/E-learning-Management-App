import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../application/controllers/student/student_controller.dart';
import '../../../domain/models/student_model.dart';
import '../../../data/repositories/auth/auth_repository.dart';

class InstructorStudentsPage extends StatefulWidget {
  // 🆕 Callbacks
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
  List<StudentModel> students = [];
  List<StudentModel> filteredStudents = [];
  bool isLoading = false;
  String searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _studentController = StudentController(
      authRepository: AuthRepository.defaultClient(),
    );
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => isLoading = true);

    try {
      final loadedStudents = await _studentController.getAllStudents();
      setState(() {
        students = loadedStudents;
        _applyFilter();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Loaded ${students.length} students successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _applyFilter() {
    if (searchQuery.isEmpty) {
      filteredStudents = students;
    } else {
      filteredStudents = students
          .where((s) =>
              s.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (s.studentCode?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
              s.email.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
  }

  void _showStudentDetail(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: Text(student.name, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('📧 Email:', student.email),
              _buildDetailRow('🆔 Student Code:', student.studentCode ?? 'N/A'),
              _buildDetailRow('📱 Phone:', student.phone ?? 'N/A'),
              _buildDetailRow(
                '📚 Courses:',
                '${student.courseIds.length} courses',
              ),
              _buildDetailRow(
                '👥 Groups:',
                '${student.groupIds.length} groups',
              ),
              _buildDetailRow(
                '✅ Status:',
                student.isActive ? 'Active' : 'Inactive',
                valueColor: student.isActive ? Colors.green : Colors.red,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditStudentDialog(student);
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _deleteStudent(student.uid);
            },
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(StudentModel student) {
    final nameController = TextEditingController(text: student.name);
    final phoneController = TextEditingController(text: student.phone ?? '');


    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('✏️ Edit Student Information',
            style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '👤 Student Name',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '📱 Phone Number',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 12),

            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('❌ Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => _updateStudent(student, nameController,
                phoneController),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('✅ Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStudent(
    StudentModel student,
    TextEditingController nameController,
    TextEditingController phoneController,
  ) async {
    try {
      final success = await _studentController.updateStudentProfile(
        student.uid,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),

      );

      if (success) {
        Navigator.pop(context);
        _loadStudents();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteStudent(String studentUid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('⚠️ Confirm Deletion',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this student?\n\n'
          '(The student will be marked as inactive)',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await _studentController.deleteStudent(studentUid);

      if (success) {
        _loadStudents();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: const Color(0xFF1F2937),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo[600],
          child: Text(
            student.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🆔 ${student.studentCode ?? 'N/A'}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            Text(
              '📧 ${student.email}',
              style: TextStyle(color: Colors.grey[400]),
            )
          ],
        ),
        trailing: PopupMenuButton(
          color: const Color(0xFF1F2937),
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: () => Future.delayed(
                Duration.zero,
                () => _showStudentDetail(student),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text('View Details', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => Future.delayed(
                Duration.zero,
                () => _showEditStudentDialog(student),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Edit', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => Future.delayed(
                Duration.zero,
                () => _deleteStudent(student.uid),
              ),
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showStudentDetail(student),
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

    if (students.isEmpty && !isLoading) {
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
              'Error loading students',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'An error occurred',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadStudents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No students found',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t added any students yet',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        return _buildStudentCard(filteredStudents[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Students',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: widget.onCreateStudentPressed,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Student'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: widget.onImportCSVPressed,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Import CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Manage and monitor your students',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
        const SizedBox(height: 24),

        // Search Bar
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
            hintText: 'Search by name, code or email...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
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

        // Results Summary
        Text(
          'Results: ${filteredStudents.length} students',
          style: TextStyle(
            color: Colors.indigo[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // Handle loading, error, and students display
        Expanded(
          child: _buildStudentsContent(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}