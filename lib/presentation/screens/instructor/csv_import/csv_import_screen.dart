import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/repositories/csv/csv_import_repository.dart';
import '../../../../application/controllers/csv/bulk_import_controller.dart';
import '../../../../application/controllers/course/course_instructor_provider.dart';
import '../../../../application/controllers/group/group_controller.dart';
import '../../../../application/controllers/course/enrollment_controller.dart';
import '../../../../data/repositories/student/student_repository.dart';
import '../../../../domain/models/course_model.dart';
import '../../../../domain/models/group_model.dart';

typedef ImportCompleteCallback = void Function(bool success, String message);

// Extended ImportResult with enrollment information
class ImportResultWithEnrollment extends ImportResult {
  final int enrolledCount;
  final List<String> enrollmentErrors;

  ImportResultWithEnrollment({
    required super.dataType,
    required super.totalRecords,
    required this.enrolledCount,
    required this.enrollmentErrors,
  });
}

class CsvImportScreen extends ConsumerStatefulWidget {
  final String dataType;
  final ImportCompleteCallback? onImportComplete;
  final VoidCallback? onCancel;

  const CsvImportScreen({
    super.key,
    required this.dataType,
    this.onImportComplete,
    this.onCancel,
  });

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  int _currentStep = 1;
  String? _selectedFileName;
  String? _fileContent;
  Map<String, dynamic>? _structureValidation;
  List<StudentImportRecord>? _parsedRecords;
  List<String> _existingEmails = [];
  bool _isLoading = false;
  bool _isValidating = false;
  ImportResult? _importResult;
  int _newCount = 0;
  int _duplicateCount = 0;
  int _invalidCount = 0;

  // Cascading dropdown state
  CourseModel? _selectedCourse;
  GroupModel? _selectedGroup;
  List<CourseModel> _courses = [];
  List<GroupModel> _groups = [];
  bool _isLoadingGroups = false;

  @override
  void initState() {
    super.initState();
    _loadExistingEmails();
    _loadCourses();
  }

  Future<void> _loadExistingEmails() async {
    try {
      final students = await StudentRepository.getAllStudents();
      setState(() {
        _existingEmails = students.map((s) => s.email.toLowerCase()).toList();
      });
    } catch (e) {
      // Silent fail – no debug print
    }
  }

