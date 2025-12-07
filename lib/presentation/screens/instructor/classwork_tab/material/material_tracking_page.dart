// ========================================
// FILE: material_tracking_page.dart
// MÔ TẢ: Material Tracking Screen - Theo dõi ai đã xem và tải material
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:elearning_management_app/domain/models/material_tracker_model.dart';
import 'package:elearning_management_app/application/providers/material_tracker_provider.dart';
import 'package:elearning_management_app/data/repositories/course/enrollment_repository.dart';
import 'package:elearning_management_app/data/repositories/group/group_repository.dart';

// ========================================
// SCREEN: Material Tracking
// ========================================
class MaterialTrackingPage extends ConsumerStatefulWidget {
  final String materialId;
  final String materialTitle;
  final String courseId;

  const MaterialTrackingPage({
    super.key,
    required this.materialId,
    required this.materialTitle,
    required this.courseId,
  });

  @override
  ConsumerState<MaterialTrackingPage> createState() =>
      _MaterialTrackingPageState();
}

class _MaterialTrackingPageState extends ConsumerState<MaterialTrackingPage> {
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Viewed, Not Viewed, Downloaded
  String _groupFilter = 'All';
  String _sortColumn = 'studentName';
  bool _sortAscending = true;
  List<String> _availableGroups = [];
  Map<String, String> _groupIdToName = {}; // Map groupId -> groupName

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  // Load available groups from enrollments
  Future<void> _loadGroups() async {
    try {
      final enrollmentRepo = EnrollmentRepository();
      final enrollments =
          await enrollmentRepo.getStudentsInCourse(widget.courseId);

      final groupIds = enrollments
          .map((e) => e.groupId)
          .where((g) => g.isNotEmpty)
          .toSet()
          .toList();

      // Load group names
      final Map<String, String> groupMap = {};
      for (final groupId in groupIds) {
        try {
          final group =
              await GroupRepository.getGroupById(widget.courseId, groupId);
          if (group != null) {
            groupMap[groupId] = group.name;
          }
        } catch (e) {
          print('Error loading group $groupId: $e');
          groupMap[groupId] = groupId; // Fallback to ID if name not found
        }
      }

      final groupNames = groupMap.values.toList()..sort();

      if (mounted) {
        setState(() {
          _groupIdToName = groupMap;
          _availableGroups = groupNames;
        });
      }
    } catch (e) {
      print('Error loading groups: $e');
    }
  }

