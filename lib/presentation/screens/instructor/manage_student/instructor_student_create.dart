import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../application/controllers/student/student_controller.dart';
import '../../../../application/controllers/course/course_instructor_provider.dart';
import '../../../../application/controllers/group/group_controller.dart';
import '../../../../application/controllers/course/enrollment_controller.dart';
import '../../../../data/repositories/auth/auth_repository.dart';
import '../../../../domain/models/course_model.dart';
import '../../../../domain/models/group_model.dart';

class CreateStudentPage extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const CreateStudentPage({
    super.key,
    this.onSuccess,
    this.onCancel,
  });

  @override
  ConsumerState<CreateStudentPage> createState() => _CreateStudentPageState();
}

class _CreateStudentPageState extends ConsumerState<CreateStudentPage> {
  late StudentController _studentController;
  late EnrollmentController _enrollmentController;
  FirebaseAuth? _secondaryAuth;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _obscurePassword = true;

  // Cascading dropdown state
  CourseModel? _selectedCourse;
  GroupModel? _selectedGroup;
  List<CourseModel> _courses = [];
  List<GroupModel> _groups = [];
  bool _isLoadingGroups = false;

  @override
  void initState() {
    super.initState();
    _studentController = StudentController(
      authRepository: AuthRepository.defaultClient(),
    );
    _enrollmentController = EnrollmentController();
    _initSecondaryAuth();
    _loadCourses();
  }

