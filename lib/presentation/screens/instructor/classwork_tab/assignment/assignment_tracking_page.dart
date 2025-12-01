import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../domain/models/assignment_model.dart';
import '../../../../../domain/models/submission_model.dart';

/// Full-screen page for tracking student submissions and grading
class AssignmentTrackingPage extends ConsumerStatefulWidget {
  final Assignment assignment;
  final String courseId;

  const AssignmentTrackingPage({
    super.key,
    required this.assignment,
    required this.courseId,
  });

  @override
  ConsumerState<AssignmentTrackingPage> createState() =>
      _AssignmentTrackingPageState();
}

class _AssignmentTrackingPageState
    extends ConsumerState<AssignmentTrackingPage> {
  // Filter states
  String _selectedGroup = 'All Groups';
  String _selectedStatus = 'All';
  String _searchQuery = '';
  String _sortBy = 'Name A-Z';

  // Mock data for UI demonstration (will be replaced with real data)
  final List<StudentSubmissionData> _mockStudents = [
    StudentSubmissionData(
      studentId: 'S001',
      studentName: 'Nguyen Van An',
      studentCode: 'CTS-2301',
      avatarUrl: null,
      groupName: 'Group 1',
      status: SubmissionStatus.submitted,
      submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
      isLate: false,
      attachments: ['Assignment_Report.pdf'],
      grade: null,
    ),
    StudentSubmissionData(
      studentId: 'S002',
      studentName: 'Tran Thi Binh',
      studentCode: 'CTS-2298',
      avatarUrl: null,
      groupName: 'Group 1',
      status: SubmissionStatus.graded,
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
      isLate: false,
      attachments: ['Homework.docx'],
      grade: 85.0,
    ),
    StudentSubmissionData(
      studentId: 'S003',
      studentName: 'Le Van Cuong',
      studentCode: 'CTS-2295',
      avatarUrl: null,
      groupName: 'Group 2',
      status: SubmissionStatus.submitted,
      submittedAt: DateTime.now().subtract(const Duration(hours: 5)),
      isLate: true, // Submitted late
      attachments: ['Late_Submission.zip'],
      grade: null,
    ),
    StudentSubmissionData(
      studentId: 'S004',
      studentName: 'Pham Thi Dung',
      studentCode: 'CTS-2289',
      avatarUrl: null,
      groupName: 'Group 2',
      status: SubmissionStatus.draft,
      submittedAt: null,
      isLate: false,
      attachments: [],
      grade: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    // Mock metrics
    final totalAssigned = _mockStudents.length;
    final turnedIn = _mockStudents
        .where((s) =>
            s.status == SubmissionStatus.submitted ||
            s.status == SubmissionStatus.graded ||
            (s.status == SubmissionStatus.submitted && s.isLate))
        .length;
    final graded =
        _mockStudents.where((s) => s.status == SubmissionStatus.graded).length;
    final missing = _mockStudents
        .where(
            (s) => s.status == SubmissionStatus.draft && s.submittedAt == null)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Work Tracking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.assignment.title,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: isDesktop
          ? SingleChildScrollView(
              child: Column(
                children: [
                  // Header Dashboard (Metrics)
                  _buildMetricsHeader(
                      totalAssigned, turnedIn, graded, missing, isDesktop),

                  // Action Bar (Filters, Search, Sort, Export)
                  _buildActionBar(isDesktop),

                  // Body (Student List) - Full width table
                  _buildDesktopTable(),
                ],
              ),
            )
          : Column(
              children: [
                // Mobile Layout
                _buildMetricsHeader(
                    totalAssigned, turnedIn, graded, missing, isDesktop),
                _buildActionBar(isDesktop),
                const SizedBox(height: 16),
                Expanded(child: _buildMobileList()),
              ],
            ),
    );
  }

  /// Metrics Header with 4 stat cards
  Widget _buildMetricsHeader(int totalAssigned, int turnedIn, int graded,
      int missing, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: isDesktop
          ? Row(
              children: [
                Flexible(
                  flex: 1,
                  child: _buildStatCard(
                    'Total Assigned',
                    totalAssigned.toString(),
                    Icons.group,
                    Colors.blue,
                    isFlexible: true,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: _buildStatCard(
                    'Turned In',
                    turnedIn.toString(),
                    Icons.upload_file,
                    Colors.green,
                    isFlexible: true,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: _buildStatCard(
                    'Graded',
                    graded.toString(),
                    Icons.check_circle,
                    Colors.purple,
                    isFlexible: true,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: _buildStatCard(
                    'Missing',
                    missing.toString(),
                    Icons.warning,
                    Colors.red,
                    isFlexible: true,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total',
                        totalAssigned.toString(),
                        Icons.group,
                        Colors.blue,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Turned In',
                        turnedIn.toString(),
                        Icons.upload_file,
                        Colors.green,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Graded',
                        graded.toString(),
                        Icons.check_circle,
                        Colors.purple,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Missing',
                        missing.toString(),
                        Icons.warning,
                        Colors.red,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool compact = false,
    bool isFlexible = false,
  }) {
    final cardContent = Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: compact
            ? Column(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          color: color,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ));

    // Return plain content (parent will handle Expanded/Flexible)
    return cardContent;
  }

  /// Action Bar with filters, search, sort, export
  Widget _buildActionBar(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: isDesktop ? _buildDesktopActionBar() : _buildMobileActionBar(),
    );
  }

  Widget _buildDesktopActionBar() {
    return Row(
      children: [
        // Filter by Group
        _buildDropdown(
          label: 'Group',
          value: _selectedGroup,
          items: ['All Groups', 'Group 1', 'Group 2'],
          onChanged: (value) => setState(() => _selectedGroup = value!),
        ),
        const SizedBox(width: 12),

        // Filter by Status
        _buildDropdown(
          label: 'Status',
          value: _selectedStatus,
          items: ['All', 'Turned In', 'Late', 'Missing', 'Graded'],
          onChanged: (value) => setState(() => _selectedStatus = value!),
        ),
        const SizedBox(width: 12),

        // Search
        Expanded(
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by name or student code...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
              filled: true,
              fillColor: const Color(0xFF0F172A),
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
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Sort
        _buildDropdown(
          label: 'Sort',
          value: _sortBy,
          items: ['Name A-Z', 'Name Z-A', 'Newest First', 'Oldest First'],
          onChanged: (value) => setState(() => _sortBy = value!),
        ),
        const SizedBox(width: 12),

        // Export CSV
        ElevatedButton.icon(
          onPressed: _exportToCSV,
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Export CSV'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileActionBar() {
    return Column(
      children: [
        // Search
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search student...',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Filters row
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: 'Group',
                value: _selectedGroup,
                items: ['All Groups', 'Group 1', 'Group 2'],
                onChanged: (value) => setState(() => _selectedGroup = value!),
                compact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDropdown(
                label: 'Status',
                value: _selectedStatus,
                items: ['All', 'Turned In', 'Late', 'Missing', 'Graded'],
                onChanged: (value) => setState(() => _selectedStatus = value!),
                compact: true,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _exportToCSV,
              icon: const Icon(Icons.download, color: Colors.indigo),
              style: IconButton.styleFrom(
                backgroundColor: Colors.indigo.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool compact = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      compact ? item.split(' ').first : item,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          dropdownColor: const Color(0xFF1E293B),
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
        ),
      ),
    );
  }

  /// Desktop DataTable - Full Width with Whole Page Scroll
  Widget _buildDesktopTable() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'STUDENT',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      'STATUS',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'SUBMISSION',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      'GRADE',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Table Body - shrinkWrap for whole page scroll
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mockStudents.length,
              itemBuilder: (context, index) {
                final student = _mockStudents[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[800]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Student Column
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.indigo,
                              child: Text(
                                student.studentName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    student.studentName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    student.studentCode,
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status Column
                      SizedBox(
                        width: 110,
                        child: _buildStatusTag(student.status,
                            isLate: student.isLate),
                      ),

                      // Submission Column
                      Expanded(
                        flex: 3,
                        child: student.attachments.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () =>
                                        _previewFile(student.attachments[0]),
                                    child: Text(
                                      student.attachments[0],
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 13,
                                        decoration: TextDecoration.underline,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (student.submittedAt != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 12, color: Colors.grey[500]),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDateTime(student.submittedAt!),
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              )
                            : Text(
                                'No submission',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                      ),

                      // Grade Column
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: TextEditingController(
                            text: student.grade?.toString() ?? '',
                          ),
                          onSubmitted: (value) {
                            _saveGrade(student.studentId, value);
                          },
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '0-100',
                            hintStyle: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                                  const BorderSide(color: Colors.indigo),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Mobile ListView Cards
  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mockStudents.length,
      itemBuilder: (context, index) {
        final student = _mockStudents[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Avatar + Name + Status
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.indigo,
                    child: Text(
                      student.studentName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.studentName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          student.studentCode,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusTag(student.status, isLate: student.isLate),
                ],
              ),

              if (student.submittedAt != null) ...[
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF334155), height: 1),
                const SizedBox(height: 12),

                // Row 2: Submission file
                if (student.attachments.isNotEmpty)
                  InkWell(
                    onTap: () => _previewFile(student.attachments.first),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.indigo.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.attach_file,
                              size: 18, color: Colors.indigo[300]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              student.attachments.first,
                              style: TextStyle(
                                color: Colors.indigo[300],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.visibility,
                              size: 16, color: Colors.grey[500]),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Submitted time
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(student.submittedAt!),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Row 3: Grade input + Return button
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: TextEditingController(
                          text: student.grade?.toString() ?? '',
                        ),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Grade',
                          labelStyle: TextStyle(color: Colors.grey[500]),
                          hintText: '0-100',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onSubmitted: (value) =>
                            _saveGrade(student.studentId, value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () => _returnWork(student.studentId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Return',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (student.submittedAt == null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'No submission yet',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusTag(SubmissionStatus status, {bool isLate = false}) {
    Color color;
    String label;
    IconData icon;

    // Handle late submission
    if (isLate && status == SubmissionStatus.submitted) {
      color = Colors.orange;
      label = 'Late';
      icon = Icons.schedule;
    } else {
      switch (status) {
        case SubmissionStatus.submitted:
          color = Colors.green;
          label = 'Turned In';
          icon = Icons.check_circle;
          break;
        case SubmissionStatus.graded:
          color = Colors.purple;
          label = 'Graded';
          icon = Icons.grade;
          break;
        case SubmissionStatus.returned:
          color = Colors.blue;
          label = 'Returned';
          icon = Icons.assignment_returned;
          break;
        default:
          color = Colors.red;
          label = 'Missing';
          icon = Icons.warning;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('h:mm a').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('h:mm a').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, h:mm a').format(dateTime);
    }
  }

  // Action handlers (placeholder)
  void _exportToCSV() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export CSV functionality will be implemented'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  void _previewFile(String fileName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preview: $fileName'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  void _saveGrade(String studentId, String grade) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Grade saved for $studentId: $grade'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _returnWork(String studentId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Work returned to $studentId'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

/// Data model for student submission (mock)
class StudentSubmissionData {
  final String studentId;
  final String studentName;
  final String studentCode;
  final String? avatarUrl;
  final String groupName;
  final SubmissionStatus status;
  final DateTime? submittedAt;
  final bool isLate; // NEW: Flag to indicate late submission
  final List<String> attachments;
  final double? grade;

  StudentSubmissionData({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    this.avatarUrl,
    required this.groupName,
    required this.status,
    this.submittedAt,
    this.isLate = false,
    required this.attachments,
    this.grade,
  });
}
