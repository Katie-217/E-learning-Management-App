// ========================================
// FILE: instructor_forum_screen.dart
// MÔ TẢ: Màn hình quản lý forum tập trung cho instructor
// Instructor có thể xem tất cả courses và quản lý forum của từng course
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/application/controllers/course/course_instructor_provider.dart';
import 'package:elearning_management_app/application/controllers/forum/forum_provider.dart';
import 'package:elearning_management_app/presentation/widgets/student/forum/forum_topics_screen.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';

class InstructorForumScreen extends ConsumerStatefulWidget {
  const InstructorForumScreen({super.key});

  @override
  ConsumerState<InstructorForumScreen> createState() => _InstructorForumScreenState();
}

class _InstructorForumScreenState extends ConsumerState<InstructorForumScreen> {
  String _searchQuery = '';
  String _selectedSemester = 'All';

  @override
  void initState() {
    super.initState();
    // Load instructor courses when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courseInstructorProvider.notifier).loadInstructorCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final coursesState = ref.watch(courseInstructorProvider);
    final courses = coursesState.filteredCourses;
    
    // Filter courses by search query
    final filteredCourses = courses.where((course) {
      final matchesSearch = _searchQuery.isEmpty ||
          course.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          course.code.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesSemester = _selectedSemester == 'All' || 
          course.semester == _selectedSemester;
      
      return matchesSearch && matchesSemester;
    }).toList();

    // Get available semesters
    final semesters = courses.map((c) => c.semester).toSet().toList()..sort();

    return Column(
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Description
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.indigo, Colors.purple],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.forum, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Course Forums Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage discussion forums for all your courses',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              const Divider(color: Colors.grey),
              const SizedBox(height: 20),

              // Search and Filter Row
              Row(
                children: [
                  // Search Bar
                  Expanded(
                    flex: 2,
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search courses by name or code...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFF111827),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Semester Filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedSemester,
                      dropdownColor: const Color(0xFF111827),
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      items: ['All', ...semesters].map((semester) {
                        return DropdownMenuItem(
                          value: semester,
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 8),
                              Text(semester),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedSemester = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Courses Grid/List
        Expanded(
          child: coursesState.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.indigo),
                )
              : coursesState.error != null
                  ? Center(
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
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            coursesState.error!,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : filteredCourses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 80,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'No courses found',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'You don\'t have any courses yet'
                                    : 'Try adjusting your search or filters',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await ref
                                .read(courseInstructorProvider.notifier)
                                .refreshInstructorCourses();
                          },
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Responsive grid
                              final crossAxisCount = constraints.maxWidth > 1200
                                  ? 3
                                  : constraints.maxWidth > 800
                                      ? 2
                                      : 1;
                              
                              return GridView.builder(
                                padding: const EdgeInsets.all(4),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 1.5,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: filteredCourses.length,
                                itemBuilder: (context, index) {
                                  final course = filteredCourses[index];
                                  return _CourseForumCard(
                                    courseId: course.id,
                                    courseName: course.name,
                                    courseCode: course.code,
                                    semester: course.semester,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ForumTopicsScreen(
                                            courseId: course.id,
                                            courseName: '${course.code} - ${course.name}',
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

// ========================================
// WIDGET: Course Forum Card
// ========================================
class _CourseForumCard extends ConsumerWidget {
  final String courseId;
  final String courseName;
  final String courseCode;
  final String semester;
  final VoidCallback onTap;

  const _CourseForumCard({
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.semester,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get forum stats for this course
    final topicsAsync = ref.watch(topicsProvider(courseId));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.indigo, Colors.purple],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.forum, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            courseCode,
                            style: TextStyle(
                              color: Colors.indigo[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            courseName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Semester Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.blue[300]),
                      const SizedBox(width: 4),
                      Text(
                        semester,
                        style: TextStyle(
                          color: Colors.blue[300],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(color: Colors.grey, height: 1),
                const SizedBox(height: 12),

                // Stats
                topicsAsync.when(
                  loading: () => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, __) => Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[400], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Error loading stats',
                        style: TextStyle(color: Colors.red[400], fontSize: 12),
                      ),
                    ],
                  ),
                  data: (topics) {
                    final topicCount = topics.length;
                    final replyCount = topics.fold<int>(
                      0,
                      (sum, topic) => sum + (topic['replyCount'] as int? ?? 0),
                    );

                    return Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            label: 'Topics',
                            value: topicCount,
                            icon: Icons.topic,
                            color: Colors.blue[400]!,
                          ),
                        ),
                        Container(width: 1, height: 30, color: Colors.grey[700]),
                        Expanded(
                          child: _StatItem(
                            label: 'Replies',
                            value: replyCount,
                            icon: Icons.comment,
                            color: Colors.green[400]!,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.manage_search, size: 18),
                    label: const Text('Manage Forum'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.withOpacity(0.2),
                      foregroundColor: Colors.indigo[300],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.indigo.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================
// WIDGET: Stat Item
// ========================================
class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}