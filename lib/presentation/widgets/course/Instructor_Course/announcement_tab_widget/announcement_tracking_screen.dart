// ========================================
// FILE: announcement_tracking_screen.dart
// MÔ TẢ: Announcement Tracking Screen với REAL Firebase data
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

import 'package:elearning_management_app/domain/models/announcement_tracking_model.dart';
import 'package:elearning_management_app/data/repositories/announcement/announcement_repository.dart';

// ========================================
// PROVIDER: Stream tracking data từ Firebase
// ========================================
final announcementTrackingProvider = StreamProvider.family<List<AnnouncementTrackingModel>, String>(
  (ref, announcementId) {
    final repo = ref.watch(AnnouncementRepositoryProvider);
    
    // Query tracking documents for this announcement
    return repo.getTrackingStream(announcementId); // <--- DÒNG ĐÃ SỬA
  },
);

// ========================================
// SCREEN: Announcement Tracking
// ========================================
class AnnouncementTrackingScreen extends ConsumerStatefulWidget {
  final String announcementId;
  final String announcementTitle;
  final String courseId;
  final List<String> targetGroupIds; // Empty = all groups

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
  String _statusFilter = 'All'; // All, Viewed, Not Viewed, Downloaded
  String _groupFilter = 'All';
  String _sortColumn = 'studentName';
  bool _sortAscending = true;

  // ========================================
  // CSV EXPORT
  // ========================================
  Future<void> _exportToCSV(List<AnnouncementTrackingModel> trackingData) async {
    try {
      final List<List<dynamic>> csvData = [];
      
      // Header
      csvData.add([
        'Student Name',
        'Student ID',
        'Group',
        'Has Viewed',
        'Last Viewed',
        'Has Downloaded',
        'Last Downloaded',
      ]);

      // Data rows
      for (final track in trackingData) {
        csvData.add([
          'Student ${track.studentId}', // Replace with actual student name from lookup
          track.studentId,
          track.groupId,
          track.hasViewed ? 'Yes' : 'No',
          track.hasViewed ? _formatDateTime(track.lastViewedAt) : '-',
          track.hasDownloaded ? 'Yes' : 'No',
          track.hasDownloaded && track.lastDownloadedAt != null
              ? _formatDateTime(track.lastDownloadedAt!)
              : '-',
        ]);
      }

      // Convert to CSV
      const converter = ListToCsvConverter();
      final csvString = converter.convert(csvData);

      // Save file
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

  // ========================================
  // FILTER LOGIC
  // ========================================
  List<AnnouncementTrackingModel> _applyFilters(List<AnnouncementTrackingModel> data) {
    var filtered = data;

    // Search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((track) {
        return track.studentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            track.groupId.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Status filter
    if (_statusFilter == 'Viewed') {
      filtered = filtered.where((track) => track.hasViewed).toList();
    } else if (_statusFilter == 'Not Viewed') {
      filtered = filtered.where((track) => !track.hasViewed).toList();
    } else if (_statusFilter == 'Downloaded') {
      filtered = filtered.where((track) => track.hasDownloaded).toList();
    }

    // Group filter
    if (_groupFilter != 'All') {
      filtered = filtered.where((track) => track.groupId == _groupFilter).toList();
    }

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn) {
        case 'studentName':
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
  // BUILD UI
  // ========================================
  @override
  Widget build(BuildContext context) {
    final trackingAsync = ref.watch(announcementTrackingProvider(widget.announcementId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        title: Text('Tracking: ${widget.announcementTitle}'),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: trackingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error loading tracking data: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (trackingData) {
          final filteredData = _applyFilters(trackingData);
          final groups = trackingData.map((e) => e.groupId).toSet().toList()..sort();
          
          // Statistics
          final viewedCount = trackingData.where((t) => t.hasViewed).length;
          final notViewedCount = trackingData.length - viewedCount;
          final downloadedCount = trackingData.where((t) => t.hasDownloaded).length;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Cards
                _buildStatisticsCards(viewedCount, notViewedCount, downloadedCount, trackingData.length),
                const SizedBox(height: 16),

                // Filters
                Row(
                  children: [
                    Expanded(
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
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildFilterDropdown(
                      label: 'Status',
                      value: _statusFilter,
                      items: ['All', 'Viewed', 'Not Viewed', 'Downloaded'],
                      onChanged: (value) => setState(() => _statusFilter = value!),
                    ),
                    const SizedBox(width: 12),
                    _buildFilterDropdown(
                      label: 'Group',
                      value: _groupFilter,
                      items: ['All', ...groups],
                      onChanged: (value) => setState(() => _groupFilter = value!),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _exportToCSV(filteredData),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Export CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

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

  Widget _buildStatisticsCards(int viewed, int notViewed, int downloaded, int total) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Viewed',
            value: viewed.toString(),
            subtitle: '${((viewed / total) * 100).toStringAsFixed(0)}%',
            color: const Color(0xFF34D399),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Not Viewed',
            value: notViewed.toString(),
            subtitle: '${((notViewed / total) * 100).toStringAsFixed(0)}%',
            color: const Color(0xFFFF6B6B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Downloaded',
            value: downloaded.toString(),
            subtitle: '${((downloaded / total) * 100).toStringAsFixed(0)}%',
            color: const Color(0xFF60A5FA),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Total Students',
            value: total.toString(),
            subtitle: 'Enrolled',
            color: const Color(0xFF9CA3AF),
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
            headingRowColor: MaterialStateProperty.all(const Color(0xFF1F2937)),
            columns: [
              DataColumn(
                label: const Text('Student ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onSort: (_, __) => setState(() {
                  if (_sortColumn == 'studentName') {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortColumn = 'studentName';
                    _sortAscending = true;
                  }
                }),
              ),
              DataColumn(label: const Text('Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              DataColumn(label: const Text('Viewed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              DataColumn(label: const Text('Last Viewed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              DataColumn(label: const Text('Downloaded', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              DataColumn(label: const Text('Last Downloaded', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
                  track.hasViewed ? track.timeAgo : '-',
                  style: const TextStyle(color: Colors.white70),
                )),
                DataCell(
                  Icon(
                    track.hasDownloaded ? Icons.download_done : Icons.remove_circle_outline,
                    color: track.hasDownloaded ? const Color(0xFF60A5FA) : Colors.grey,
                  ),
                ),
                DataCell(Text(
                  track.downloadTimeAgo ?? '-',
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

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
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
          Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}