  // ========================================
  // CSV EXPORT
  // ========================================
  Future<void> _exportToCSV(List<MaterialTrackerModel> trackingData) async {
    try {
      final List<List<dynamic>> csvData = [];

      // Header
      csvData.add([
        'Student Name',
        'Email',
        'Group',
        'Has Viewed',
        'Last Viewed',
        'Has Downloaded',
        'Last Downloaded',
      ]);

      // Data rows
      for (final track in trackingData) {
        csvData.add([
          track.studentName,
          track.studentEmail,
          _groupIdToName[track.groupId] ?? track.groupId,
          track.isViewed ? 'Yes' : 'No',
          track.isViewed && track.viewedAt != null
              ? _formatDateTime(track.viewedAt!)
              : '-',
          track.isDownloaded ? 'Yes' : 'No',
          track.isDownloaded && track.downloadedAt != null
              ? _formatDateTime(track.downloadedAt!)
              : '-',
        ]);
      }

      // Convert to CSV
      const converter = ListToCsvConverter();
      final csvString = converter.convert(csvData);

      // Save file
      final fileName =
          'material_tracking_${widget.materialId}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Material Tracking CSV',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: utf8.encode(csvString),
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported successfully: $result'),
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
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${difference.inDays >= 730 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays >= 60 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // ========================================
  // FILTER LOGIC (Client-side for status, search & sort)
  // ========================================
  List<MaterialTrackerModel> _applyFilters(List<MaterialTrackerModel> data) {
    var filtered = data;

    // Group Filter is now handled by Firestore query (removed from here)

    // Status Filter
    if (_statusFilter != 'All') {
      filtered = filtered.where((track) {
        switch (_statusFilter) {
          case 'Viewed':
            return track.isViewed;
          case 'Not Viewed':
            return !track.isViewed;
          case 'Downloaded':
            return track.isDownloaded;
          case 'Not Downloaded':
            return !track.isDownloaded;
          case 'Viewed & Downloaded':
            return track.isViewed && track.isDownloaded;
          default:
            return true;
        }
      }).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((track) {
        final studentName = track.studentName.toLowerCase();
        final studentEmail = track.studentEmail.toLowerCase();
        final groupId = track.groupId.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return studentName.contains(query) ||
            studentEmail.contains(query) ||
            groupId.contains(query);
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn) {
        case 'studentName':
          comparison = a.studentName.compareTo(b.studentName);
          break;
        case 'group':
          comparison = a.groupId.compareTo(b.groupId);
          break;
        case 'hasViewed':
          comparison = (a.isViewed ? 1 : 0).compareTo(b.isViewed ? 1 : 0);
          break;
        case 'lastViewedAt':
          if (a.viewedAt == null && b.viewedAt == null) return 0;
          if (a.viewedAt == null) return 1;
          if (b.viewedAt == null) return -1;
          comparison = a.viewedAt!.compareTo(b.viewedAt!);
          break;
        case 'hasDownloaded':
          comparison =
              (a.isDownloaded ? 1 : 0).compareTo(b.isDownloaded ? 1 : 0);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  // ========================================
  // BUILD UI
  // ========================================
  @override
  Widget build(BuildContext context) {
    // Convert group name to group ID for query
    String? selectedGroupId;
    if (_groupFilter != 'All') {
      selectedGroupId = _groupIdToName.entries
          .firstWhere((entry) => entry.value == _groupFilter,
              orElse: () => MapEntry('', ''))
          .key;
      if (selectedGroupId!.isEmpty) selectedGroupId = null;
    }

    // ✅ Real-time data from Firestore with Group Filter (Status filtered client-side)
    final trackingAsync = ref.watch(
      materialTrackersStreamProvider(
        MaterialTrackersParams(
          materialId: widget.materialId,
          groupId: selectedGroupId, // ✅ Use groupId, not group name
          status:
              null, // Don't filter by status in Firestore, do it client-side
        ),
      ),
    );
    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        title: Text(
          'Material Tracking: ${widget.materialTitle}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: trackingAsync.when(
        data: (trackers) => _buildContent(trackers),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading tracking data',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<MaterialTrackerModel> trackingData) {
    final filteredData = _applyFilters(trackingData);

    // Statistics
    final viewedCount = trackingData.where((t) => t.isViewed).length;
    final notViewedCount = trackingData.length - viewedCount;
    final downloadedCount = trackingData.where((t) => t.isDownloaded).length;

    final isSmallScreen = MediaQuery.of(context).size.width < 900;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            _buildStatisticsCards(viewedCount, notViewedCount, downloadedCount,
                trackingData.length, isSmallScreen),
            const SizedBox(height: 16),

            // Filters Row
            isSmallScreen
                ? _buildMobileFilters(filteredData)
                : _buildDesktopFilters(filteredData),
            const SizedBox(height: 16),

            // Table
            trackingData.isEmpty
                ? _buildEmptyState()
                : _buildTrackingTable(filteredData, isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(int viewed, int notViewed, int downloaded,
      int total, bool isSmallScreen) {
    final stats = [
      {
        'title': 'Viewed',
        'value': viewed,
        'icon': Icons.visibility,
        'color': const Color(0xFF34D399)
      },
      {
        'title': 'Not Viewed',
        'value': notViewed,
        'icon': Icons.visibility_off,
        'color': const Color(0xFFFF6B6B)
      },
      {
        'title': 'Downloaded',
        'value': downloaded,
        'icon': Icons.download,
        'color': const Color(0xFF60A5FA)
      },
      {
        'title': 'Total Students',
        'value': total,
        'icon': Icons.people,
        'color': const Color(0xFF9CA3AF)
      },
    ];

    if (isSmallScreen) {
      return Column(
        children: stats.map((stat) {
          final value = stat['value'] as int;
          final percentage = total > 0 && stat['title'] != 'Total Students'
              ? '${((value / total) * 100).toStringAsFixed(0)}%'
              : stat['title'] == 'Total Students'
                  ? 'Enrolled'
                  : '0%';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StatCard(
              title: stat['title'] as String,
              value: value.toString(),
              subtitle: percentage,
              color: stat['color'] as Color,
              icon: stat['icon'] as IconData,
            ),
          );
        }).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - (12 * (stats.length - 1))) / stats.length;

        return SizedBox(
          height: 120,
          child: Row(
            children: List.generate(stats.length, (index) {
              final stat = stats[index];
              final value = stat['value'] as int;
              final percentage = total > 0 && stat['title'] != 'Total Students'
                  ? '${((value / total) * 100).toStringAsFixed(0)}%'
                  : stat['title'] == 'Total Students'
                      ? 'Enrolled'
                      : '0%';

              return SizedBox(
                width: index < stats.length - 1 ? cardWidth : cardWidth,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < stats.length - 1 ? 12 : 0,
                  ),
                  child: _StatCard(
                    title: stat['title'] as String,
                    value: value.toString(),
                    subtitle: percentage,
                    color: stat['color'] as Color,
                    icon: stat['icon'] as IconData,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildDesktopFilters(List<MaterialTrackerModel> filteredData) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by student name, ID, or group...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: const Color(0xFF1F2937),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 180,
          child: _buildFilterDropdown(
            label: 'Status',
            value: _statusFilter,
            items: [
              'All',
              'Viewed',
              'Not Viewed',
              'Downloaded',
              'Not Downloaded',
              'Viewed & Downloaded'
            ],
            onChanged: (value) => setState(() => _statusFilter = value!),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 150,
          child: _buildFilterDropdown(
            label: 'Group',
            value: _groupFilter,
            items: ['All', ..._availableGroups],
            onChanged: (value) => setState(() => _groupFilter = value!),
          ),
        ),
        const SizedBox(width: 12),
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
    );
  }

  Widget _buildMobileFilters(List<MaterialTrackerModel> filteredData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFF1F2937),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFilterDropdown(
                label: 'Status',
                value: _statusFilter,
                items: [
                  'All',
                  'Viewed',
                  'Not Viewed',
                  'Downloaded',
                  'Not Downloaded',
                  'Viewed & Downloaded'
                ],
                onChanged: (value) => setState(() => _statusFilter = value!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFilterDropdown(
                label: 'Group',
                value: _groupFilter,
                items: ['All', ..._availableGroups],
                onChanged: (value) => setState(() => _groupFilter = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _exportToCSV(filteredData),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Export CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
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
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              dropdownColor: const Color(0xFF1F2937),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'No tracking data available',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Students will appear here once they view or download this material',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTable(
      List<MaterialTrackerModel> data, bool isSmallScreen) {
    if (isSmallScreen) {
      // Mobile/Tablet: Card List View
      return Column(
        children: data.map((track) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Student Info
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            track.studentName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track.studentEmail,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _groupIdToName[track.groupId] ?? track.groupId,
                        style:
                            const TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.grey, height: 1),
                const SizedBox(height: 12),
                // Status Row
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                track.isViewed
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: track.isViewed
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFFFF6B6B),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Viewed',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track.isViewed && track.viewedAt != null
                                ? _getTimeAgo(track.viewedAt!)
                                : '-',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                track.isDownloaded
                                    ? Icons.download_done
                                    : Icons.remove_circle_outline,
                                color: track.isDownloaded
                                    ? const Color(0xFF60A5FA)
                                    : Colors.grey[600],
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Downloaded',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track.isDownloaded && track.downloadedAt != null
                                ? _getTimeAgo(track.downloadedAt!)
                                : '-',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    // Desktop: Table View
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFF1F2937)),
          dataRowColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.hovered)) {
                return Colors.grey[800]!.withOpacity(0.3);
              }
              return Colors.transparent;
            },
          ),
          columnSpacing: 40,
          columns: [
            DataColumn(
              label: const Text('Student Name',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              onSort: (_, __) => setState(() {
                if (_sortColumn == 'studentName') {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortColumn = 'studentName';
                  _sortAscending = true;
                }
              }),
            ),
            const DataColumn(
                label: Text('Email',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))),
            const DataColumn(
                label: Text('Group',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(
              label: const Text('Viewed',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              onSort: (_, __) => setState(() {
                if (_sortColumn == 'hasViewed') {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortColumn = 'hasViewed';
                  _sortAscending = true;
                }
              }),
            ),
            DataColumn(
              label: const Text('Last Viewed',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              onSort: (_, __) => setState(() {
                if (_sortColumn == 'lastViewedAt') {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortColumn = 'lastViewedAt';
                  _sortAscending = true;
                }
              }),
            ),
            DataColumn(
              label: const Text('Downloaded',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              onSort: (_, __) => setState(() {
                if (_sortColumn == 'hasDownloaded') {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortColumn = 'hasDownloaded';
                  _sortAscending = true;
                }
              }),
            ),
            const DataColumn(
                label: Text('Last Downloaded',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))),
          ],
          rows: data.map((track) {
            return DataRow(cells: [
              DataCell(Text(track.studentName,
                  style: const TextStyle(color: Colors.white))),
              DataCell(Text(track.studentEmail,
                  style: const TextStyle(color: Colors.white70))),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_groupIdToName[track.groupId] ?? track.groupId,
                    style: const TextStyle(color: Colors.blue, fontSize: 12)),
              )),
              DataCell(
                Icon(
                  track.isViewed ? Icons.check_circle : Icons.cancel,
                  color: track.isViewed
                      ? const Color(0xFF34D399)
                      : const Color(0xFFFF6B6B),
                  size: 20,
                ),
              ),
              DataCell(Text(
                track.isViewed && track.viewedAt != null
                    ? _getTimeAgo(track.viewedAt!)
                    : '-',
                style: TextStyle(
                    color: track.isViewed ? Colors.white70 : Colors.grey[600]),
              )),
              DataCell(
                Icon(
                  track.isDownloaded
                      ? Icons.download_done
                      : Icons.remove_circle_outline,
                  color: track.isDownloaded
                      ? const Color(0xFF60A5FA)
                      : Colors.grey[600],
                  size: 20,
                ),
              ),
              DataCell(Text(
                track.isDownloaded && track.downloadedAt != null
                    ? _getTimeAgo(track.downloadedAt!)
                    : '-',
                style: TextStyle(
                    color:
                        track.isDownloaded ? Colors.white70 : Colors.grey[600]),
              )),
            ]);
          }).toList(),
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
      height: 120, // Fixed height
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  maxLines: 1,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