  Future<void> _initSecondaryAuth() async {
    try {
      // Create secondary Firebase App for student creation without affecting current admin session
      final secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );
      _secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    } catch (e) {
      print('🔥 Failed to initialize secondary auth: $e');
      // Fallback to regular auth (will cause logout issue but still functional)
      _secondaryAuth = FirebaseAuth.instance;
    }
  }

  // ========================================
  // DATA LOADING METHODS
  // ========================================

  Future<void> _loadCourses() async {
    try {
      final courseController = ref.read(courseInstructorControllerProvider);
      final courses = await courseController.getInstructorCourses();
      setState(() {
        _courses =
            courses.where((course) => course.status == 'active').toList();
      });
    } catch (e) {
      _showError('Error loading courses: $e');
    }
  }

  Future<void> _loadGroupsForCourse(String courseId) async {
    setState(() {
      _isLoadingGroups = true;
      _selectedGroup = null; // Reset group selection
      _groups = [];
    });

    try {
      await ref
          .read(groupControllerProvider.notifier)
          .getGroupsByCourse(courseId);
      final groupsAsyncValue = ref.read(groupControllerProvider);

      groupsAsyncValue.when(
        data: (groups) {
          setState(() {
            _groups = groups;
            _isLoadingGroups = false;
          });
        },
        loading: () {
          setState(() {
            _isLoadingGroups = true;
          });
        },
        error: (error, stack) {
          setState(() {
            _isLoadingGroups = false;
          });
          _showError('Error loading groups: $error');
        },
      );
    } catch (e) {
      setState(() {
        _isLoadingGroups = false;
      });
      _showError('Error loading groups: $e');
    }
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) return false;

    if (!_emailController.text.trim().contains('@')) {
      _showError('Invalid email');
      return false;
    }

    // Validate cascading selections
    if (_selectedCourse == null) {
      _showError('Please select a course');
      return false;
    }

    if (_selectedGroup == null) {
      _showError('Please select a group');
      return false;
    }

    return true;
  }

  Future<void> _createStudent() async {
    if (!_validateForm()) return;

    setState(() => isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Check if student is already enrolled in this course
      final existingEnrollments =
          await _enrollmentController.getEnrolledStudents(_selectedCourse!.id);
      final isAlreadyEnrolledInCourse = existingEnrollments.any((enrollment) =>
          enrollment.studentEmail?.toLowerCase() == email.toLowerCase());

      if (isAlreadyEnrolledInCourse) {
        _showError(
            'Student with email $email is already enrolled in course ${_selectedCourse!.name}');
        setState(() => isLoading = false);
        return;
      }

      // Use secondary auth to avoid logging out current admin user
      if (_secondaryAuth == null) {
        await _initSecondaryAuth();
      }

      String uid;
      bool isNewAccount = false;

      try {
        // Try to create new Firebase Auth account
        UserCredential userCredential =
            await _secondaryAuth!.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        uid = userCredential.user!.uid;
        isNewAccount = true;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Account exists, get the existing user UID
          final existingUser = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (existingUser.docs.isEmpty) {
            throw Exception('Email exists in Auth but no user profile found');
          }

          uid = existingUser.docs.first.id;
          isNewAccount = false;
        } else {
          rethrow;
        }
      }

      // Step 1: Create student profile (only if new account)
      if (isNewAccount) {
        await _studentController.createStudent(
          uid: uid,
          email: email,
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );
      }

      // Step 2: Enroll student in selected group (Strict Enrollment)
      await _enrollmentController.enrollStudentInGroup(
        courseId: _selectedCourse!.id,
        userId: uid,
        studentName: _nameController.text.trim(),
        studentEmail: email,
        groupId: _selectedGroup!.id,
        groupMaxMembers: _selectedGroup!.maxMembers,
      );

      if (mounted) {
        final message = isNewAccount
            ? 'Student account created and enrolled in ${_selectedGroup!.name} successfully!'
            : 'Existing student enrolled in ${_selectedGroup!.name} successfully!';
        _showSuccess(message);
        await Future.delayed(const Duration(seconds: 1));
        widget.onSuccess?.call();
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Auth Error';
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'This email is already in use';
          break;
        case 'invalid-email':
          msg = 'Invalid email';
          break;
        case 'weak-password':
          msg = 'Password is too weak';
          break;
        default:
          msg = e.message ?? 'Unknown error';
      }
      _showError(msg);
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Success!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onSuccess?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========================================
  // DROPDOWN WIDGET BUILDERS
  // ========================================

  Widget _buildCourseDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Course *',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownMenu<CourseModel>(
            width: double.infinity,
            hintText: 'Choose a course...',
            enableFilter: true,
            enableSearch: true,
            requestFocusOnTap: true,
            menuStyle: MenuStyle(
              backgroundColor: WidgetStateProperty.all(const Color(0xFF1F2937)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1F2937),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
            textStyle: const TextStyle(color: Colors.white),
            onSelected: (CourseModel? course) {
              setState(() {
                _selectedCourse = course;
              });
              if (course != null) {
                _loadGroupsForCourse(course.id);
              }
            },
            dropdownMenuEntries: _courses
                .map<DropdownMenuEntry<CourseModel>>((CourseModel course) {
              return DropdownMenuEntry<CourseModel>(
                value: course,
                label: '${course.code} - ${course.name}',
                style: MenuItemButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Group *',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownMenu<GroupModel>(
            width: double.infinity,
            hintText: _selectedCourse == null
                ? 'Select a course first...'
                : _isLoadingGroups
                    ? 'Loading groups...'
                    : _groups.isEmpty
                        ? 'No groups available'
                        : 'Choose a group...',
            enableFilter: true,
            enableSearch: true,
            requestFocusOnTap: _selectedCourse != null &&
                !_isLoadingGroups &&
                _groups.isNotEmpty,
            menuStyle: MenuStyle(
              backgroundColor: WidgetStateProperty.all(const Color(0xFF1F2937)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1F2937),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _selectedCourse == null
                      ? Colors.grey[800]!
                      : Colors.grey[700]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
            textStyle: TextStyle(
              color: _selectedCourse == null ? Colors.grey[600] : Colors.white,
            ),
            onSelected: (GroupModel? group) {
              setState(() {
                _selectedGroup = group;
              });
            },
            dropdownMenuEntries:
                _groups.map<DropdownMenuEntry<GroupModel>>((GroupModel group) {
              return DropdownMenuEntry<GroupModel>(
                value: group,
                label: '${group.name} (${group.code})',
                style: MenuItemButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
              );
            }).toList(),
          ),
          if (_isLoadingGroups)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Loading groups...',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xFF1F2937),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title:
            const Text('Create Student', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111827),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.indigo),
                    SizedBox(height: 16),
                    Text('Creating student...',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Note box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[900]?.withValues(alpha: 0.3),
                          border: Border.all(color: Colors.blue[700]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Note:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.blue)),
                            SizedBox(height: 8),
                            Text(
                              '• Email must be unique\n'
                              '• Password at least 6 characters\n'
                              '• Phone number is optional',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Account Information
                      const Text('Account Information',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'student@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'At least 6 characters',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) => (v != null && v.length < 6)
                            ? 'Password must be at least 6 characters'
                            : null,
                      ),

                      const SizedBox(height: 24),

                      // Personal Information
                      const Text('Personal Information',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'E.g.: Nguyen Van A',
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number (optional)',
                        hint: '0123456789',
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 24),

                      // Course & Group Selection Section
                      const Text('Course & Group Selection',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue[900]?.withValues(alpha: 0.3),
                          border: Border.all(color: Colors.blue[700]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ℹ️ Students must be enrolled in both a course and group (Strict Enrollment Rule)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),

                      _buildCourseDropdown(),
                      _buildGroupDropdown(),

                      const SizedBox(height: (32)),

                      // Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _createStudent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.add),
                          label: Text(
                              isLoading ? 'Creating...' : 'Create Student',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Cancel',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    // Clean up secondary auth
    _secondaryAuth?.signOut();
    super.dispose();
  }
}
