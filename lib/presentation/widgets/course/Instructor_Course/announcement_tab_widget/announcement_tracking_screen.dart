// ========================================
// FILE: announcement_tracking_screen.dart (FINAL FIX)
// MÔ TẢ: Fixed infinite loop by using ref.read() instead of ref.watch()
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

import 'package:elearning_management_app/domain/models/announcement_tracking_model.dart';
import 'package:elearning_management_app/data/repositories/announcement/announcement_repository.dart';
import 'package:elearning_management_app/data/repositories/course/enrollment_repository.dart';

// ========================================
// PROVIDER: Fixed with ref.read() instead of ref.watch()
// ========================================
typedef TrackingParams = ({String announcementId, String courseId});

final announcementTrackingProvider = FutureProvider.family<Map<String, dynamic>, TrackingParams>(
  (ref, params) async {
    final announcementId = params.announcementId;
    final courseId = params.courseId;
    
    print('🔍 PROVIDER START:');
    print('   announcementId: $announcementId');
    print('   courseId: $courseId');
    
    // ✅ FIX: Use ref.read() instead of ref.watch()
    final repo = ref.read(AnnouncementRepositoryProvider);
    final enrollmentRepo = EnrollmentRepository();
    
    // Get tracking data
    final trackingData = await repo.getTrackingList(announcementId);
    print('📊 Tracking records: ${trackingData.length}');
    
    // Get ALL enrolled students
    final allEnrollments = await enrollmentRepo.getStudentsInCourse(courseId);
    print('👥 Total enrolled: ${allEnrollments.length}');
    
    // Create tracking models for students who haven't viewed yet
    final trackedStudentIds = trackingData.map((t) => t.studentId).toSet();
    print('✅ Students with tracking: ${trackedStudentIds.length}');
    
    // ✅ Use static placeholder date to prevent rebuilds
    final fixedPlaceholderDate = DateTime(2000, 1, 1);
    
    final notViewedStudents = allEnrollments
        .where((enrollment) => !trackedStudentIds.contains(enrollment.userId))
        .map((enrollment) {
          print('   🆕 Creating placeholder for: ${enrollment.userId}');
          return AnnouncementTrackingModel(
            id: AnnouncementTrackingModel.generateId(
              announcementId: announcementId,
              studentId: enrollment.userId,
            ),
            announcementId: announcementId,
            studentId: enrollment.userId,
            courseId: courseId,
            groupId: enrollment.groupId,
            hasViewed: false,
            hasDownloaded: false,
            lastViewedAt: fixedPlaceholderDate,
          );
        })
        .toList();
    
    print('❌ Students without tracking: ${notViewedStudents.length}');
    
    final allTracking = [...trackingData, ...notViewedStudents];
    print('📋 FINAL tracking records: ${allTracking.length}');
    print('   Viewed: ${allTracking.where((t) => t.hasViewed).length}');
    print('   Not Viewed: ${allTracking.where((t) => !t.hasViewed).length}');
    print('✅ PROVIDER COMPLETE - Will NOT rebuild unless invalidated\n');
    
    return {
      'trackingData': allTracking,
      'enrollments': allEnrollments,
    };
  },
);

// ========================================
// SCREEN: Announcement Tracking
// ========================================
class AnnouncementTrackingScreen extends ConsumerStatefulWidget {
  final String announcementId;
  final String announcementTitle;
  final String courseId;
  final List<String> targetGroupIds;

  const AnnouncementTrackingScreen({
    super.key,
    required this.announcementId,
    required this.announcementTitle,
    required this.courseId,
    required this.targetGroupIds,
  });

  @override
  ConsumerState<AnnouncementTrackingScreen> createState() =>
      _AnnouncementTrackingScreenState();
}