  // ========================================
  // CASCADING DROPDOWN METHODS
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
      _selectedGroup = null;
      _groups = [];
    });

    try {
      // Load groups using provider
      await ref
          .read(groupControllerProvider.notifier)
          .getGroupsByCourse(courseId);

      // Get loaded groups from provider state
      final groupsState = ref.read(groupControllerProvider);
      groupsState.whenData((groups) {
        setState(() {
          _groups = groups;
          _isLoadingGroups = false;
        });
      });
    } catch (e) {
      setState(() => _isLoadingGroups = false);
      _showError('Error loading groups: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        String content;
        if (file.bytes != null) {
          // Web/mobile: use bytes
          content = String.fromCharCodes(file.bytes!);
        } else if (file.path != null) {
          // Desktop: read from path
          final fileContent = await File(file.path!).readAsString();
          content = fileContent;
        } else {
          throw Exception('Unable to read file content');
        }

        setState(() {
          _selectedFileName = file.name;
          _fileContent = content;
          _structureValidation = null;
          _parsedRecords = null;
        });
      }
    } catch (e) {
      _showError('File selection error: $e');
    }
  }

  Future<void> _validateAndParse() async {
    if (_fileContent == null) return;

    setState(() => _isValidating = true);

    try {
      // Only email & name are required now
      final validation = CsvImportService.validateCsvStructure(
        _fileContent!,
        ['email', 'name'],
      );

      if (validation['isValid'] != true) {
        _showError('CSV structure error: ${validation['error']}');
        setState(() => _isValidating = false);
        return;
      }

      // Get existing emails in this specific course
      print(
          '🔄 DEBUG: Getting existing enrollments for course: ${_selectedCourse!.id}');
      final enrollmentController = EnrollmentController();
      final existingEnrollments =
          await enrollmentController.getEnrolledStudents(_selectedCourse!.id);
      final existingEmailsInThisCourse = existingEnrollments
          .map((e) => e.studentEmail?.toLowerCase())
          .where((email) => email != null)
          .cast<String>()
          .toList();

      print(
          '🔄 DEBUG: Found ${existingEmailsInThisCourse.length} existing emails in this course:');
      for (final email in existingEmailsInThisCourse) {
        print('   - $email');
      }

      print('🔄 DEBUG: Parsing CSV with course-specific duplicates check...');
      final records = await CsvImportService.parseAndValidateStudentsCsv(
        _fileContent!,
        existingEmailsInThisCourse, // Use course-specific emails instead of system-wide
      );

      print('🔄 DEBUG: CSV parsing results:');
      for (final record in records) {
        print(
            '   Row ${record.rowIndex}: ${record.data['email']} - Status: ${record.status}');
      }

      _newCount = records.where((r) => r.status == 'new').length;
      _duplicateCount = records.where((r) => r.status == 'duplicate').length;
      _invalidCount = records.where((r) => r.status == 'invalid').length;

      setState(() {
        _structureValidation = validation;
        _parsedRecords = records;
        _currentStep = 2;
      });

      // Load existing user names for duplicate emails
      await _loadExistingUserNames();
    } catch (e) {
      _showError('CSV parsing error: $e');
    } finally {
      setState(() => _isValidating = false);
    }
  }

  Future<void> _importData() async {
    if (_parsedRecords == null || _parsedRecords!.isEmpty) {
      _showError('No data to import');
      return;
    }

    if (_selectedCourse == null || _selectedGroup == null) {
      _showError('Please select course and group first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔄 DEBUG: Starting import process...');
      final enrollmentController = EnrollmentController();
      final controller = BulkImportController();

      final recordsToImport = _parsedRecords!
          .where((r) => r.status == 'new')
          .map((r) => r.data)
          .toList();

      print('🔄 DEBUG: Records to import: ${recordsToImport.length}');
      print(
          '🔄 DEBUG: Selected course: ${_selectedCourse?.name} (${_selectedCourse?.id})');
      print(
          '🔄 DEBUG: Selected group: ${_selectedGroup?.name} (${_selectedGroup?.id})');

      if (recordsToImport.isEmpty) {
        _showError('No new students to add');
        setState(() => _isLoading = false);
        return;
      }

      // Step 1: Check existing enrollments in this course to prevent duplicate enrollments
      print(
          '🔄 DEBUG: Checking existing enrollments in course: ${_selectedCourse!.name}...');
      final existingEnrollments =
          await enrollmentController.getEnrolledStudents(_selectedCourse!.id);
      print(
          '🔄 DEBUG: Found ${existingEnrollments.length} existing enrollments in this course');
      final existingEmailsInCourse = existingEnrollments
          .map((e) => e.studentEmail?.toLowerCase())
          .where((email) => email != null)
          .cast<String>()
          .toSet();
      print(
          '🔄 DEBUG: Existing emails in THIS course: $existingEmailsInCourse');

      // Filter out students already enrolled in THIS SPECIFIC COURSE (not system-wide)
      final filteredRecords = recordsToImport.where((record) {
        final email = record['email']?.toString().toLowerCase();
        final isAlreadyInThisCourse =
            email != null && existingEmailsInCourse.contains(email);

        if (isAlreadyInThisCourse) {
          print(
              '🔄 DEBUG: Skipping $email - already enrolled in course ${_selectedCourse!.name}');
        } else {
          print(
              '🔄 DEBUG: Including $email - not enrolled in course ${_selectedCourse!.name} yet');
        }

        return email != null && !isAlreadyInThisCourse;
      }).toList();

      if (filteredRecords.isEmpty) {
        _showError('All students are already enrolled in this course');
        setState(() => _isLoading = false);
        return;
      }

      // Step 2: Import students using BulkImportController (creates user accounts)
      print(
          '🔄 DEBUG: Creating user accounts for ${filteredRecords.length} students...');
      final result = await controller.importStudents(filteredRecords);
      print(
          '🔄 DEBUG: User accounts created - Success: ${result.successCount}, Failed: ${result.failureCount}');
      if (result.failedRecords.isNotEmpty) {
        print('❌ DEBUG: Failed records:');
        for (final failed in result.failedRecords) {
          print('   - ${failed['email']}: ${failed['error']}');
        }
      }

      // Step 3: Enroll all successfully imported students into the selected group
      print('🔄 DEBUG: Starting enrollment process...');
      int enrolledCount = 0;
      final enrollmentErrors = <String>[];

      for (final successRecord in result.successRecords) {
        try {
          final email = successRecord['email']?.toString();
          final name = successRecord['name']?.toString();
          final userId = successRecord['uid']?.toString();

          print('🔄 DEBUG: Enrolling student: $email (UID: $userId)');

          if (email != null && name != null && userId != null) {
            await enrollmentController.enrollStudentInGroup(
              courseId: _selectedCourse!.id,
              userId: userId,
              studentName: name,
              studentEmail: email,
              groupId: _selectedGroup!.id,
              groupMaxMembers: _selectedGroup!.maxMembers,
            );
            enrolledCount++;
            print('✅ DEBUG: Successfully enrolled: $email');
          } else {
            print(
                '❌ DEBUG: Missing data for student: email=$email, name=$name, uid=$userId');
          }
        } catch (e) {
          print('❌ DEBUG: Enrollment failed for ${successRecord['email']}: $e');
          enrollmentErrors.add('${successRecord['email']}: $e');
        }
      }

      print(
          '🔄 DEBUG: Enrollment complete - Enrolled: $enrolledCount, Errors: ${enrollmentErrors.length}');

      await _loadExistingEmails();

      // Create custom result with enrollment info
      final customResult = ImportResultWithEnrollment(
        dataType: result.dataType,
        totalRecords: result.totalRecords,
        enrolledCount: enrolledCount,
        enrollmentErrors: enrollmentErrors,
      );
      customResult.successRecords.addAll(result.successRecords);
      customResult.failedRecords.addAll(result.failedRecords);

      setState(() {
        _importResult = customResult;
        _currentStep = 4;
      });
    } catch (e) {
      _showError('Import error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Cache for existing user names to avoid multiple queries
  final Map<String, String> _existingUserNames = {};

  // Helper method to get existing user name for duplicate email
  String _getExistingUserName(String email) {
    return _existingUserNames[email.toLowerCase()] ?? 'Loading...';
  }

  // Load existing user names for duplicate emails
  Future<void> _loadExistingUserNames() async {
    if (_parsedRecords == null) return;

    final duplicateEmails = _parsedRecords!
        .where((r) => r.status == 'duplicate')
        .map((r) => r.data['email']?.toString().toLowerCase())
        .where((email) => email != null)
        .cast<String>()
        .toSet();

    for (final email in duplicateEmails) {
      try {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userData = userQuery.docs.first.data();
          _existingUserNames[email] =
              userData['name'] ?? userData['displayName'] ?? 'Unknown User';
        }
      } catch (e) {
        _existingUserNames[email] = 'Unknown User';
      }
    }

    if (mounted) setState(() {}); // Refresh UI with loaded names
  }

  // Helper method to get count of new students
  int _getNewStudentsCount() {
    if (_parsedRecords == null) return 0;
    return _parsedRecords!.where((r) => r.status == 'new').length;
  }

  // ========================================
  // CASCADING DROPDOWN UI COMPONENTS
  // ========================================

  Widget _buildCourseGroupSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Target Course & Group',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              // Course Dropdown
              SizedBox(
                width: 300, // Fixed width
                child: _buildCourseDropdown(),
              ),

              // Group Dropdown
              SizedBox(
                width: 300, // Fixed width
                child: _buildGroupDropdown(),
              ),
            ],
          ),
          if (_selectedCourse != null && _selectedGroup != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[900]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[700]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green[400], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Students will be imported to: ${_selectedCourse!.name} → ${_selectedGroup!.name}',
                        style: TextStyle(
                          color: Colors.green[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseDropdown() {
    return DropdownMenu<CourseModel>(
      enableFilter: true,
      menuHeight: 150, // Limit height to show ~3 items
      enableSearch: true,
      requestFocusOnTap: true,
      label: const Text('Select Course'),
      hintText: 'Choose course to import students to',
      leadingIcon: const Icon(Icons.school),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800],
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
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      onSelected: (CourseModel? course) {
        setState(() {
          _selectedCourse = course;
          _selectedGroup = null; // Reset group when course changes
        });
        if (course != null) {
          _loadGroupsForCourse(course.id);
        }
      },
      dropdownMenuEntries:
          _courses.map<DropdownMenuEntry<CourseModel>>((CourseModel course) {
        return DropdownMenuEntry<CourseModel>(
          value: course,
          label: course.name,
          leadingIcon: Icon(Icons.book, color: Colors.blue[400], size: 16),
        );
      }).toList(),
    );
  }

  Widget _buildGroupDropdown() {
    final bool isEnabled = _selectedCourse != null && !_isLoadingGroups;

    return DropdownMenu<GroupModel>(
      enableFilter: true,
      menuHeight: 150, // Limit height to show ~3 items
      enableSearch: true,
      requestFocusOnTap: isEnabled,
      label: const Text('Select Group'),
      hintText: isEnabled ? 'Choose target group' : 'Select course first',
      leadingIcon: _isLoadingGroups
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.group),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isEnabled ? Colors.grey[800] : Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: isEnabled ? Colors.grey[600]! : Colors.grey[700]!),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        labelStyle:
            TextStyle(color: isEnabled ? Colors.white70 : Colors.white38),
        hintStyle:
            TextStyle(color: isEnabled ? Colors.white54 : Colors.white38),
      ),
      onSelected: isEnabled
          ? (GroupModel? group) {
              setState(() {
                _selectedGroup = group;
              });
            }
          : null,
      dropdownMenuEntries: isEnabled
          ? _groups.map<DropdownMenuEntry<GroupModel>>((GroupModel group) {
              return DropdownMenuEntry<GroupModel>(
                value: group,
                label: group.name,
                leadingIcon:
                    Icon(Icons.people, color: Colors.green[400], size: 16),
              );
            }).toList()
          : [],
    );
  }

  Widget _buildStep1Upload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(1, 'Select Course, Group & Upload CSV File'),
        const SizedBox(height: 16),

        // Course and Group Selection
        _buildCourseGroupSelection(),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[900]?.withValues(alpha: 0.2),
            border: Border.all(color: Colors.blue[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CSV format guide:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Required columns:\n'
                ' • email (example: sv001@example.com)\n'
                ' • name (example: Nguyen Van A)\n\n'
                'Optional columns:\n'
                ' • phone (10 digits)\n\n'
                'Column order: Not required\n'
                'First row: Must be headers\n'
                'Format: CSV with comma (,) as separator',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        if (_selectedFileName == null)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (_selectedCourse != null && _selectedGroup != null)
                  ? _pickFile
                  : null,
              icon: const Icon(Icons.upload_file),
              label: Text((_selectedCourse == null || _selectedGroup == null)
                  ? 'Please select course and group first'
                  : 'Select CSV File'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    (_selectedCourse != null && _selectedGroup != null)
                        ? Colors.blue
                        : Colors.grey[700],
                foregroundColor: Colors.white,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[900]?.withValues(alpha: 0.3),
              border: Border.all(color: Colors.green[700]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFileName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'File selected',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedFileName = null;
                      _fileContent = null;
                      _structureValidation = null;
                      _parsedRecords = null;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  // The rest of the UI widgets remain exactly the same as in your final version
  // (Preview, Confirm, Summary, buttons, etc.) – only the required changes above were applied

  Widget _buildStep2Preview() {
    if (_parsedRecords == null || _parsedRecords!.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final newRecords = _parsedRecords!.where((r) => r.status == 'new').toList();
    final duplicateRecords =
        _parsedRecords!.where((r) => r.status == 'duplicate').toList();
    final invalidRecords =
        _parsedRecords!.where((r) => r.status == 'invalid').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(2, 'Preview and Validate'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatBox(
                title: 'New to add',
                count: newRecords.length,
                color: Colors.green,
                icon: Icons.add_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                title: 'Already exists',
                count: duplicateRecords.length,
                color: Colors.orange,
                icon: Icons.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                title: 'Data errors',
                count: invalidRecords.length,
                color: Colors.red,
                icon: Icons.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Show duplicate records section
        if (duplicateRecords.isNotEmpty) ...[
          const Text(
            'Already enrolled in this course (will skip):',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: Colors.orange[900]?.withValues(alpha: 0.2),
              border: Border.all(color: Colors.orange[700]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: duplicateRecords.length,
              itemBuilder: (context, index) {
                final record = duplicateRecords[index];
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Row ${record.rowIndex}: ${record.data['email'] ?? 'N/A'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Already enrolled in this course with name: ${_getExistingUserName(record.data['email']?.toString() ?? '')}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.orange[300]),
                      ),
                      Text(
                        'CSV name: ${record.data['name'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                      if (index < duplicateRecords.length - 1)
                        const Divider(color: Colors.orange, height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (invalidRecords.isNotEmpty) ...[
          const Text(
            'Invalid data (cannot import):',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: Colors.red[900]?.withValues(alpha: 0.2),
              border: Border.all(color: Colors.red[700]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: invalidRecords.length,
              itemBuilder: (context, index) {
                final record = invalidRecords[index];
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Row ${record.rowIndex}: ${record.data['email'] ?? 'N/A'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      ...record.errorMessages.map((err) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('• $err',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.red[300])),
                          )),
                      if (index < invalidRecords.length - 1)
                        const Divider(color: Colors.red, height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        // Show new records section
        if (newRecords.isNotEmpty) ...[
          const Text(
            'New students to be added:',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: Colors.green[900]?.withValues(alpha: 0.2),
              border: Border.all(color: Colors.green[700]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: newRecords.length,
              itemBuilder: (context, index) {
                final record = newRecords[index];
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Row ${record.rowIndex}: ${record.data['email'] ?? 'N/A'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Name: ${record.data['name'] ?? 'N/A'}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.green[300]),
                      ),
                      Text(
                        'Will be enrolled in: ${_selectedGroup?.name ?? 'Selected Group'}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                      if (index < newRecords.length - 1)
                        const Divider(color: Colors.green, height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildStep3Confirm() {
    final newRecords = _parsedRecords!.where((r) => r.status == 'new').toList();
    final duplicateCount =
        _parsedRecords!.where((r) => r.status == 'duplicate').length;
    final invalidCount =
        _parsedRecords!.where((r) => r.status == 'invalid').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(3, 'Confirm Import'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[900]?.withValues(alpha: 0.2),
            border: Border.all(color: Colors.blue[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Summary:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue),
              ),
              const SizedBox(height: 12),
              _buildConfirmRow(
                  'New students to add:', newRecords.length, Colors.green),
              const SizedBox(height: 8),
              _buildConfirmRow(
                  'Will skip (duplicates):', duplicateCount, Colors.orange),
              const SizedBox(height: 8),
              _buildConfirmRow(
                  'Will skip (data errors):', invalidCount, Colors.red),
              const Divider(height: 16, color: Colors.blue),
              const Text(
                'Note: The system will:\n'
                ' • Create accounts only for new students\n'
                ' • Automatically skip existing students\n'
                ' • Automatically skip records with data errors',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Summary() {
    if (_importResult == null)
      return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(4, 'Import Results'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Import Statistics',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _importResult!.successCount > 0
                          ? Colors.green[900]
                          : Colors.red[900],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _importResult!.successCount > 0
                          ? 'Success'
                          : 'Unsuccessful',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('New students added:',
                  _importResult!.successCount.toString(), Colors.green),
              const SizedBox(height: 12),
              _buildSummaryRow('Skipped (duplicates):',
                  _duplicateCount.toString(), Colors.orange),
              const SizedBox(height: 12),
              _buildSummaryRow('Skipped (data errors):',
                  _invalidCount.toString(), Colors.orange),
              const SizedBox(height: 12),
              _buildSummaryRow('Errors:',
                  _importResult!.failureCount.toString(), Colors.red),
              const Divider(height: 20, color: Colors.grey),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total records:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white),
                  ),
                  Text(
                    '${_invalidCount + _duplicateCount + _importResult!.successCount}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Import Students from CSV'),
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        margin: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 24),
              if (_currentStep == 1) _buildStep1Upload(),
              if (_currentStep == 2 && !_isValidating) _buildStep2Preview(),
              if (_currentStep == 2 && _isValidating)
                const Center(
                    child: CircularProgressIndicator(color: Colors.blue)),
              if (_currentStep == 3) _buildStep3Confirm(),
              if (_currentStep == 4) _buildStep4Summary(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widgets remain unchanged (progress indicator, headers, stat boxes, buttons, etc.)
  // Only the parts you asked to modify have been updated.

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(4, (index) {
        final stepNum = index + 1;
        final isActive = _currentStep >= stepNum;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? Colors.blue : Colors.grey[700],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$stepNum',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              if (index < 3)
                Expanded(
                  child: Container(
                      height: 2,
                      color: _currentStep > stepNum
                          ? Colors.blue
                          : Colors.grey[700]),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepHeader(int step, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step $step: $title',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        Container(width: 40, height: 2, color: Colors.blue),
      ],
    );
  }

  Widget _buildStatBox(
      {required String title,
      required int count,
      required Color color,
      required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Expanded(
                child: Text(title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400])))
          ]),
          const SizedBox(height: 8),
          Text(count.toString(),
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.white)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              border: Border.all(color: color.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(6)),
          child: Text(value.toString(),
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              border: Border.all(color: color.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(6)),
          child: Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_currentStep > 1 && _currentStep < 4)
          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  _isLoading ? null : () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back', style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[600]!)),
            ),
          ),
        if (_currentStep > 1 && _currentStep < 4) const SizedBox(width: 12),
        if (_currentStep == 1)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: (_selectedFileName == null ||
                      _isValidating ||
                      _selectedCourse == null ||
                      _selectedGroup == null)
                  ? null
                  : _validateAndParse,
              icon: _isValidating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
              label: Text(
                  _isValidating
                      ? 'Checking...'
                      : (_selectedCourse == null || _selectedGroup == null)
                          ? 'Select course & group first'
                          : _selectedFileName == null
                              ? 'Upload CSV file first'
                              : 'Continue',
                  style: const TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: (_selectedFileName != null &&
                          _selectedCourse != null &&
                          _selectedGroup != null)
                      ? Colors.blue
                      : Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        if (_currentStep == 2)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: (_isLoading || _getNewStudentsCount() == 0)
                  ? null
                  : () => setState(() => _currentStep = 3),
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                  _getNewStudentsCount() == 0
                      ? 'No new students to add'
                      : 'Continue to confirm',
                  style: const TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _getNewStudentsCount() > 0
                      ? Colors.blue
                      : Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        if (_currentStep == 3)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _importData,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.upload),
              label: Text(_isLoading ? 'Importing...' : 'Import now',
                  style: const TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        if (_currentStep == 4)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.onImportComplete != null) {
                  final success = _importResult!.successCount > 0;
                  final message = success
                      ? 'Import successful: ${_importResult!.successCount} students added'
                      : 'Import completed: No new students added';
                  widget.onImportComplete!(success, message);
                }
                // Always navigate back after completion
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Done', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
      ],
    );
  }
}