class _AnnouncementTrackingScreenState
    extends ConsumerState<AnnouncementTrackingScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _groupFilter = 'All';
  String _sortColumn = 'studentId';
  bool _sortAscending = true;
  Map<String, String> _groupMap = {};
  String _getGroupName(String groupId) {
    return _groupMap[groupId] ?? 'Unknown Group';
  }
  @override
  Widget build(BuildContext context) {
  final trackingAsync = ref.watch(
    announcementTrackingProvider((
      announcementId: widget.announcementId,
      courseId: widget.courseId,
    )), // 👈 Chú ý: 2 dấu ngoặc tròn ((...))
  );

    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        title: Text('Tracking: ${widget.announcementTitle}'),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(announcementTrackingProvider);
            },
          ),
        ],
      ),
      body: trackingAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading tracking data...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Error loading tracking data',
                style: TextStyle(color: Colors.red[400], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  err.toString(),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(announcementTrackingProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
        data: (dataMap) {
          final trackingData = dataMap['trackingData'] as List<AnnouncementTrackingModel>;
          final filteredData = _applyFilters(trackingData);
          final groups = trackingData.map((e) => e.groupId).toSet().toList()..sort();
          
          // Calculate statistics
          final totalStudents = trackingData.length;
          final viewedCount = trackingData.where((t) => t.hasViewed).length;
          final notViewedCount = totalStudents - viewedCount;
          final downloadedCount = trackingData.where((t) => t.hasDownloaded).length;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Cards
                _buildStatisticsCards(viewedCount, notViewedCount, downloadedCount, totalStudents),
                const SizedBox(height: 16),

                // Filters
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // Search
                    SizedBox(
                      width: 300,
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by student or group...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: const Color(0xFF1F2937),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    // Status filter
                    _buildFilterDropdown(
                      label: 'Status',
                      value: _statusFilter,
                      items: ['All', 'Viewed', 'Not Viewed', 'Downloaded'],
                      onChanged: (value) => setState(() => _statusFilter = value!),
                    ),
                    // Group filter
                    _buildFilterDropdown(
                      label: 'Group',
                      value: _groupFilter,
                      items: ['All', ...groups],
                      onChanged: (value) => setState(() => _groupFilter = value!),
                    ),
                    // Export button
                    ElevatedButton.icon(
                      onPressed: () => _exportToCSV(filteredData),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Export CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Results count
                Text(
                  'Showing ${filteredData.length} of $totalStudents students',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                const SizedBox(height: 12),

                // Table
                Expanded(
                  child: _buildTrackingTable(filteredData),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ========================================
  // FILTER LOGIC
  // ========================================
  List<AnnouncementTrackingModel> _applyFilters(List<AnnouncementTrackingModel> data) {
    var filtered = data;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((track) {
        return track.studentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            track.groupId.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_statusFilter == 'Viewed') {
      filtered = filtered.where((track) => track.hasViewed).toList();
    } else if (_statusFilter == 'Not Viewed') {
      filtered = filtered.where((track) => !track.hasViewed).toList();
    } else if (_statusFilter == 'Downloaded') {
      filtered = filtered.where((track) => track.hasDownloaded).toList();
    }

    if (_groupFilter != 'All') {
      filtered = filtered.where((track) => track.groupId == _groupFilter).toList();
    }

    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn) {
        case 'studentId':
          comparison = a.studentId.compareTo(b.studentId);
          break;
        case 'group':
          comparison = a.groupId.compareTo(b.groupId);
          break;
        case 'hasViewed':
          comparison = (a.hasViewed ? 1 : 0).compareTo(b.hasViewed ? 1 : 0);
          break;
        case 'lastViewedAt':
          comparison = a.lastViewedAt.compareTo(b.lastViewedAt);
          break;
        case 'hasDownloaded':
          comparison = (a.hasDownloaded ? 1 : 0).compareTo(b.hasDownloaded ? 1 : 0);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  // ========================================
  // CSV EXPORT
  // ========================================
  Future<void> _exportToCSV(List<AnnouncementTrackingModel> trackingData) async {
    try {
      final List<List<dynamic>> csvData = [];
      
      csvData.add([
        'Student ID',
        'Group',
        'Has Viewed',
        'Last Viewed',
        'Has Downloaded',
        'Last Downloaded',
      ]);

      for (final track in trackingData) {
        csvData.add([
          track.studentId,
          track.groupId,
          track.hasViewed ? 'Yes' : 'No',
          track.hasViewed ? _formatDateTime(track.lastViewedAt) : 'Not viewed',
          track.hasDownloaded ? 'Yes' : 'No',
          track.hasDownloaded && track.lastDownloadedAt != null
              ? _formatDateTime(track.lastDownloadedAt!)
              : 'Not downloaded',
        ]);
      }

      const converter = ListToCsvConverter();
      final csvString = converter.convert(csvData);

      final fileName = 'announcement_tracking_${widget.announcementId}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Announcement Tracking CSV',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: utf8.encode(csvString),
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    if (dt.year == 2000 && dt.month == 1 && dt.day == 1) {
      return 'Not viewed';
    }
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ========================================
  // UI BUILDERS
  // ========================================
  
  Widget _buildStatisticsCards(int viewed, int notViewed, int downloaded, int total) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        
        final cards = [
          _StatCard(
            title: 'Viewed',
            value: viewed.toString(),
            subtitle: '${total > 0 ? ((viewed / total) * 100).toStringAsFixed(0) : 0}%',
            color: const Color(0xFF34D399),
            icon: Icons.visibility,
          ),
          _StatCard(
            title: 'Not Viewed',
            value: notViewed.toString(),
            subtitle: '${total > 0 ? ((notViewed / total) * 100).toStringAsFixed(0) : 0}%',
            color: const Color(0xFFFF6B6B),
            icon: Icons.visibility_off,
          ),
          _StatCard(
            title: 'Downloaded',
            value: downloaded.toString(),
            subtitle: '${total > 0 ? ((downloaded / total) * 100).toStringAsFixed(0) : 0}%',
            color: const Color(0xFF60A5FA),
            icon: Icons.download,
          ),
          _StatCard(
            title: 'Total Students',
            value: total.toString(),
            subtitle: 'Enrolled',
            color: const Color(0xFF9CA3AF),
            icon: Icons.people,
          ),
        ];
        
        if (isSmall) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }
        
        return Row(
          children: cards.map((card) => 
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: card == cards.last ? 0 : 12),
                child: card,
              ),
            ),
          ).toList(),
        );
      },
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            dropdownColor: const Color(0xFF1F2937),
            style: const TextStyle(color: Colors.white),
            underline: const SizedBox(),
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingTable(List<AnnouncementTrackingModel> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF1F2937)),
            dataRowMinHeight: 48,
            dataRowMaxHeight: 64,
            columns: [
              DataColumn(
                label: const Text('Student ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onSort: (_, __) => setState(() {
                  if (_sortColumn == 'studentId') {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortColumn = 'studentId';
                    _sortAscending = true;
                  }
                }),
              ),
              const DataColumn(label: Text('Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Viewed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Last Viewed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Downloaded', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Last Downloaded', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ],
            rows: data.map((track) {
              return DataRow(cells: [
                DataCell(Text(track.studentId, style: const TextStyle(color: Colors.white))),
                DataCell(Text(track.groupId, style: const TextStyle(color: Colors.white70))),
                DataCell(
                  Icon(
                    track.hasViewed ? Icons.check_circle : Icons.cancel,
                    color: track.hasViewed ? const Color(0xFF34D399) : const Color(0xFFFF6B6B),
                  ),
                ),
                DataCell(Text(
                  track.hasViewed ? track.timeAgo : 'Not viewed',
                  style: const TextStyle(color: Colors.white70),
                )),
                DataCell(
                  Icon(
                    track.hasDownloaded ? Icons.download_done : Icons.remove_circle_outline,
                    color: track.hasDownloaded ? const Color(0xFF60A5FA) : Colors.grey,
                  ),
                ),
                DataCell(Text(
                  track.downloadTimeAgo ?? 'Not downloaded',
                  style: const TextStyle(color: Colors.white70),
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ========================================
// WIDGET: Statistics Card
// ========================================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}